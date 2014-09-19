#include "ORCAEN830Readout.hh"
#include <errno.h>
#include <sys/timeb.h>
#include "readout_code.h"

bool ORCAEN830Readout::Start()
{
	lastChan0Count  = 0x0;
	rollOverCount      = 0x0;
    uint32_t enabledMask = GetDeviceSpecificData()[0];
    if(enabledMask & (0x1)) chan0Enabled = true;
    else                    chan0Enabled = false;
	return true;
}

bool ORCAEN830Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t statusRegOffset	= GetDeviceSpecificData()[1];
    int32_t chan0Offset		    = (int32_t)GetDeviceSpecificData()[5];
    uint16_t statusWord;
    uint32_t addressModifier = 0x09;

    int32_t result = VMERead(GetBaseAddress() + statusRegOffset,addressModifier, sizeof(statusWord),statusWord);
    
    if(result != sizeof(statusWord)){
        LogBusError("Status Rd: V830 0x%04x %s",GetBaseAddress(),strerror(errno));
    }
    else  {
        bool dataReady = statusWord & (0x1L << 0);
        bool cardBusy  = statusWord & (0x1L << 4);
		if(dataReady & !cardBusy){
			uint32_t dataId			= GetHardwareMask()[0];
			uint32_t locationMask	= ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x1f)<<16);
			
			uint16_t numEvents = 0;
			uint32_t mebEventNumRegOffset	= GetDeviceSpecificData()[2];
            result = VMERead(GetBaseAddress() + mebEventNumRegOffset,addressModifier, sizeof(numEvents), numEvents);
			if(result != sizeof(numEvents)){
				LogBusError("Num Events Rd: V830 0x%04x %s",GetBaseAddress()+mebEventNumRegOffset,strerror(errno)); 
			}
			else if(numEvents){
				
				uint32_t enabledMask		= GetDeviceSpecificData()[0];
				uint32_t eventBufferOffset	= GetDeviceSpecificData()[3];
				uint32_t numEnabledChannels	= GetDeviceSpecificData()[4];
				
				for(uint32_t event=0;event<numEvents;event++){
					ensureDataCanHold(5+numEnabledChannels); //event size
					data[dataIndex++] = dataId | (5+numEnabledChannels);
					data[dataIndex++] = locationMask;
					data[dataIndex++] = enabledMask;
                    
                    uint32_t indexForRollOver = dataIndex;  //save a place for the roll over
					data[dataIndex++] = 0;                  //channel 0 rollover
					
					//get the header -- always the first word
					uint32_t dataHeader = 0;
					if(VMERead(GetBaseAddress() + eventBufferOffset,addressModifier, sizeof(dataHeader),dataHeader)!= sizeof(dataHeader)){
						LogBusError("Header Rd: V830 0x%04x %s",GetBaseAddress()+eventBufferOffset,strerror(errno)); 
					}
					data[dataIndex++] = dataHeader;
					
					for(uint16_t i=0 ; i<numEnabledChannels ; i++){
						uint32_t aValue;
						if(VMERead(GetBaseAddress() + eventBufferOffset,addressModifier, sizeof(aValue), aValue) != sizeof(aValue)){
							LogBusError("Data Rd: V830 0x%04x %s",GetBaseAddress()+eventBufferOffset,strerror(errno)); 
						}
                        //keep a rollover count for channel zero
                        if(chan0Enabled && i==0){
                            aValue += chan0Offset;
                            if(aValue<lastChan0Count){
                                rollOverCount++;
                            }
                            lastChan0Count = aValue;
                            data[indexForRollOver] = rollOverCount;
                        }
                        data[dataIndex++]      = aValue;
					}
					
					int32_t leaf_index;
					//read out the children that are in the readout list
					leaf_index = GetNextTriggerIndex()[0];
					while(leaf_index >= 0) {
						leaf_index = readout_card(leaf_index,lamData);
					}
					
				}
			}
		}
	}
    return true; 
}
