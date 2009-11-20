#ifndef _ORFECReadout_hh_
#define _ORFECReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORFECReadout : public ORVVmeCard
{
  public:
    ORFECReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORFECReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORFECReadout_hh_*/
