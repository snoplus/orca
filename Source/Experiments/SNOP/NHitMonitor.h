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

@interface NHitMonitor : NSObject {

@private
    NSThread *runningThread;
    char *buf;
    int sock;
    int timeout;
    ORMTCModel *mtc;
}

- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) run: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit;
@end
