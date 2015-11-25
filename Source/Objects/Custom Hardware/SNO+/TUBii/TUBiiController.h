//
//  TUBiiController.h
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "OrcaObjectController.h"

@interface TUBiiController : OrcaObjectController {
    NSView *blankView;
    IBOutlet NSTabView *tabView;
    NSSize PulserAndDelays_size;
    NSSize Triggers_size;
    NSSize Tubii_size;
    NSSize Analog_size;
}

// These references to UI elements are created by CTRL-dragging them into this
// header file. Note the connection dots on the left.

-(id) init;

@end
