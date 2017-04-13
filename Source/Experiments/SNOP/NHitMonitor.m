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

@implementation NHitMonitor

- (id) init
{
    runningThread = [[NSThread alloc] init];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
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

- (void) run: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit
{
    ORXL3Model *xl3;
    ORMTCModel *mtc;
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
    [mtc setPedestalCrateMask: (1 << crate)];
    [mtc setPgtRate: pulserRate];
    [mtc setCoarseDelay: COARSE_DELAY];
    [mtc setFineDelay: FINE_DELAY];
    [mtc setPedestalWidth: PEDESTAL_WIDTH];

    /* turn off all pedestals */
    [xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0];

    for (i = 0; i < maxNhit + 1; i++) {
        slot = [[slots objectAtIndex:i] intValue];
        channel = [[channels objectAtIndex:i] intValue];
        fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

        [fec setPed:channel state:1];

        [xl3 setPedestals];

        [mtc enablePulser];
        [self getNhitTriggerCount];
        [mtc disablePulser];
    }
}
@end
