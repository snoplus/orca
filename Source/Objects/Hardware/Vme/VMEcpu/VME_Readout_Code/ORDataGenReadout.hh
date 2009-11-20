#ifndef _ORDataGenReadout_hh_
#define _ORDataGenReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORDataGenReadout : public ORVVmeCard
{
  public:
    ORDataGenReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORDataGenReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORDataGenReadout_hh_*/
