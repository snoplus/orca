#ifndef _ORFLTv4Readout_hh_
#define _ORFLTv4Readout_hh_
#include "ORVCard.hh"
#include <iostream>


/** For every card in the Orca configuration one instance of ORFLTv4Readout is constructed.
  *
  * Short firmware history (Firmware is CFPGA,FPGA8=X.X.X.X,X.X.X.X version):
  * - 2.1.1.4., 2.1.2.1: Filter redesign (timing problems), k-offset of energy fixed, FIFO redesign, 6+SUM channel veto
  * - 2.1.1.1., 2.1.1.1 and smaller: first version(s)
  */
class ORFLTv4Readout : public ORVCard
{
  public:
    ORFLTv4Readout(SBC_card_info* ci) : ORVCard(ci) {} 
    virtual ~ORFLTv4Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
	virtual bool Stop();
	void ClearSumHistogramBuffer();

    enum EORFLTv4Consts {
        kFifoEmpty = 0x01,
        kNumChan   = 24,
        kNumFLTs   = 20,
		kMaxHistoLength   = 2048
    };
	
	uint32_t sumHistogram[kNumChan][kMaxHistoLength];
	uint32_t recordingTimeSum[kNumChan];
};

#endif /* _ORFLTv4Readout_hh_*/
