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
#import "ORFec32Model.h"
#import "SNOPModel.h"
#import "OROrderedObjManager.h"
#import "ORPQModel.h"
#import "ORGlobal.h"

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
                     selector : @selector(stop)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (BOOL) isRunning
{
    /* Returns if the nhit monitor is currently running. */
    return [runningThread isExecuting];
}

- (void) stop
{
    /* Stop the nhit monitor. */
    if ([self isRunning]) [runningThread cancel];
}

- (void) start: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit
{
    /* Start the nhit monitor. */
    if ([self isRunning]) return;

    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:crate], @"crate",
                            [NSNumber numberWithInt:pulserRate], @"pulserRate",
                            [NSNumber numberWithInt:numPulses], @"numPulses",
                            [NSNumber numberWithInt:maxNhit], @"maxNhit",
                             nil];

    [runningThread initWithTarget:self selector:@selector(run) object:args];
}

- (int) connect
{
    /* Connect to the data server. */
    SNOPModel *snop;
    char err[ANET_ERR_LEN];
    char* name = "nhit";
    struct GenericRecordHeader header;

    [self disconnect];

    NSArray* snops = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    if ([snops count] == 0) {
        NSLogColor([NSColor redColor], @"unable to find SNO+ model object.\n");
        return -1;
    }

    snop = [snops objectAtIndex:0];

    sock = anetTcpConnect(err, (char *) [[snop dataHost] UTF8String], [snop dataPort]);

    if (sock == ANET_ERR) {
        NSLogColor([NSColor redColor], @"failed to connect to data server: %s",
                   err);
        return -1;
    }

    anetSendTimeout(err, sock, 1000);
    anetReceiveTimeout(err, sock, 1000);

    /* Send our name to the data server. */
    header.RecordID = htonl(kSCmd);
    header.RecordLength = htonl(strlen(name));
    header.RecordVersion = htonl(kId);

    if (anetWrite(sock, (char *) &header, sizeof(struct GenericRecordHeader)) == -1) {
        NSLogColor([NSColor redColor], @"failed to send name to data server\n");
        [self disconnect];
        return -1;
    }

    if (anetWrite(sock, name, strlen(name)) == -1) {
        NSLogColor([NSColor redColor], @"failed to send name to data server\n");
        [self disconnect];
        return -1;
    }

    /* Subscribe to MTCD records from the data server. */
    header.RecordID = htonl(kSCmd);
    header.RecordLength = htonl(4);
    header.RecordVersion = ntohl(kSub);

    if (anetWrite(sock, (char *) &header, sizeof(struct GenericRecordHeader)) == -1) {
        NSLogColor([NSColor redColor], @"failed to send subscription to data server\n");
        [self disconnect];
        return -1;
    }

    if (anetWrite(sock, "MTCD", 4) == -1) {
        NSLogColor([NSColor redColor], @"failed to send subscription to data server\n");
        [self disconnect];
        return -1;
    }

    return 0;
}

- (void) disconnect
{
    if (sock > 0) close(sock);
}

- (int) getNhitTriggerCount: (int) nhit numPulses: (int) numPulses nhitRecord: (struct NhitRecord *) nhitRecord
{
    /* Returns the number of triggers which had an NHIT trigger fire. */
    int current_gtid;
    int i, nrecords;
    int count = 0;
    int start;
    struct GenericRecordHeader header;

    current_gtid = [[mtc mtc] intCommand:"get_gtid"];

    start = time(NULL);

    while (1) {
        /* Check to see if we should stop. */
        if ([[NSThread currentThread] isCancelled]) goto err;

        if (time(NULL) > start + timeout) {
            goto err;
        }

        if (anetRead(sock, (char *) &header, sizeof(struct GenericRecordHeader)) == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                continue;
            }
            goto err;
        }

        if (anetRead(sock, (char *) buf, ntohl(header.RecordLength)) == -1) {
            goto err;
        }

        nrecords = ntohl(header.RecordLength)/sizeof(struct MTCReadoutData);

        for (i = 0; i < nrecords; i++) {
            struct MTCReadoutData *mtc_readout_data = (struct MTCReadoutData *) (buf + i*sizeof(struct MTCReadoutData));

            if (mtc_readout_data->BcGT < current_gtid) continue;

            if (mtc_readout_data->Pedestal) {
                if (mtc_readout_data->Nhit_100_Lo)
                    nhitRecord->nhit_100_lo[nhit] += 1;
                if (mtc_readout_data->Nhit_100_Med)
                    nhitRecord->nhit_100_med[nhit] += 1;
                if (mtc_readout_data->Nhit_100_Hi)
                    nhitRecord->nhit_100_hi[nhit] += 1;
                if (mtc_readout_data->Nhit_20)
                    nhitRecord->nhit_20[nhit] += 1;
                if (mtc_readout_data->Nhit_20_LB)
                    nhitRecord->nhit_20_lb[nhit] += 1;

                count += 1;

                if (count >= numPulses) break;
            }

            if (count >= numPulses) break;
        }
    }

    return 0;
err:
    NSLogColor([NSColor redColor], @"getNhitTriggerCount failed\n");
    return -1;
}

- (int) getThreshold: (int *) counts numPulses: (int) numPulses
{
    /* Returns the trigger threshold for a given NHIT trigger by looking for
     * the nhit at which the trigger rate crosses 50%.
     *
     * Returns -1 if no point crosses 50%. */
    int i;

    if (counts[0] > numPulses/2) {
        /* we are already above threshold at 0 nhit */
        return 0;
    }

    for (i = 0; i < numPulses; i++) {
        if (counts[i] > numPulses/2) {
            return (i-1) + (numPulses/2 - counts[i-1])/(counts[i] - counts[i-1]);
        }
    }

    return -1;
}

- (void) run: (NSDictionary *) args
{
    /* Run the nhit monitor. This method should only be called in a separate
     * thread. The start method should be called to actually start the nhit
     * monitor. */
    ORXL3Model *xl3;
    ORFec32Model *fec;
    int slot, channel;
    uint32_t pedestals_enabled, pulser_enabled, pedestal_mask, coarse_delay;
    uint32_t fine_delay, pedestal_width;
    float pulser_rate;
    struct NhitRecord nhitRecord;
    int i;

    int crate = [[args objectForKey:@"crate"] intValue];
    int pulserRate = [[args objectForKey:@"pulserRate"] intValue];
    int numPulses = [[args objectForKey:@"numPulses"] intValue];
    int maxNhit = [[args objectForKey:@"maxNhit"] intValue];

    [self connect];

    for (i = 0; i < MAX_NHIT; i++) {
        nhitRecord.nhit_100_lo[i] = 0;
        nhitRecord.nhit_100_med[i] = 0;
        nhitRecord.nhit_100_hi[i] = 0;
        nhitRecord.nhit_20[i] = 0;
        nhitRecord.nhit_20_lb[i] = 0;
    }

    if (maxNhit > MAX_NHIT) {
        NSLogColor([NSColor redColor], @"maxNhit must be less than %i\n",
                   MAX_NHIT);
        return;
    }

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
    NSMutableArray *slots = [NSMutableArray array];
    NSMutableArray *channels = [NSMutableArray array];
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

    if (maxNhit > [channels count]) {
        NSLogColor([NSColor redColor], @"crate %i only has %i channels with "
            "triggers enabled, but need at least %i", crate, [channels count],
             maxNhit);
    }

    pedestals_enabled = [mtc isPedestalEnabledInCSR];
    pulser_enabled = [mtc pulserEnabled];
    pedestal_mask = [mtc pedCrateMask];
    pulser_rate = [mtc pgtRate];
    coarse_delay = [mtc coarseDelay];
    fine_delay = [mtc fineDelay];
    pedestal_width = [mtc pedestalWidth];

    [mtc disablePulser];
    [mtc enablePedestal];
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

        /* Check to see if we should stop. */
        if ([[NSThread currentThread] isCancelled]) goto err;

        [fec setPed:channel enabled:1];

        [xl3 setPedestals];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [mtc enablePulser];
        });
        if ([self getNhitTriggerCount: i numPulses:numPulses nhitRecord:&nhitRecord] == -1) break;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [mtc disablePulser];
        });
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

    /* print trigger thresholds */
    int threshold_n100_lo = [self getThreshold: nhitRecord.nhit_100_lo
                             numPulses: numPulses];

    if (threshold_n100_lo == -1) {
        NSLog(@"nhit_100_lo  threshold is > %i nhit", maxNhit);
    } else {
        NSLog(@"nhit_100_lo  threshold is %.2f nhit", threshold_n100_lo);
    }

    int threshold_n100_med = [self getThreshold: nhitRecord.nhit_100_med
                             numPulses: numPulses];

    if (threshold_n100_med == -1) {
        NSLog(@"nhit_100_med threshold is > %i nhit", maxNhit);
    } else {
        NSLog(@"nhit_100_med threshold is %.2f nhit", threshold_n100_med);
    }

    int threshold_n100_hi = [self getThreshold: nhitRecord.nhit_100_hi
                             numPulses: numPulses];

    if (threshold_n100_hi == -1) {
        NSLog(@"nhit_100_hi  threshold is > %i nhit", maxNhit);
    } else {
        NSLog(@"nhit_100_hi  threshold is %.2f nhit", threshold_n100_hi);
    }

    int threshold_n20 = [self getThreshold: nhitRecord.nhit_20
                             numPulses: numPulses];

    if (threshold_n20 == -1) {
        NSLog(@"nhit_20      threshold is > %i nhit", maxNhit);
    } else {
        NSLog(@"nhit_20      threshold is %.2f nhit", threshold_n20);
    }

    int threshold_n20_lb = [self getThreshold: nhitRecord.nhit_20_lb
                             numPulses: numPulses];

    if (threshold_n20_lb == -1) {
        NSLog(@"nhit_20_lb   threshold is > %i nhit", maxNhit);
    } else {
        NSLog(@"nhit_20_lb   threshold is %.2f nhit", threshold_n20_lb);
    }

    NSMutableString *command = [NSMutableString stringWithFormat:@"INSERT INTO nhit_monitor (crate, num_pulses, pulser_rate, nhit_100_lo, nhit_100_med, nhit_100_hi, nhit_20, nhit_20_lb) VALUES (%i, %i, %i, ", crate, numPulses, pulserRate];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_lo[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_lo[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_med[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_med[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_hi[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_hi[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_20[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_20[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_20_lb[i]];
    }
    [command appendFormat:@"%i])", nhitRecord.nhit_20_lb[i]];

    ORPQModel *db = [ORPQModel getCurrent];

    if (!db) {
        NSLog(@"Postgres object not found, please add it to the experiment!\n");
        goto err;
    }

    [db dbQuery:command object:self selector:nil timeout:10.0];

    [self disconnect];
err:
    [self disconnect];
}
@end
