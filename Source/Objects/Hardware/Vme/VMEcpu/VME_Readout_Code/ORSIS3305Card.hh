#include "ORVVmeCard.hh"
#include <time.h>

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
		kOrcaHeaderInLongs		 = 4,
		kHeaderSizeInLongsNoWrap = 2,
		kHeaderSizeInLongsWrap	 = 4,
		kTrailerSizeInLongs		 = 4
	};
	
	
protected:
	virtual uint32_t GetPreviousBankSampleRegisterOffset(size_t channel);
	virtual uint32_t GetADCBufferRegisterOffset(size_t channel);
	
	virtual inline uint32_t GetAcquisitionControl()		{ return 0x10; }
	virtual inline uint32_t GetADCMemoryPageRegister()	{ return 0x34; }
	virtual inline uint32_t GetDataWidth()				{ return 0x4; }
	virtual inline  size_t  GetNumberOfChannels()		{ return kNumberOfChannels; }
	
	virtual bool DisarmAndArmBank(size_t bank);
	virtual bool DisarmAndArmNextBank();
	virtual bool IsEvent();
	virtual void ReadOutChannel(size_t channel);
	virtual bool SetupPageReg();
	virtual bool resetSampleLogic();
	
	bool     fPulseMode;
	bool     fProcessPulse;
	bool	 fWaitingForSomeChannels;
	bool	 fBankOneArmed;
	uint32_t fWaitCount;
	time_t	 fLastBankSwitchTime;
	uint32_t fChannelsToReadMask;
	uint32_t dmaBuffer[0x200000]; //2M Longs (8MB)
};
