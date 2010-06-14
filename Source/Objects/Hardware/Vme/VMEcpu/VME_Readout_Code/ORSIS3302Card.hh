#include "ORVVmeCard.hh"
#include <vector>

class ORSIS3302Card: public ORVVmeCard
{
   public:
       ORSIS3302Card(SBC_card_info* card_info);
       virtual ~ORSIS3302Card() {}

	   virtual bool Start();
       virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	   virtual bool Stop();
       enum EORSIS3302Consts {
           kNumberOfChannels = 8,
	       kHeaderSizeInLongs = 2,
	       kTrailerSizeInLongs = 4};


   protected:
       virtual uint32_t GetPreviousBankSampleRegisterOffset(size_t channel);
       virtual uint32_t GetADCBufferRegisterOffset(size_t channel);
       virtual inline uint32_t GetAcquisitionControl()
           { return 0x10; }
       virtual inline uint32_t GetADCMemoryPageRegister()
           { return 0x34; }

       virtual inline uint32_t GetDataWidth() { return 0x4; }

	   virtual bool IsEvent();
       virtual bool ReadOutChannel(size_t channel);

       virtual bool DisarmAndArmBank(size_t bank);
       virtual bool DisarmAndArmNextBank()
           { return (fBankOneArmed) ? DisarmAndArmBank(1) : DisarmAndArmBank(0); }
       virtual size_t GetNumberOfChannels() { return kNumberOfChannels; }

       bool fBankOneArmed;
	   std::vector<std::vector<uint32_t> > fSetOfTempVectors;
	   std::vector<size_t> fSetOfTempVectorIters;

};
