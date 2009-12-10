#ifndef _ORFLTv4Readout_hh_
#define _ORFLTv4Readout_hh_
#include "ORVCard.hh"

class ORFLTv4Readout : public ORVCard
{
  public:
    ORFLTv4Readout(SBC_card_info* ci) : ORVCard(ci) {} 
    virtual ~ORFLTv4Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);

    enum EORFLTv4Consts {
        kFifoEmpty = 0x01,
        kNumChan   = 24,
        kFirstTimeFlag   = 0x10000
    };
};

#endif /* _ORFLTv4Readout_hh_*/
