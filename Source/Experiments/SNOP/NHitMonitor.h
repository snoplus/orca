//
//  NHitMonitor.h
//  Orca
//
//  Created by Anthony LaTorre on Thursday, April 13, 2017.
//
//  Class that handles the Nhit monitor.
//

#import <Foundation/Foundation.h>
#import "ORMTCModel.h"
#import <stdint.h>
#import "ORPQModel.h"

/* Buffer size for records from the data stream. Most records are small, but
 * the MTC records are concatenated so may be a few kilobytes. */
#define DATASTREAM_BUFFER_SIZE 0xffffff

/* Maximum number of channels to fire on a single crate. */
#define MAX_NHIT 512

/* Default settings for running the nhit monitor. */
#define COARSE_DELAY 250
#define FINE_DELAY 0
#define PEDESTAL_WIDTH 50

struct NhitRecord {
    int nhit_100_lo[MAX_NHIT];
    int nhit_100_med[MAX_NHIT];
    int nhit_100_hi[MAX_NHIT];
    int nhit_20[MAX_NHIT];
    int nhit_20_lb[MAX_NHIT];
};

@interface NHitMonitor : NSObject {

@private
    NSThread *runningThread;
    char *buf;
    int sock;
    ORMTCModel *mtc;
}

- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (BOOL) isRunning;
- (void) stop;
- (void) start: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit;
- (int) connect;
- (void) disconnect;
- (int) getNhitTriggerCount: (int) nhit numPulses: (int) numPulses nhitRecord: (struct NhitRecord *) nhitRecord timeout: (int) timeout;
- (void) nhitMonitorCallback: (ORPQResult *) result;
- (void) run: (NSDictionary *) args;
@end

extern NSString* ORNhitMonitorUpdateNotification;
