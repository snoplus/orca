//
//  TUBiiController.h
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "OrcaObjectController.h"


@interface TUBiiController : OrcaObjectController <NSTabViewDelegate> {
    NSView *blankView;
    NSSize PulserAndDelays_size;
    NSSize Triggers_size;
    NSSize Tubii_size;
    NSSize Analog_size;
    NSSize GTDelays_size;
    NSTabView *tabView;
 
  NSMatrix *caenChannelSelect_3;
  NSMatrix *caenChannelSelect_2;
  NSMatrix *caenChannelSelect_1;
  NSMatrix *caenChannelSelect_0;
  NSMatrix *caenGainSelect_0;
  NSMatrix *caenGainSelect_1;
  NSMatrix *caenGainSelect_2;
  NSMatrix *caenGainSelect_3;
  NSMatrix *caenGainSelect_4;
  NSMatrix *caenGainSelect_5;
  NSMatrix *caenGainSelect_6;
  NSMatrix *caenGainSelect_7;
}

// These references to UI elements are created by CTRL-dragging them into this
// header file. Note the connection dots on the left.
@property (assign,weak) IBOutlet NSTabView *tabView;

@property (assign,weak) IBOutlet NSMatrix *caenChannelSelect_0;
@property (assign,weak) IBOutlet NSMatrix *caenChannelSelect_1;
@property (assign,weak) IBOutlet NSMatrix *caenChannelSelect_2;
@property (assign,weak) IBOutlet NSMatrix *caenChannelSelect_3;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_0;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_1;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_2;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_3;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_4;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_5;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_6;
@property (assign,weak) IBOutlet NSMatrix *caenGainSelect_7;



- (IBAction)CaenMatchHardware:(id)sender;
- (IBAction)CaenLoadMask:(id)sender;

-(id) init;

@end
