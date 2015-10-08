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

- (id)init
{
    // Initialize by launching the GUI, referenced by the name of the xib/nib file
    self = [super initWithWindowNibName:@"TUBiiController"];
    
    // Not automatic, apparently
    // Try extern-ing the names in the model
    //[self registerNotificationObservers];
    
    return self;
}

// GUI actions. CTRL-drag handles from the IB into this file.
- (IBAction)SmellieFire:(id)sender {
    NSLog(@"TUBii: SMELLIE pulser ON: %i\n", [sender state]);
    [model fireSmelliePulser:[sender state]];
}

- (IBAction)TellieFire:(id)sender {
    NSLog(@"TUBii: TELLIE pulser ON: %i\n", [sender state]);
    [model fireTelliePulser:[sender state]];
}

- (IBAction)PulserFire:(id)sender {
    NSLog(@"TUBii: Pulser ON: %i\n", [sender state]);
    [model firePulser:[sender state]];
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

@end