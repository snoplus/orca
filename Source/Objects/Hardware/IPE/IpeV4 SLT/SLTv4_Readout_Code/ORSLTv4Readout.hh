#ifndef _ORSLTv4Readout_hh_
#define _ORSLTv4Readout_hh_
#include "ORVCard.hh"
#include <iostream>

class ORSLTv4Readout : public ORVCard
{
  public:
    ORSLTv4Readout(SBC_card_info* ci) : ORVCard(ci) {} 
    virtual ~ORSLTv4Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORSLTv4Readout_hh_*/
