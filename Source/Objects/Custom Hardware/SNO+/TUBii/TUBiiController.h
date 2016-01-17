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
    NSSize SpeakerCounter_size;
    NSSize ClockMonitor_size;
    // These references to UI elements are created by CTRL-dragging them into this
    // header file. Note the connection dots on the left.
    IBOutlet NSTabView *tabView;

    IBOutlet NSMatrix *TrigMaskSelect;

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

    IBOutlet NSMatrix *DefaultClockSelect;

    NSButton *ClockSourceMatchHardware;
}
-(id) init;




- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high;
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix;

- (float) ConvertBitsToValue:(NSUInteger)bits NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;
- (NSUInteger) ConvertValueToBits: (float) value NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;

- (IBAction)StatusReadoutChanged:(id)sender;
- (IBAction)DataReadoutChanged:(id)sender;

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