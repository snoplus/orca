#include "ORVVmeCard.hh"
#include <time.h>

class ORSIS3316Card: public ORVVmeCard
{
public:
	ORSIS3316Card(SBC_card_info* card_info);
	virtual ~ORSIS3316Card() {}
	
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	virtual bool Resume();
	virtual bool Stop();
    
	
protected:
	
	virtual void DisarmAndArmBank();
    uint32_t currentBank;
	uint32_t prevRunningBank;
	time_t	 fLastBankSwitchTime;
};
