#ifndef _ORCAEN830Readout_hh_
#define _ORCAEN830Readout_hh_
#include "ORVVmeCard.hh"

class ORCAEN830Readout : public ORVVmeCard
{
  public:
    ORCAEN830Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAEN830Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORCAEN830Readout_hh_*/
