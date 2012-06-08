#include "ORCAEN830Readout.hh"
#include <errno.h>
#include <sys/timeb.h>
#include "readout_code.h"

bool ORCAEN830Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t statusRegOffset		= GetDeviceSpecificData()[1];
     
    uint8_t theStatusReg;
    if(VMERead(GetBaseAddress() + statusRegOffset,0x9, sizeof(theStatusReg),theStatusReg) == sizeof(theStatusReg)){
		if(theStatusReg & 0x1){
			uint32_t dataId			= GetHardwareMask()[0];
			uint32_t locationMask	= ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x1f)<<16);
			
			uint16_t numEvents = 0;
			uint32_t mebEventNumRegOffset	= GetDeviceSpecificData()[2];
			if(VMERead(GetBaseAddress() + mebEventNumRegOffset,0x09, sizeof(numEvents), numEvents) != sizeof(numEvents)){
				LogBusError("Rd Err: V830 0x%04x %s",GetBaseAddress()+mebEventNumRegOffset,strerror(errno)); 
			}
			else if(numEvents){
				
				uint32_t enabledMask		= GetDeviceSpecificData()[0];
				uint32_t eventBufferOffset	= GetDeviceSpecificData()[3];
				uint32_t numEnabledChannels	= GetDeviceSpecificData()[4];
				uint32_t dataFormatWord		= GetDeviceSpecificData()[5];
				
				for(int16_t event=0;event<numEvents;event++){
					ensureDataCanHold(5+numEnabledChannels); //event size
					data[dataIndex++] = dataId | (5+numEnabledChannels);
					data[dataIndex++] = locationMask;
					data[dataIndex++] = dataFormatWord;
					data[dataIndex++] = enabledMask;
					
					//get the header -- always the first word
					uint32_t dataHeader = 0;
					if(VMERead(GetBaseAddress() + eventBufferOffset,0x9, sizeof(dataHeader),dataHeader)!= sizeof(numEvents)){
						LogBusError("Rd Err: V830 0x%04x %s",GetBaseAddress()+eventBufferOffset,strerror(errno)); 
					}
					data[dataIndex++] = dataHeader;
					
					for(uint16_t aWord=0 ; aWord<numEnabledChannels ; aWord++){
						uint32_t aValue;
						if(VMERead(GetBaseAddress() + eventBufferOffset,0x9, sizeof(aValue), aValue) != sizeof(numEvents)){
							LogBusError("Rd Err: V830 0x%04x %s",GetBaseAddress()+eventBufferOffset,strerror(errno)); 
						}
						data[dataIndex++] = aValue;
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
	else {
        LogBusError("Rd Err: V830 0x%04x %s",GetBaseAddress(),strerror(errno)); 
    }
    return true; 
}
