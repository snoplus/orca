//
//  TUBiiController.m
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "TUBiiController.h"
#import "TUBiiModel.h"

@implementation TUBiiController

@synthesize caenChannelSelect_0;
@synthesize caenChannelSelect_1;
@synthesize caenChannelSelect_2;
@synthesize caenChannelSelect_3;
@synthesize caenGainSelect_0;
@synthesize caenGainSelect_1;
@synthesize caenGainSelect_2;
@synthesize caenGainSelect_3;
@synthesize caenGainSelect_4;
@synthesize caenGainSelect_5;
@synthesize caenGainSelect_6;
@synthesize caenGainSelect_7;
@synthesize tabView;

- (id)init
{
    // Initialize by launching the GUI, referenced by the name of the xib/nib file
    self = [super initWithWindowNibName:@"TUBiiController"];

    
    return self;
}
- (void) awakeFromNib
{
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    
    PulserAndDelays_size = NSMakeSize(400, 350);
    Triggers_size = NSMakeSize(400, 350);
    Tubii_size = NSMakeSize(400, 350);
    Analog_size = NSMakeSize(615, 445);
    [tabView setDelegate:self];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    [self CaenMatchHardware:(self)];
    [[self caenChannelSelect_3] setEnabled:NO];
}
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int tabIndex = [aTabView indexOfTabViewItem:item];
    if (tabIndex==0)
    {
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:PulserAndDelays_size];
        [[self window] setContentView:tabView];
    }
    else if (tabIndex==1)
    {
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:Triggers_size];
        [[self window] setContentView:tabView];
    }
    else if (tabIndex==2)
    {
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:Tubii_size];
        [[self window] setContentView:tabView];
    }
    else if (tabIndex==3)
    {
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:Analog_size];
        [[self window] setContentView:tabView];
    }
}
// GUI actions. CTRL-drag handles from the IB into this file.
- (IBAction)SmellieFire:(id)sender {
    NSLog(@"TUBii: SMELLIE pulser ON: %i\n", [sender state]);
    [model fireSmelliePulser:[sender state]];
}
- (IBAction)SmellieStop:(id)sender {
    NSLog(@"TUBii: SMELLIE pulser STOP: %i\n", [sender state]);
    [model stopSmelliePulser:[sender state]];
}

- (IBAction)TellieFire:(id)sender {
    NSLog(@"TUBii: TELLIE pulser ON: %i\n", [sender state]);
    [model fireTelliePulser:[sender state]];
}
- (IBAction)TellieStop:(id)sender {
    NSLog(@"TUBii: TELLIE pulser STOP: %i\n", [sender state]);
    [model stopTelliePulser:[sender state]];
}

- (IBAction)PulserFire:(id)sender {
    NSLog(@"TUBii: Pulser ON: %i\n", [sender state]);
    [model firePulser:[sender state]];
}
- (IBAction)PulserStop:(id)sender {
    NSLog(@"TUBii: Pulser STOP: %i\n", [sender state]);
    [model stopPulser:[sender state]];
}

- (IBAction)SmellieRate:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: SMELLIE rate: %f Hz\n",value);
    [model setSmellieRate:value];
}
- (IBAction)SmellieNPulses:(id)sender {
    int value = [sender intValue];
    NSLog(@"TUBii: SMELLIE number of pulses: %i\n",value);
    [model setSmellieNPulses:value];
}

- (IBAction)TellieRate:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: TELLIE rate: %f Hz\n",value);
    [model setTellieRate:value];
}
- (IBAction)TellieNPulses:(id)sender {
    int value = [sender intValue];
    NSLog(@"TUBii: TELLIE number of pulses: %i\n",value);
    [model setTellieNPulses:value];
}

- (IBAction)PulserRate:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: Pulser rate: %f Hz\n",value);
    [model setPulserRate:value];
}
- (IBAction)NPules:(id)sender {
    int value = [sender intValue];
    NSLog(@"TUBii: Number of pulses: %i\n",value);
    [model setNPulses:value];
}

- (IBAction)SmellieDelay:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: SMELLIE Delay Length: %f ns\n",value);
    [model setSmellieDelay:value];
}

- (IBAction)LoadSmellieDelay:(id)sender {
    [model loadSmellieDelay:[sender state]];
}

- (IBAction)TellieDelay:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: TELLIE Delay Length: %f ns\n",value);
    [model setTellieDelay:value];
}

- (IBAction)LoadTellieDelay:(id)sender {
    [model loadTellieDelay:[sender state]];
}

- (IBAction)DelayLength:(id)sender {
    float value = [sender floatValue];
    NSLog(@"TUBii: Delay length: %f ns\n",value);
    [model setGenericDelay:value];
}

- (IBAction)LoadDelay:(id)sender {
    [model loadDelay:[sender state]];
}

- (IBAction)TrigMaskSet:(id)sender {
    unsigned long mask = 0;
    int i;
    for(i=0;i<16;i++){
        if([[sender cellWithTag:i] intValue]){
            mask |= (1L << i);
            NSLog(@"%i YES \n",i);
        }
    }
    NSLog(@"TUBii: Trigger mask: %lu\n",mask);
    [model setTrigMask:mask];

}
- (IBAction)TrigMaskLoad:(id)sender {
    [model loadTrigMask:[sender state]];
}

- (IBAction)CaenMatchHardware:(id)sender{
  
    CAEN_CHANNEL_MASK ChannelMask = [model caenChannelMask];
    CAEN_GAIN_MASK GainMask = [model caenGainMask];


    BOOL err = YES;
    err &= [caenChannelSelect_0 selectCellWithTag:(ChannelMask & channelSel_0)>>0];
    err &= [caenChannelSelect_1 selectCellWithTag:(ChannelMask & channelSel_1)>>1];
    err &= [caenChannelSelect_2 selectCellWithTag:(ChannelMask & channelSel_2)>>2];
    err &= [caenChannelSelect_3 selectCellWithTag:(ChannelMask & channelSel_3)>>3];
    err &= [caenGainSelect_0 selectCellWithTag:(GainMask & gainSel_0)>>0];
    err &= [caenGainSelect_1 selectCellWithTag:(GainMask & gainSel_1)>>1];
    err &= [caenGainSelect_2 selectCellWithTag:(GainMask & gainSel_2)>>2];
    err &= [caenGainSelect_3 selectCellWithTag:(GainMask & gainSel_3)>>3];
    err &= [caenGainSelect_4 selectCellWithTag:(GainMask & gainSel_4)>>4];
    err &= [caenGainSelect_5 selectCellWithTag:(GainMask & gainSel_5)>>5];
    err &= [caenGainSelect_6 selectCellWithTag:(GainMask & gainSel_6)>>6];
    err &= [caenGainSelect_7 selectCellWithTag:(GainMask & gainSel_7)>>7];
    if (err==NO) {
        NSLog(@"Error in CaenMatchHardware");
    }
    
}

- (IBAction)CaenLoadMask:(id)sender
{
    CAEN_CHANNEL_MASK ChannelMask =0;
    CAEN_GAIN_MASK GainMask=0;
    ChannelMask |= [[caenChannelSelect_0 selectedCell] tag ]*channelSel_0;
    ChannelMask |= [[caenChannelSelect_1 selectedCell] tag ]*channelSel_1;
    ChannelMask |= [[caenChannelSelect_2 selectedCell] tag ]*channelSel_2;
    ChannelMask |= [[caenChannelSelect_3 selectedCell] tag ]*channelSel_3;
    GainMask |= [[caenGainSelect_0 selectedCell] tag ]*gainSel_0;
    GainMask |= [[caenGainSelect_1 selectedCell] tag ]*gainSel_1;
    GainMask |= [[caenGainSelect_2 selectedCell] tag ]*gainSel_2;
    GainMask |= [[caenGainSelect_3 selectedCell] tag ]*gainSel_3;
    GainMask |= [[caenGainSelect_4 selectedCell] tag ]*gainSel_4;
    GainMask |= [[caenGainSelect_5 selectedCell] tag ]*gainSel_5;
    GainMask |= [[caenGainSelect_6 selectedCell] tag ]*gainSel_6;
    GainMask |= [[caenGainSelect_7 selectedCell] tag ]*gainSel_7;
    NSLog(@"Sending to TUBii CAEN Mask %i, %i\n",ChannelMask,GainMask);
    [model setCaenMasks:ChannelMask GainMask:GainMask];
}



@end