//
//  NHitMonitor.m
//  Orca
//
//  Created by Anthony LaTorre on Thursday, April 13, 2017.
//

#import "NHitMonitor.h"
#import "anet.h"
#import "ORMTCModel.h"
#import "ORXL3Model.h"
#import "record_info.h"

/* Buffer size for records from the data stream. Most records are small, but
 * the MTC records are concatenated so may be a few kilobytes. */
#define DATASTREAM_BUFFER_SIZE 0xffffff

@implementation NHitMonitor

- (id) init
{
    runningThread = [[NSThread alloc] init];
    buf = malloc(DATASTREAM_BUFFER_SIZE);
    sock = -1;
    timeout = 10;
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    free(buf);
    [runningThread release];
    [super dealloc];
}

- (void) registerNotificationObservers
{

    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(setPulserRate:)
                         name : ORRunSecondChanceForWait
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(launchECAThread:)
                         name : ORRunStartedNotification
                       object : nil];

}

- (int) connectToDataServer
{
    /* Connect to the data server. */
    SNOPModel *snop;
    char host[256];
    char err[ANET_ERR_LEN];
    char* name = "nhit";
    int port;
    struct GenericRecordHeader header;

    [self disconnect];

    NSArray* snops = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    if ([snops count] == 0) {
        NSLogColor([NSColor redColor], @"unable to find SNO+ model object.\n");
        return -1;
    }

    snop = [snops objectAtIndex:0];

    sock = anetTcpConnect(err, [[snop dataServerHost] UTF8String],
                          [snop dataServerPort]);

    if (sock == ANET_ERR) {
        NSLogColor([NSColor redColor], @"failed to connect to data server: %s",
                   err);
        return -1;
    }

    anetSendTimeout(err, sock, 1000);
    anetRecvTimeout(err, sock, 1000);

    /* Send our name to the data server. */
    header.RecordID = htonl(kSCmd);
    header.RecordLength = htonl(strlen(name));
    header.RecordVersion = 0x4944;

    memcpy(buf, &header, sizeof(GenericRecordHeader));
    memcpy(buf+sizeof(GenericRecordHeader), name, strlen(name));

    if (anetWrite(sock, buf, sizeof(GenericRecordHeader)+strlen(name)) == -1) {
        NSLogColor([NSColor redColor], @"failed to send name to data server\n");
        return -1;
    }

    return 0;
}

- (void) disconnect
{
    if (sock > 0) close(sock);
}

- (int) getNhitTriggerCount: numPulses: (int) numPulses
{
    /* Returns the number of triggers which had an NHIT trigger fire. */
    int current_gtid;
    int data, nrecords;
    int nhit_100_lo, nhit_100_med, nhit_100_hi, n20, n20_lb;
    int count = 0;
    int start, now;

    current_gtid = [[mtc mtc] intCommand:"get_gtid"];

    start = time(NULL);

    while (1) {
        if (time(NULL) > start + timeout) {
            goto err;
        }

        if (anetRead(sock, &header, sizeof(GenericRecordHeader)) == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                continue;
            }
            goto err;
        }

        if (anetRead(sock, buf, ntohl(header.RecordLength)) == -1) {
            goto err;
        }

        nrecords = ntohl(header.RecordLength)/6;

        for (i = 0; i < nrecords; i++) {
            MTCReadoutData *mtc_data = (MTCReadoutData *) (buf + i*6*4);

            if (mtc_data->BcGT < current_gtid) continue;

            if (mtc_data->Pedestal) {
                if (mtc_readout_data.Nhit_100_Lo)
                    nhit_100_lo += 1
                if (mtc_readout_data.Nhit_100_Med)
                    nhit_100_med += 1
                if (mtc_readout_data.Nhit_100_Hi)
                    nhit_100_hi += 1
                if (mtc_readout_data.Nhit_20)
                    nhit_20 += 1
                if (mtc_readout_data.Nhit_20_LB)
                    nhit_20_lb += 1

                count += 1

                if (count >= numPulses) break;
            }

        if (count >= numPulses) break;
    }

    return 0;
err:
    NSLogColor([NSColor redColor], @"getNhitTriggerCount failed\n");
    return -1;
}

- (void) run: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit
{
    ORXL3Model *xl3;
    ORFec32Model *fec;
    int slot, channel;
    uint32_t pedestals_enabled, pulser_enabled, pedestal_mask, coarse_delay;
    uint32_t fine_delay, pedestal_width;
    float pulser_rate;

    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    if ([mtcs count] == 0) {
        NSLogColor([NSColor redColor], @"unable to find mtc object.\n");
        return;
    }

    mtc = [mtcs objectAtIndex:0];

    xl3 = nil;

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

    for (i = 0; i < [xl3s count]; i++) {
        if ([[xl3s objectAtIndex:i] crateNumber] == crate) {
            xl3 = [xl3s objectAtIndex:i];
            break;
        }
    }

    if (!xl3) {
        NSLogColor([NSColor redColor], @"unable to find XL3 %i\n", crate);
        return;
    }

    /* create a list of channels for which to enable pedestals. We only add
     * channels if both the N100 and N20 triggers are enabled. */
    NSArray *slots = @[];
    NSArray *channels = @[];
    for (slot = 0; slot < 16; slot++) {
        for (channel = 0; channel < 32; channel++) {
            fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

            if (!fec) continue;

            if ([fec trigger100nsEnabled: channel] && \
                [fec trigger20nsEnabled: channel]) {
                [slots addObject:[NSNumber numberWithInt:channel]];
                [channels addObject:[NSNumber numberWithInt:channel]];
            }
        }
    }

    if (maxNhit > [channels length]) {
        NSLogColor([NSColor redColor], @"crate %i only has %i channels with "
            "triggers enabled, but need at least %i", crate, [channels length],
             maxNhit);
    }

    pedestals_enabled = [mtc isPedestalEnabledInCSR];
    pulser_enabled = [mtc pulserEnabled];
    pedestal_mask = [mtc pedCrateMask];
    pulser_rate = [mtc pgtRate];
    coarse_delay = [mtc getCoarseDelay];
    fine_delay = [mtc getFineDelay];
    pedestal_width = [mtc getPedestalWidth];

    [mtc disablePulser];
    [mtc enablePedestals];
    [mtc setPedCrateMask: (1 << crate)];
    [mtc loadPedestalCrateMaskToHardware];
    [mtc setPgtRate: pulserRate];
    [mtc setCoarseDelay: COARSE_DELAY];
    [mtc loadCoarseDelayToHardware];
    [mtc setFineDelay: FINE_DELAY];
    [mtc loadFineDelayToHardware];
    [mtc setPedestalWidth: PEDESTAL_WIDTH];
    [mtc loadPedWidthToHardware];

    /* turn off all pedestals */
    [xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0];

    for (i = 0; i < maxNhit + 1; i++) {
        slot = [[slots objectAtIndex:i] intValue];
        channel = [[channels objectAtIndex:i] intValue];
        fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

        [fec setPed:channel state:1];

        [xl3 setPedestals];

        [mtc enablePulser];
        [self getNhitTriggerCount: numPulses];
        [mtc disablePulser];
    }

    if (pedestals_enabled) {
        [mtc enablePedestal];
    } else {
        [mtc disablePedestal];
    }

    if (pulser_enabled) {
        [mtc enablePulser];
    } else {
        [mtc disablePulser];
    }

    [mtc setPedCrateMask:pedestal_mask];
    [mtc loadPedestalCrateMaskToHardware];
    [mtc setCoarseDelay: coarse_delay];
    [mtc loadCoarseDelayToHardware];
    [mtc setFineDelay: fine_delay];
    [mtc loadFineDelayToHardware];
    [mtc setPedestalWidth: pedestal_width];
    [mtc loadPedWidthToHardware];
}
@end
