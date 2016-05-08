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
    //NSSizes used for resizing window on tab change
    NSSize PulserAndDelays_size;
    NSSize Triggers_size;
    NSSize Tubii_size;
    NSSize Analog_size;
    NSSize GTDelays_size;
    NSSize SpeakerCounter_size_big;
    NSSize SpeakerCounter_size_small;
    NSSize ClockMonitor_size;
    // These references to UI elements are created by CTRL-dragging them into this
    // header file. Note the connection dots on the left.
    IBOutlet NSTabView *tabView;

    IBOutlet NSMatrix *TrigMaskSelect;
    IBOutlet NSTextField *BurstTriggerMask;
    IBOutlet NSTextField *BurstRate;
    IBOutlet NSTextField *ComboEnableMask;
    IBOutlet NSTextField *ComboTriggerMask;
    IBOutlet NSTextField *PrescaleTriggerMask;
    IBOutlet NSTextField *PrescaleFactor;

    IBOutlet NSMatrix *caenChannelSelect_3;
    IBOutlet NSMatrix *caenChannelSelect_2;
    IBOutlet NSMatrix *caenChannelSelect_1;
    IBOutlet NSMatrix *caenChannelSelect_0;
    IBOutlet NSMatrix *caenGainSelect_0;
    IBOutlet NSMatrix *caenGainSelect_1;
    IBOutlet NSMatrix *caenGainSelect_2;
    IBOutlet NSMatrix *caenGainSelect_3;
    IBOutlet NSMatrix *caenGainSelect_4;
    IBOutlet NSMatrix *caenGainSelect_5;
    IBOutlet NSMatrix *caenGainSelect_6;
    IBOutlet NSMatrix *caenGainSelect_7;

    IBOutlet NSMatrix *SpeakerMaskSelect_1;
    IBOutlet NSMatrix *SpeakerMaskSelect_2;
    IBOutlet NSTextField *SpeakerMaskField;

    IBOutlet NSMatrix *CounterMaskSelect_1;
    IBOutlet NSMatrix *CounterMaskSelect_2;
    IBOutlet NSTextField *CounterMaskField;
    IBOutlet NSBox *CounterAdvancedOptionsBox;
    IBOutlet NSBox *CounterMaskSelectBox;
    IBOutlet NSButton *CounterLZBSelect;
    IBOutlet NSButton *CounterTestModeSelect;
    IBOutlet NSButton *CounterInhibitSelect;
    IBOutlet NSMatrix *CounterModeSelect;

    IBOutlet NSMatrix *ECA_EnableButton;
    
    IBOutlet NSTextField *DGT_Field;
    IBOutlet NSTextField *LO_Field;
    IBOutlet NSSlider *LO_Slider;
    IBOutlet NSSlider *DGT_Slider;
    IBOutlet NSMatrix *LO_SrcSelect;

    IBOutlet NSSlider *MTCAMimic_Slider;
    IBOutlet NSTextField *MTCAMimic_TextField;

    IBOutlet NSTextField *SmellieDelay_TextField;
    IBOutlet NSTextField *TellieDelay_TextField;
    IBOutlet NSTextField *GenericDelay_TextField;

    IBOutlet NSTextField *SmellieRate_TextField;
    IBOutlet NSTextField *TellieRate_TextField;
    IBOutlet NSTextField *GenericRate_TextField;

    IBOutlet NSTextField *SmellieWidth_TextField;
    IBOutlet NSTextField *TellieWidth_TextField;
    IBOutlet NSTextField *GenericWidth_TextField;

    IBOutlet NSTextField *SmellieNPulses_TextField;
    IBOutlet NSTextField *TellieNPulses_TextField;
    IBOutlet NSTextField *GenericNPulses_TextField;

    IBOutlet NSMatrix *DefaultClockSelect;

    NSButton *ClockSourceMatchHardware;
}
- (id) init;
- (void) awakeFromNib;

- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high;
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix;

- (IBAction)InitializeClicked:(id)sender;
- (IBAction)SendPing:(id)sender;
- (IBAction)DataReadoutChanged:(id)sender;

- (IBAction)TrigMaskMatchHardware:(id)sender;
- (IBAction)TrigMaskLoad:(id)sender;
- (IBAction)BurstTriggerLoad:(id)sender;
- (IBAction)ComboTriggerLoad:(id)sender;
- (IBAction)PrescaleTriggerLoad:(id)sender;

- (IBAction)CaenMatchHardware:(id)sender;
- (IBAction)CaenLoadMask:(id)sender;

- (IBAction)SpeakerMatchHardware:(id)sender;
- (IBAction)CounterMatchHardware:(id)sender;
- (IBAction)SpeakerLoadMask:(id)sender;
- (IBAction)CounterLoadMask:(id)sender;
- (IBAction)SpeakerCheckBoxChanged:(id)sender;
- (IBAction)SpeakerFieldChanged:(id)sender;
- (IBAction)SpeakerCounterCheckAll:(id)sender;
- (IBAction)SpeakerCounterUnCheckAll:(id)sender;

- (IBAction)CounterCheckBoxChanged:(id)sender;
- (IBAction)CounterFieldChanged:(id)sender;
- (IBAction)AdvancedOptionsButtonChanged:(id)sender;

- (IBAction)GTDelaysMatchHardware:(id)sender;
- (IBAction)GTDelaysLoadMask:(id)sender;
- (IBAction)LOSrcSelectChanged:(id)sender;
- (IBAction)LODelayLengthTextFieldChagned:(id)sender;
- (IBAction)LODelayLengthSliderChagned:(id)sender;
- (IBAction)ResetClock:(id)sender;

- (IBAction)ECAEnableChanged:(id)sender;
- (IBAction)MTCAMimicTextFieldChanged:(id)sender;
- (IBAction)MTCAMimicSliderChanged:(id)sender;
- (IBAction)MTCAMimicMatchHardware:(id)sender;
- (IBAction)MTCAMimicLoadValue:(id)sender;
- (IBAction)LoadClockSource:(id)sender;
- (IBAction)ClockSourceMatchHardware:(id)sender;


@end