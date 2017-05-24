//
//  TUBiiController.m
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "TUBiiController.h"
#import "TUBiiModel.h"
//Defs to map between tab number and tab name
#define TUBII_GUI_TUBII_TAB_NUM 0
#define TUBII_GUI_PULSER_TAB_NUM 1
#define TUBII_GUI_TRIGGER_TAB_NUM 2
#define TUBII_GUI_SPEAKER_TAB_NUM 5
#define TUBII_GUI_ANALOG_TAB_NUM 3
#define TUBII_GUI_GTDELAY_TAB_NUM 4
#define TUBII_GUI_CLOCK_TAB_NUM 6

@implementation TUBiiController

- (id)init{
    // Initialize by launching the GUI, referenced by the name of the xib/nib file
    self = [super initWithWindowNibName:@"TUBii"];
    return self;
}
- (void) awakeFromNib
{
    Tubii_size = NSMakeSize(450, 400);
    PulserAndDelays_size = NSMakeSize(500, 350);
    Triggers_size = NSMakeSize(600, 680);
    Analog_size = NSMakeSize(615, 445);
    GTDelays_size = NSMakeSize(500, 250);
    SpeakerCounter_size_small = NSMakeSize(575,550);
    SpeakerCounter_size_big = NSMakeSize(575,650);
    ClockMonitor_size = NSMakeSize(500, 175);
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    
    [super awakeFromNib];
    
    [tabView setDelegate:self];

    [CounterAdvancedOptionsBox setHidden:YES];
    [caenChannelSelect_3 setEnabled:NO];//Not currently working on board
    [self updateWindow];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    //we don't want this notification
    [notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubiiLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubiiLockChanged:)
                         name : ORTubiiLock
                       object : nil];
    
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTubiiLock to:secure];
    [tubiiLockButton setEnabled:secure];
}

- (void) tubiiLockChanged:(NSNotification*)aNotification
{
    
    //Basic ops
    BOOL locked						= [gSecurity isLocked:ORTubiiLock];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTubiiLock];
    
    //Tubii
    [tubiiLockButton setState: locked];
    [tubiiIPField setEnabled: !lockedOrNotRunningMaintenance];
    [tubiiPortField setEnabled: !lockedOrNotRunningMaintenance];
    [tubiiInitButton setEnabled: !lockedOrNotRunningMaintenance];
    [tubiiDataReadoutButton setEnabled: !lockedOrNotRunningMaintenance];
    [ECA_EnableButton setEnabled: !lockedOrNotRunningMaintenance];

    //Pulsers & Delays
    [SmellieRate_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [SmellieWidth_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [SmellieNPulses_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [TellieRate_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [TellieWidth_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [TellieNPulses_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [fireSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [fireTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [SmellieDelay_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [TellieDelay_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [GenericDelay_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [GenericRate_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [GenericWidth_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [GenericNPulses_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [loadSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadDelayButton setEnabled: !lockedOrNotRunningMaintenance];
    [firePulserButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopPulserButton setEnabled: !lockedOrNotRunningMaintenance];
    
    //Triggers
    [TrigMaskSelect setEnabled: !lockedOrNotRunningMaintenance];
    [sendTriggerMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchHWButton setEnabled: !lockedOrNotRunningMaintenance];
    [BurstRate setEnabled: !lockedOrNotRunningMaintenance];
    [BurstTriggerMask setEnabled: !lockedOrNotRunningMaintenance];
    [sendBurstButton setEnabled: !lockedOrNotRunningMaintenance];
    [ComboEnableMask setEnabled: !lockedOrNotRunningMaintenance];
    [ComboTriggerMask setEnabled: !lockedOrNotRunningMaintenance];
    [sendComboButton setEnabled: !lockedOrNotRunningMaintenance];
    [PrescaleFactor setEnabled: !lockedOrNotRunningMaintenance];
    [PrescaleTriggerMask setEnabled: !lockedOrNotRunningMaintenance];
    [sendPrescaleButton setEnabled: !lockedOrNotRunningMaintenance];
    [MTCAMimic_Slider setEnabled: !lockedOrNotRunningMaintenance];
    [MTCAMimic_TextField setEnabled: !lockedOrNotRunningMaintenance];
    [sendMTCAButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchMTCAButton setEnabled: !lockedOrNotRunningMaintenance];

    //Analog
    [caenChannelSelect_0 setEnabled: !lockedOrNotRunningMaintenance];
    [caenChannelSelect_1 setEnabled: !lockedOrNotRunningMaintenance];
    [caenChannelSelect_2 setEnabled: !lockedOrNotRunningMaintenance];
    [caenChannelSelect_3 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_0 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_1 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_2 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_3 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_4 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_5 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_6 setEnabled: !lockedOrNotRunningMaintenance];
    [caenGainSelect_7 setEnabled: !lockedOrNotRunningMaintenance];
    [matchAnalogButton setEnabled: !lockedOrNotRunningMaintenance];
    [sendAnalogButton setEnabled: !lockedOrNotRunningMaintenance];

    //GT Delays
    [LO_SrcSelect setEnabled: !lockedOrNotRunningMaintenance];
    [LO_Field setEnabled: !lockedOrNotRunningMaintenance];
    [DGT_Field setEnabled: !lockedOrNotRunningMaintenance];
    [LO_Slider setEnabled: !lockedOrNotRunningMaintenance];
    [DGT_Slider setEnabled: !lockedOrNotRunningMaintenance];
    [sendGTDelaysButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchGTDelaysButton setEnabled: !lockedOrNotRunningMaintenance];

    //Speaker & Counter
    [SpeakerMaskSelect_1 setEnabled: !lockedOrNotRunningMaintenance];
    [SpeakerMaskSelect_2 setEnabled: !lockedOrNotRunningMaintenance];
    [SpeakerMaskField setEnabled: !lockedOrNotRunningMaintenance];
    [matchSpeakerButton setEnabled: !lockedOrNotRunningMaintenance];
    [sendSpeakerButton setEnabled: !lockedOrNotRunningMaintenance];
    [checkSpeakerButton setEnabled: !lockedOrNotRunningMaintenance];
    [uncheckSpeakerButton setEnabled: !lockedOrNotRunningMaintenance];
    [CounterMaskSelect_1 setEnabled: !lockedOrNotRunningMaintenance];
    [CounterMaskSelect_2 setEnabled: !lockedOrNotRunningMaintenance];
    [CounterMaskField setEnabled: !lockedOrNotRunningMaintenance];
    [matchCounterButton setEnabled: !lockedOrNotRunningMaintenance];
    [sendCounterButton setEnabled: !lockedOrNotRunningMaintenance];
    [checkCounterButton setEnabled: !lockedOrNotRunningMaintenance];
    [uncheckCounterButton setEnabled: !lockedOrNotRunningMaintenance];
    [CounterLZBSelect setEnabled: !lockedOrNotRunningMaintenance];
    [CounterTestModeSelect setEnabled: !lockedOrNotRunningMaintenance];
    [CounterInhibitSelect setEnabled: !lockedOrNotRunningMaintenance];
    [CounterModeSelect setEnabled: !lockedOrNotRunningMaintenance];

    //Clock Monitor
    [DefaultClockSelect setEnabled: !lockedOrNotRunningMaintenance];
    [sendClockButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchClockButton setEnabled: !lockedOrNotRunningMaintenance];
    [resetClockButton setEnabled: !lockedOrNotRunningMaintenance];
    
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int tabIndex = [aTabView indexOfTabViewItem:item];
    NSSize* newSize = nil;
    switch (tabIndex) {
        case TUBII_GUI_PULSER_TAB_NUM:
            newSize = &PulserAndDelays_size;
            break;
        case TUBII_GUI_TRIGGER_TAB_NUM:
            newSize = &Triggers_size;
            break;
        case TUBII_GUI_TUBII_TAB_NUM:
            newSize = &Tubii_size;
            break;
        case TUBII_GUI_ANALOG_TAB_NUM:
            newSize = &Analog_size;
            break;
        case TUBII_GUI_GTDELAY_TAB_NUM:
            newSize = &GTDelays_size;
            break;
        case TUBII_GUI_SPEAKER_TAB_NUM:
            if([CounterAdvancedOptionsBox isHidden]) {
            newSize = &SpeakerCounter_size_small;
            }
            else {
                newSize = &SpeakerCounter_size_big;
            }
            break;
        case TUBII_GUI_CLOCK_TAB_NUM:
            newSize = &ClockMonitor_size;
            break;
        default:
            break;
    }
    if (newSize) {
        [[self window] setContentView:blankView]; //Put in a blank view for nicer transition look
        [self resizeWindowToSize:*newSize];
        [[self window] setContentView:tabView];
    }

}

#pragma mark •••Actions
- (IBAction)tubiiLockAction:(id)sender {
    [gSecurity tryToSetLock:ORTubiiLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction)InitializeClicked:(id)sender {
    @try{
        [model Initialize];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)SendPing:(id)sender {
    @try{
        [model Ping];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)DataReadoutChanged:(id)sender {
    if ([[sender selectedCell] tag] == 1) { //Data Readout On is selected
        @try{
            [model setDataReadout:YES];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else { //Data Readout Off is selected
        @try{
            [model setDataReadout:NO];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)PulserFire:(id)sender {
    //Eventually these functions should be changed to use setting the values like they were settings
    //rather then just sending them all at once.
    if ([sender tag] == 1){
        //Smellie Pulser is being fired
        @try{
            [model fireSmelliePulser_rate:[SmellieRate_TextField floatValue] pulseWidth:[SmellieWidth_TextField doubleValue] NPulses:[SmellieNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        //Tellie Pulser is being fired
        @try{
            [model fireTelliePulser_rate:[TellieRate_TextField floatValue] pulseWidth:[TellieWidth_TextField doubleValue] NPulses:[TellieNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        //Generic Pulser is being fired
        @try{
            [model firePulser_rate:[ GenericRate_TextField floatValue] pulseWidth:[GenericWidth_TextField doubleValue] NPulses:[GenericNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)PulserStop:(id)sender {
    //Stops the pulser from sending anymore pulses
    if([sender tag] == 1){
        @try{
            [model stopSmelliePulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        @try{
            [model stopTelliePulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        @try{
            [model stopPulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)LoadDelay:(id)sender {
    //Sends the selected delay value to TUBii
    int delay =0;
    if([sender tag] == 1){
        delay = [SmellieDelay_TextField integerValue];
        @try{
            [model setSmellieDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        delay = [TellieDelay_TextField integerValue];
        @try{
            [model setTellieDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        delay = [GenericDelay_TextField integerValue];
        @try{
            [model setGenericDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)TrigMaskMatchHardware:(id)sender {
    //Makes the trigger mask GUI element match TUBii's hardware state
    NSUInteger syncMask;
    NSUInteger asyncMask;
    @try {
        syncMask = [model syncTrigMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        asyncMask = [model asyncTrigMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    NSUInteger trigMaskVal = (syncMask | asyncMask);
    NSUInteger syncMaskVal = 16777215 - asyncMask;
    [self SendBitInfo:trigMaskVal FromBit:0 ToBit:24 ToCheckBoxes:TrigMaskSelect];
    [self SendBitInfo:syncMaskVal FromBit:24 ToBit:48 ToCheckBoxes:TrigMaskSelect];
}
- (IBAction)TrigMaskLoad:(id)sender {
    //Makes the trigger mask hardware state match the corresponding GUI element
    NSUInteger trigMaskVal = [self GetBitInfoFromCheckBoxes:TrigMaskSelect FromBit:0 ToBit:24];
    NSUInteger syncMaskVal = [self GetBitInfoFromCheckBoxes:TrigMaskSelect FromBit:24 ToBit:48];

    NSUInteger syncMask=0, asyncMask=0;
    for(int i=0; i<24; i++)
    {
        if(syncMaskVal & (1<<i))
        {
            if(trigMaskVal & (1<<i))
                syncMask |= 1<<i;
            else
                syncMask &= ~(1<<i);
            asyncMask &= ~(1<<i);
        }
        else
        {
            if(trigMaskVal & (1<<i))
                asyncMask |= 1<<i;
            else
                asyncMask &= ~(1<<i);
            syncMask &= ~(1<<i);
        }
    }
    
    @try{
        [model setTrigMask:syncMask setAsyncMask:asyncMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)BurstTriggerLoad:(id)sender {
    NSLog(@"Not yet implemented. :(");
}
- (IBAction)ComboTriggerLoad:(id)sender {
    NSUInteger enableMask = [ComboEnableMask integerValue];
    NSUInteger triggerMask = [ComboTriggerMask integerValue];
    @try{
        [model setComboTrigger_EnableMask:enableMask TriggerMask:triggerMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)PrescaleTriggerLoad:(id)sender {
    float factor = [PrescaleFactor floatValue];
    NSUInteger mask = [PrescaleTriggerMask integerValue];
    @try{
        [model setPrescaleTrigger_Mask:mask ByFactor:factor];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)TUBiiPGTLoad:(id)sender {
    float rate = [TUBiiPGTRate floatValue];
    @try{
        [model setTUBiiPGT_Rate:rate];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)TUBiiPGTStop:(id)sender {
    float rate = 0;
    @try{
        [model setTUBiiPGT_Rate:rate];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)CaenMatchHardware:(id)sender {
    //Makes the CAEN GUI reflect the current hardware state
    CAEN_CHANNEL_MASK ChannelMask;
    CAEN_GAIN_MASK GainMask;
    @try {
        ChannelMask = [model caenChannelMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        GainMask = [model caenGainMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }

    BOOL err = YES;
    err &= [caenChannelSelect_0 selectCellWithTag:(ChannelMask & channelSel_0)>0];
    err &= [caenChannelSelect_1 selectCellWithTag:(ChannelMask & channelSel_1)>0];
    err &= [caenChannelSelect_2 selectCellWithTag:(ChannelMask & channelSel_2)>0];
    err &= [caenChannelSelect_3 selectCellWithTag:(ChannelMask & channelSel_3)>0];
    err &= [caenGainSelect_0 selectCellWithTag:(GainMask & gainSel_0)>0];
    err &= [caenGainSelect_1 selectCellWithTag:(GainMask & gainSel_1)>0];
    err &= [caenGainSelect_2 selectCellWithTag:(GainMask & gainSel_2)>0];
    err &= [caenGainSelect_3 selectCellWithTag:(GainMask & gainSel_3)>0];
    err &= [caenGainSelect_4 selectCellWithTag:(GainMask & gainSel_4)>0];
    err &= [caenGainSelect_5 selectCellWithTag:(GainMask & gainSel_5)>0];
    err &= [caenGainSelect_6 selectCellWithTag:(GainMask & gainSel_6)>0];
    err &= [caenGainSelect_7 selectCellWithTag:(GainMask & gainSel_7)>0];
    if (err==NO) {
        NSLogColor([NSColor redColor],@"Error in CaenMatchHardware");
    }
}
- (IBAction)CaenLoadMask:(id)sender {
    //Sends the CAEN GUI values to TUBii
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
    @try{
        [model setCaenMasks:ChannelMask GainMask:GainMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }

}

- (IBAction)SpeakerMatchHardware:(id)sender {
    //Makes the Speaker/Counter GUI elements match the hardware
    NSUInteger maskVal =0;
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *textField = nil;

    if ([sender tag] ==1)
    {
        @try {
            maskVal = [model speakerMask];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        textField = SpeakerMaskField;
    }
    else if ([sender tag]==2)
    {
        @try {
            maskVal = [model speakerMask];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        textField = CounterMaskField;
    }
    [textField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:maskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:32 ToCheckBoxes:maskSelect_2];
}
- (IBAction)CounterMatchHardware:(id)sender {
    [self SpeakerMatchHardware:sender]; //Bit of a hack. I should probably rename the function
    CONTROL_REG_MASK ControlRegVal;
    BOOL counter_mode;
    @try {
        ControlRegVal = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    
    [CounterLZBSelect setState: (ControlRegVal & scalerLZB_Bit) > 0 ? NSOnState : NSOffState ];
    [CounterTestModeSelect setState: (ControlRegVal & scalerT_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    [CounterInhibitSelect setState: (ControlRegVal & scalerI_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    @try {
        counter_mode = [model CounterMode];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
    
    if (counter_mode) {
        [CounterModeSelect selectCellWithTag:1];
    }
    else {
        [CounterModeSelect selectCellWithTag:0];
    }
}
- (IBAction)SpeakerLoadMask:(id)sender {
    NSUInteger maskVal=0;
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    if ([sender tag] ==1){
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
    }
    else if ([sender tag]==2){
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
    }

    maskVal = [self GetBitInfoFromCheckBoxes:maskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:maskSelect_2 FromBit:16 ToBit:32];

    if ([sender tag] ==1) {
        @try{
            [model setSpeakerMask:maskVal];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if ([sender tag] ==2)
    {
        @try{
            [model setCounterMask:maskVal];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }

}
- (IBAction)CounterLoadMask:(id)sender {
    [self SpeakerLoadMask:sender];
    CONTROL_REG_MASK newControlReg;
    @try {
        newControlReg = [model controlReg];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
    newControlReg |=  [CounterLZBSelect intValue] ==1 ? scalerLZB_Bit : 0;
    newControlReg |=  [CounterTestModeSelect intValue] ==1 ? 0 : scalerT_Bit;
    newControlReg |=  [CounterInhibitSelect intValue] ==1 ? 0 : scalerI_Bit;
    @try{
        [model setControlReg:newControlReg];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
    if ([[CounterModeSelect selectedCell] tag] ==1) {
        //Rate Mode is selected
        @try {
            [model setCounterMode:YES];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else { //Totalizer Mode is selected
        @try {
            [model setCounterMode:NO];
        } @catch (NSException* exception) {
            [self log_error:exception];
            return;
        }
        
    }
}
- (IBAction)SpeakerCheckBoxChanged:(id)sender {
    NSUInteger maskVal = [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_2 FromBit:16 ToBit:32]<<16;
    [SpeakerMaskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];
}
- (IBAction)SpeakerFieldChanged:(id)sender {
    NSUInteger maskVal =[SpeakerMaskField integerValue];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:SpeakerMaskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:32 ToCheckBoxes:SpeakerMaskSelect_2];
}
- (IBAction)CounterCheckBoxChanged:(id)sender {
    NSUInteger maskVal = [self GetBitInfoFromCheckBoxes:CounterMaskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:CounterMaskSelect_2 FromBit:16 ToBit:32]<<16;
    [CounterMaskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];
}
- (IBAction)CounterFieldChanged:(id)sender {
    NSUInteger maskVal =[CounterMaskField integerValue];

    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:CounterMaskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:32 ToCheckBoxes:CounterMaskSelect_2];
}

- (IBAction)SpeakerCounterCheckAll:(id)sender {
    NSUInteger maskVal;
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *maskField =nil;
    if([sender tag] ==1)
    {
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        maskField = SpeakerMaskField;
    }
    else if([sender tag] == 2)
    {
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        maskField = CounterMaskField;
    }
    else{
        return;
    }
    [maskSelect_1 selectAll:nil];
    [maskSelect_2 selectAll:nil];
    maskVal = [self GetBitInfoFromCheckBoxes:maskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:maskSelect_2 FromBit:16 ToBit:32]<<16;
    [maskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];

}
- (IBAction)SpeakerCounterUnCheckAll:(id)sender {
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *maskField =nil;
    if([sender tag] ==1)
    {
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        maskField = SpeakerMaskField;
    }
    else if([sender tag] == 2)
    {
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        maskField = CounterMaskField;
    }
    else{
        return;
    }
    [maskSelect_1 deselectAllCells];
    [maskSelect_2 deselectAllCells];

    [maskField setStringValue:[NSString stringWithFormat:@"%i",0]];
}
- (IBAction)AdvancedOptionsButtonChanged:(id)sender{
    if([sender state] == NSOffState){
        [CounterAdvancedOptionsBox setHidden:YES];
        [self resizeWindowToSize:SpeakerCounter_size_small];
    }
    else{
        [CounterAdvancedOptionsBox setHidden:NO];
        if(self.window.frame.size.height < SpeakerCounter_size_big.height){
            [self resizeWindowToSize:SpeakerCounter_size_big];
        }
    }
}

- (IBAction)GTDelaysLoadMask:(id)sender {
    float LO_Delay = [LO_Field floatValue];
    float DGT_Delay = [DGT_Field floatValue];
    @try{
        [model setGTDelaysInNS:DGT_Delay LOValue:LO_Delay];
    } @catch (NSException* exception) {
        [self log_error:exception];
        return;
    }

    if([[LO_SrcSelect selectedCell] tag] ==1){
        //MTCD is LO Src is selected
        @try{
            [model setTUBiiIsLOSrc:NO];
        } @catch (NSException* exception) {
            [self log_error:exception];
            return;
        }
    }
    else {
        //TUBii is LO Src is selected
        @try{
            [model setTUBiiIsLOSrc:YES];
        } @catch (NSException* exception) {
            [self log_error:exception];
            return;
        }
    }
}
- (IBAction)GTDelaysMatchHardware:(id)sender {
    float LO_Delay;
    float DGT_Delay;
    CONTROL_REG_MASK controlReg;
    @try {
        DGT_Delay = [model DGTInNS];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [DGT_Slider setIntValue:DGT_Delay];
    [DGT_Field setIntValue:DGT_Delay];
    @try {
        LO_Delay = [model LODelayInNS];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [LO_Slider setIntValue:LO_Delay];
    [LO_Field setIntegerValue:LO_Delay];
    @try {
        controlReg = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    if ((controlReg & lockoutSel_Bit)>0){
        [LO_SrcSelect selectCellWithTag:1];
    }
    else {
        [LO_SrcSelect selectCellWithTag:2];
    }
    [self LOSrcSelectChanged:self];
}

- (IBAction)LOSrcSelectChanged:(id)sender {
    if([[LO_SrcSelect selectedCell] tag]==1){ //MTCD is selected
        [LO_Field setEnabled:NO];
        [LO_Slider setEnabled:NO];
    }
    else { //TUBii is selected
        [LO_Field setEnabled:YES];
        [LO_Slider setEnabled:YES];
    }
}
- (IBAction)LODelayLengthTextFieldChagned:(id)sender {
    NSTextField *field = nil;
    NSSlider *slider = nil;
    if ([sender tag]==1){
        field = LO_Field;
        slider = LO_Slider;
    }
    else {
        field = DGT_Field;
        slider = DGT_Slider;
    }
    float val = [field floatValue];
    [slider setFloatValue:val];
}
- (IBAction)LODelayLengthSliderChagned:(id)sender {
    NSTextField *field = nil;
    NSSlider *slider = nil;
    if ([sender tag]==1){
        field = LO_Field;
        slider = LO_Slider;
    }
    else {
        field = DGT_Field;
        slider = DGT_Slider;
    }
    [field setIntegerValue:[slider integerValue]];
}

- (IBAction)ResetClock:(id)sender {
    @try{
        [model ResetClock];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)ECAEnableChanged:(id)sender {
    if([[ECA_EnableButton selectedCell] tag]==1){ //ECA mode On is selected
        @try{
            [model setECALMode: YES];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else { //ECA mode Off is selected
        @try{
            [model setECALMode: NO];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
}

- (IBAction)MTCAMimicTextFieldChanged:(id)sender {
    //Used to keep the MTCA Mimic slider and text field in sync
    [MTCAMimic_Slider setFloatValue:[MTCAMimic_TextField floatValue]];
}
- (IBAction)MTCAMimicSliderChanged:(id)sender {
    //Used to keep the MTCA Mimic slider and text field in sync
    [MTCAMimic_TextField setStringValue:[NSString stringWithFormat:@"%.3f",[MTCAMimic_Slider floatValue]]];
}
- (IBAction)MTCAMimicMatchHardware:(id)sender {
    NSUInteger ThresholdValue;
    @try {
        ThresholdValue= [model MTCAMimic1_ThresholdInVolts];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }    //Bit value of the DAC

    [MTCAMimic_Slider setFloatValue:ThresholdValue];
    [MTCAMimic_TextField setFloatValue:ThresholdValue];
}
- (IBAction)MTCAMimicLoadValue:(id)sender {
    double value = [MTCAMimic_TextField floatValue];
    @try {
        [model setMTCAMimic1_ThresholdInVolts:value];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)LoadClockSource:(id)sender {
    BOOL tubii_is_default = ([[DefaultClockSelect selectedCell] tag] == 1);
    @try {
        [model setTUBiiIsDefaultClock: tubii_is_default];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)ClockSourceMatchHardware:(id)sender {
    CONTROL_REG_MASK cntrl_reg;
    @try {
        cntrl_reg = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    if(cntrl_reg & clkSel_Bit) {
        [DefaultClockSelect selectCellWithTag:1]; //TUBii Clk is tag 1
    }
    else {
        [DefaultClockSelect selectCellWithTag:2];//TUB Clk is tag 2
    }
}

#pragma mark •••Helper Functions
- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high {
    //Helper function to gather a bit value from a bunch of checkboxes
    NSUInteger maskVal = 0;
    for (int i=low; i<high; i++) {
        if([[aMatrix cellWithTag:i] intValue]>0)
        {
            maskVal |= (1<<(i-low));
        }
    }
    return maskVal;
}
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix {
    //Helper function to send a bit value to a bunch of check boxes
    for (int i=low;i<high;i++)
    {
        if((maskVal & 1<<(i-low)) >0)
        {
            [[aMatrix cellWithTag:i] setState:1];
        }
        else
        {
            [[aMatrix cellWithTag:i] setState:0];
        }
    }
}

-(void)log_error:(NSException *)e
{
    // Log an exception
    NSLogColor([NSColor redColor], @"[TUBii]: RedisClient exception from TUBii server: %@\n", [e reason]);
}
@end
