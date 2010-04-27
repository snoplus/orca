#ifndef _ORCaen1785Readout_hh_
#define _ORCaen1785Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCaen1785Readout : public ORVVmeCard
{
  public:
    ORCaen1785Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCaen1785Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
  protected:
	virtual void FlushDataBuffer();
};

#endif /* _ORCaen1785Readout_hh_*/
