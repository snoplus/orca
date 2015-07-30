#include "ORVVmeCard.hh"
#include <time.h>


// This is a *subset* of the registers that seem useful for readout tasks.

#define kSIS3305ControlStatus                       0x0	  /* read/write; D32 */
#define kSIS3305ModID                               0x4	  /* read only; D32 */
#define kSIS3305IrqConfig                           0x8      /* read/write; D32 */
#define kSIS3305IrqControl                          0xC      /* read/write; D32 */

#define kSIS3305AcquisitionControl                  0x10      /* read/write; D32 */

#define kSIS3305ADCSerialInterfaceReg               0x74    /* read/write D32 */

#define kSIS3305DataTransferADC14CtrlReg            0xC0    /* read/write D32 */
#define kSIS3305DataTransferADC58CtrlReg            0xC4    /* read/write D32 */
#define kSIS3305DataTransferADC14StatusReg          0xC8    /* read D32 */
#define kSIS3305DataTransferADC58StatusReg          0xCC    /* read D32 */

#define kSIS3305KeyReset                            0x400	/* write only; D32 */
#define kSIS3305KeyArmSampleLogic                   0x410   /* write only; D32 */
#define kSIS3305KeyDisarmSampleLogic                0x414   /* write only, D32 */
#define kSIS3305KeyTrigger                          0x418	/* write only; D32 */
#define kSIS3305KeyEnableSampleLogic                0x41C   /* write only; D32 */
#define kSIS3305KeySetVeto                          0x420   /* write only; D32 */
#define kSIS3305KeyClrVeto                          0x424	/* write only; D32 */
#define kSIS3305ADCSynchPulse                       0x430   /* write only D32 */
#define kSIS3305ADCFpgaReset                        0x434   /* write only D32 */
#define kSIS3305ADCExternalTriggerOutPulse          0x43C   /* write only D32 */

#pragma mark - Event Configuration Registers
#define kSIS3305EventConfigADC14                    0x2000  /* read/write */
#define kSIS3305EventConfigADC58                    0x3000  /* read/write */


#pragma mark - Sample Memory Start Address Registers
#define kSIS3305SampleStartAddressADC14             0x2004
#define kSIS3305SampleStartAddressADC58             0x3004

#pragma mark - Sample/Extended Block Length Registers
#define kSIS3305SampleLengthADC14                   0x2008
#define kSIS3305SampleLengthADC58                   0x3008

#pragma mark - Direct Memory Stop Pretrigger Block Length Registers
#define kSIS3305SamplePretriggerLengthADC14         0x200C
#define kSIS3305SamplePretriggerLengthADC58         0x300C

#pragma mark - Direct Memory Max Nof Events Registers
#define kSIS3305MaxNofEventsADC14                   0x2018
#define kSIS3305MaxNofEventsADC58                   0x3018

#pragma mark - End Address Threshold registers
#define kSIS3305EndAddressThresholdADC14            0x201C
#define kSIS3305EndAddressThresholdADC58            0x301C


#define kSIS3305Space1ADCDataFIFOCh14      0x8000
#define kSIS3305Space1ADCDataFIFOCh58      0xC000

#define kSIS3305Space2ADCDataFIFOCh14      0x800000
#define kSIS3305Space2ADCDataFIFOCh58      0xC00000


class ORSIS3305Card: public ORVVmeCard
{
public:
	ORSIS3305Card(SBC_card_info* card_info);
	virtual ~ORSIS3305Card() {}
	
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	virtual bool Resume();
	virtual bool Stop();
	
	enum EORSIS3305Consts {
		kNumberOfChannels		 = 8,
		kOrcaHeaderInLongs		 = 3,
		kSISHeaderSizeInLongsNoWrap = 4,
		kSISHeaderSizeInLongsWrap	 = 16,
		kTrailerSizeInLongs		 = 0
	};
    

	
protected:
	virtual uint32_t GetPreviousBankSampleRegisterOffset(size_t channel);
	virtual uint32_t GetADCBufferRegisterOffset(size_t channel);
	
	virtual inline uint32_t GetAcquisitionControl()		{ return 0x10; }
	virtual inline uint32_t GetADCMemoryPageRegister()	{ return 0x34; }
	virtual inline uint32_t GetDataWidth()				{ return 0x4; }
	virtual inline  size_t  GetNumberOfChannels()		{ return kNumberOfChannels; }
	

	virtual bool IsEvent();
	virtual void ReadOutChannel(size_t channel);
	virtual bool resetSampleLogic();
	
	bool     fPulseMode;
	bool     fProcessPulse;
	bool	 fWaitingForSomeChannels;
	uint32_t fChannelsToReadMask;
	uint32_t dmaBuffer[0x200000]; //2M Longs (8MB)
};
