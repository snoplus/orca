#ifndef _ORMTCReadout_hh_
#define _ORMTCReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORMTCReadout : public ORVVmeCard
{
  public:
    ORMTCReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORMTCReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORMTCReadout_hh_*/
