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
    NSSize SpeakerCounter_size;
    NSTabView *tabView;

    NSMatrix *TrigMaskSelect;

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

    NSMatrix *SpeakerMaskSelect_1;
    NSMatrix *SpeakerMaskSelect_2;
    NSMatrix *SpeakerMaskSelect_3;
    NSTextField *SpeakerMaskField;

    NSMatrix *CounterMaskSelect_1;
    NSMatrix *CounterMaskSelect_2;
    NSTextField *CounterMaskField;
    NSBox *CounterAdvancedOptionsBox;
    NSBox *CounterMaskSelectBox;
    NSButton *CounterLZBSelect;
    NSButton *CounterTestModeSelect;
    NSButton *CounterInhibitSelect;
    NSMatrix *ECA_EnableButton;
    
    NSTextField *DGT_Field;
    NSTextField *LO_Field;
    NSSlider *LO_Slider;
    NSSlider *DGT_Slider;
    NSMatrix *LO_SrcSelect;

    NSSlider *MTCAMimic_Slider;
    NSTextField *MTCAMimic_TextField;

}
-(id) init;

// These references to UI elements are created by CTRL-dragging them into this
// header file. Note the connection dots on the left.
@property (assign,weak) IBOutlet NSTabView *tabView;

@property (assign,weak) IBOutlet NSMatrix *TrigMaskSelect;
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
@property (assign,weak) IBOutlet NSMatrix *SpeakerMaskSelect_1;
@property (assign,weak) IBOutlet NSMatrix *SpeakerMaskSelect_2;
@property (assign,weak) IBOutlet NSTextField *SpeakerMaskField;
@property (assign,weak) IBOutlet NSMatrix *CounterMaskSelect_1;
@property (assign,weak) IBOutlet NSMatrix *CounterMaskSelect_2;
@property (assign,weak) IBOutlet NSTextField *CounterMaskField;
@property (assign,weak) IBOutlet NSBox *CounterAdvancedOptionsBox;
@property (assign,weak) IBOutlet NSBox *CounterMaskSelectBox;
@property (assign,weak) IBOutlet NSButton *CounterLZBSelect;
@property (assign,weak) IBOutlet NSButton *CounterTestModeSelect;
@property (assign,weak) IBOutlet NSButton *CounterInhibitSelect;

@property (assign,weak) IBOutlet NSTextField *DGT_Field;
@property (assign,weak) IBOutlet NSSlider *LO_Slider;
@property (assign,weak) IBOutlet NSSlider *DGT_Slider;
@property (assign,weak) IBOutlet NSTextField *LO_Field;
@property (assign,weak) IBOutlet NSMatrix *LO_SrcSelect;

@property (assign) IBOutlet NSSlider *MTCAMimic_Slider;
@property (assign) IBOutlet NSTextField *MTCAMimic_TextField;

- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high;
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix;

- (float) ConvertBitsToValue:(NSUInteger)bits NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;
- (NSUInteger) ConvertValueToBits: (float) value NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;

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

@end