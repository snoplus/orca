#include "ORMTCReadout.hh"
#include <cmath>
#include "readout_code.h" 
bool ORMTCReadout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t leaf_index;
    //uint32_t baseAddress            = config->card_info[index].base_add;
    char triggered = 0;
    //uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    //add mtc read-out specifics.... TBD
    
    //check for trigger, if trigger exists, set triggered = 1
    
    if(triggered){
        //we have a trigger so read out the FECs for event
        leaf_index = GetNextTriggerIndex()[0];
        while(leaf_index >= 0) {
            leaf_index = readout_card(leaf_index,lamData);
        }
    }

    return true; 
}
