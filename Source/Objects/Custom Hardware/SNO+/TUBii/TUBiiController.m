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

- (id)init{
    // Initialize by launching the GUI, referenced by the name of the xib/nib file
    self = [super initWithWindowNibName:@"TUBii"];


    return self;
}
- (void) awakeFromNib{
    [tabView setFocusRingType:NSFocusRingTypeNone];
    
    PulserAndDelays_size = NSMakeSize(500, 350);
    Triggers_size = NSMakeSize(530, 575);
    Tubii_size = NSMakeSize(450, 400);
    Analog_size = NSMakeSize(615, 445);
    GTDelays_size = NSMakeSize(500, 250);
    SpeakerCounter_size = NSMakeSize(575,550);
    ClockMonitor_size = NSMakeSize(500, 175);

    [tabView setDelegate:self];

    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    [CounterAdvancedOptionsBox setHidden:YES];
    [caenChannelSelect_3 setEnabled:NO];//Not currently working on board
    [caenGainSelect_4 setEnabled:NO]; //Not currently working on board.
}
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item{
    int tabIndex = [aTabView indexOfTabViewItem:item];
    NSSize* newSize = nil;
    switch (tabIndex) {
        case 0:
            newSize = &PulserAndDelays_size;
            break;
        case 1:
            newSize = &Triggers_size;
            break;
        case 2:
            newSize = &Tubii_size;
            break;
        case 3:
            newSize = &Analog_size;
            break;
        case 4:
            newSize = &GTDelays_size;
            break;
        case 5:
            newSize = &SpeakerCounter_size;
            break;
        case 6:
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

// GUI actions. CTRL-drag handles from the IB into this file.
#pragma mark •••Actions
- (IBAction)DataReadoutChanged:(id)sender {
    if ([[sender selectedCell] tag] == 1) { //Data Readout On is selected
        [model setDataReadout:YES];
    }
    else { //Data Readout Off is selected
        [model setDataReadout:NO];
    }
    return;
}
- (IBAction)StatusReadoutChanged:(id)sender {
    if ([[sender selectedCell] tag] == 1) { //Status Readout On is selected
        [model setStatusReadout:YES];
    }
    else { //Status Readout Off is selected
        [model setStatusReadout:NO];
    }
    return;
}
- (IBAction)PulserFire:(id)sender {
    if ([sender tag] == 1){
        [model fireSmelliePulser];
    }
    else if([sender tag] == 2){
        [model fireTelliePulser];
    }
    else if([sender tag] == 3){
        [model firePulser];
    }
    return;
}
- (IBAction)PulserStop:(id)sender {
    if([sender tag] == 1){
        [model stopSmelliePulser];
    }
    else if([sender tag] == 2){
        [model stopTelliePulser];
    }
    else if([sender tag] == 3){
        [model stopPulser];
    }
    return;
}
- (IBAction)LoadDelay:(id)sender {
    int delay =0;
    if([sender tag] == 1){
        delay = [SmellieDelay_TextField integerValue];
        [model setSmellieDelay:delay];
    }
    else if([sender tag] == 2){
        delay = [TellieDelay_TextField integerValue];
        [model setTellieDelay:delay];
    }
    else if([sender tag] == 3){
        delay = [GenericDelay_TextField integerValue];
        [model setGenericDelay:delay];
    }
    return;
}
- (IBAction)TrigMaskSet:(id)sender {

}
- (IBAction)TrigMaskMatchHardware:(id)sender {
    NSUInteger maskVal = [model trigMask];
    [self SendBitInfo:maskVal FromBit:0 ToBit:21 ToCheckBoxes:TrigMaskSelect];
}
- (IBAction)TrigMaskLoad:(id)sender {
    NSUInteger maskVal = [self GetBitInfoFromCheckBoxes:TrigMaskSelect FromBit:0 ToBit:21];
    [model setTrigMask:maskVal];
}

- (IBAction)CaenMatchHardware:(id)sender {
  
    CAEN_CHANNEL_MASK ChannelMask = [model caenChannelMask];
    CAEN_GAIN_MASK GainMask = [model caenGainMask];

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
        NSLog(@"Error in CaenMatchHardware");
    }
    
}
- (IBAction)CaenLoadMask:(id)sender {
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
    [model setCaenMasks:ChannelMask GainMask:GainMask];
}

- (IBAction)SpeakerMatchHardware:(id)sender {
    NSUInteger maskVal =0;
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *textField = nil;

    if ([sender tag] ==1)
    {
        maskVal = [model speakerMask];
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        textField = SpeakerMaskField;
    }
    else if ([sender tag]==2)
    {
        maskVal = [model counterMask];
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        textField = CounterMaskField;
    }
    [textField setIntegerValue:maskVal];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:maskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:22 ToCheckBoxes:maskSelect_2];
}
- (IBAction)CounterMatchHardware:(id)sender {
    [self SpeakerMatchHardware:sender];
    CONTROL_REG_MASK ControlRegVal = [model controlReg];

    [CounterLZBSelect setState: (ControlRegVal & scalerLZB_Bit) > 0 ? NSOnState : NSOffState ];
    [CounterTestModeSelect setState: (ControlRegVal & scalerT_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    [CounterInhibitSelect setState: (ControlRegVal & scalerI_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    if ([model CounterMode]) {
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
    maskVal |= [self GetBitInfoFromCheckBoxes:maskSelect_2 FromBit:16 ToBit:22];

    if ([sender tag] ==1) {
        [model setSpeakerMask:maskVal];
    }
    else if ([sender tag] ==2)
    {
        [model setCounterMask:maskVal];
    }

}
- (IBAction)CounterLoadMask:(id)sender {
    [self SpeakerLoadMask:sender];
    CONTROL_REG_MASK newControlReg = [model controlReg];
    newControlReg =  [CounterLZBSelect intValue] ==1 ? scalerLZB_Bit : 0;
    newControlReg |=  [CounterTestModeSelect intValue] ==1 ? 0 : scalerT_Bit;
    newControlReg |=  [CounterInhibitSelect intValue] ==1 ? 0 : scalerI_Bit;
    [model setControlReg:newControlReg];
    if ([[CounterModeSelect selectedCell] tag] ==1) {
        //Rate Mode is selected
        [model setCounterMode:YES];
    }
    else { //Totalizer Mode is selected
        [model setCounterMode:NO];
    }

    }
- (IBAction)SpeakerCheckBoxChanged:(id)sender {
    NSUInteger maskVal = [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_2 FromBit:16 ToBit:22];
    [SpeakerMaskField setStringValue:[NSString stringWithFormat:@"%i",maskVal]];
}
- (IBAction)SpeakerFieldChanged:(id)sender {
    NSUInteger maskVal =[SpeakerMaskField integerValue];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:SpeakerMaskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:22 ToCheckBoxes:SpeakerMaskSelect_2];
}
- (IBAction)CounterCheckBoxChanged:(id)sender {
    NSUInteger maskVal = [self GetBitInfoFromCheckBoxes:CounterMaskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:CounterMaskSelect_2 FromBit:16 ToBit:22];
    [CounterMaskField setStringValue:[NSString stringWithFormat:@"%i",maskVal]];
}
- (IBAction)CounterFieldChanged:(id)sender {
    NSUInteger maskVal =[CounterMaskField integerValue];

    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:CounterMaskSelect_1];
    [self SendBitInfo:maskVal FromBit:16 ToBit:22 ToCheckBoxes:CounterMaskSelect_2];
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
    maskVal |= [self GetBitInfoFromCheckBoxes:maskSelect_2 FromBit:16 ToBit:22];
    [maskField setStringValue:[NSString stringWithFormat:@"%i",maskVal]];

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
        [self resizeWindowToSize:SpeakerCounter_size];
    }
    else{
        [CounterAdvancedOptionsBox setHidden:NO];
        NSSize newSize = SpeakerCounter_size;
        newSize.height += 100;
        if(self.window.frame.size.height < newSize.height){
            [self resizeWindowToSize:newSize];
        }
    }
}

- (IBAction)GTDelaysLoadMask:(id)sender {
    float LO_Delay = [LO_Field floatValue];
    float DGT_Delay = [DGT_Field floatValue];
    [model setGTDelaysInNS:DGT_Delay LOValue:LO_Delay];

    if([[LO_SrcSelect selectedCell] tag] ==1){
        //MTCD is LO Src is selected
        [model setTUBiiIsLOSrc:NO];
    }
    else {
        //TUBii is LO Src is selected
        [model setTUBiiIsLOSrc:YES];
    }
}
- (IBAction)GTDelaysMatchHardware:(id)sender {
    float LO_Delay = [model LODelayInNS];
    [LO_Slider setIntValue:LO_Delay];
    [LO_Field setIntegerValue:LO_Delay];
    float DGT_Delay = [model DGTInNS];
    [DGT_Slider setIntValue:DGT_Delay];
    [DGT_Field setIntValue:DGT_Delay];
    if (([model controlReg] & lockoutSel_Bit)>0){
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
    [model ResetClock];
}
- (IBAction)ECAEnableChanged:(id)sender {
    if([[ECA_EnableButton selectedCell] tag]==1){ //ECA mode On is selected
        [model setECALMode: YES];
    }
    else { //ECA mode Off is selected
        [model setECALMode: NO];
    }
}

- (IBAction)MTCAMimicTextFieldChanged:(id)sender {
    [MTCAMimic_Slider setFloatValue:[MTCAMimic_TextField floatValue]];
}
- (IBAction)MTCAMimicSliderChanged:(id)sender {
    [MTCAMimic_TextField setStringValue:[NSString stringWithFormat:@"%.3f",[MTCAMimic_Slider floatValue]]];
}
- (IBAction)MTCAMimicMatchHardware:(id)sender {
    NSUInteger ThresholdValue= [model MTCAMimic1_ThresholdInVolts];
    //Bit value of the DAC

    [MTCAMimic_Slider setFloatValue:ThresholdValue];
    [MTCAMimic_TextField setFloatValue:ThresholdValue];
}
- (IBAction)MTCAMimicLoadValue:(id)sender {
    double value = [MTCAMimic_TextField floatValue];
    [model setMTCAMimic1_ThresholdInVolts:value];
}

- (IBAction)LoadClockSource:(id)sender {
    if([[DefaultClockSelect selectedCell] tag]==1){
        [model setTUBiiIsDefaultClock: YES];
    }
    else {
        [model setTUBiiIsDefaultClock: NO];
    }
}
- (IBAction)ClockSourceMatchHardware:(id)sender {
}

#pragma mark •••Helper Functions
- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high {
    NSUInteger maskVal = 0;
    for (int i=low; i<high; i++) {
        if([[aMatrix cellWithTag:i] intValue]>0)
        {
            maskVal |= (1<<i);
        }
    }
    return maskVal;
}
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix {
    for (int i=low;i<high;i++)
    {
        if((maskVal & 1<<i) >0)
        {
            [[aMatrix cellWithTag:i] setState:1];
        }
        else
        {
            [[aMatrix cellWithTag:i] setState:0];
        }
    }
}
@end