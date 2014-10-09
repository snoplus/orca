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
    uint32_t addressModifier    = GetAddressModifier();
    uint32_t baseAdd            = GetBaseAddress();
    int32_t result = VMERead(baseAdd + statusRegOffset,addressModifier, sizeof(statusWord),statusWord);
    
    if(result != sizeof(statusWord)){
        LogBusError("Status Rd: V830 0x%04x %s",GetBaseAddress(),strerror(errno));
    }
    else  {
        bool dataReady = statusWord & (0x1L << 0);
		if(dataReady){
			uint32_t dataId			= GetHardwareMask()[0];
			uint32_t locationMask	= ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x1f)<<16);
			
			uint16_t numEvents = 0;
			uint32_t mebEventNumRegOffset	= GetDeviceSpecificData()[2];
            result = VMERead(baseAdd + mebEventNumRegOffset,addressModifier, sizeof(numEvents), numEvents);
			if(result != sizeof(numEvents)){
				LogBusError("Num Events Rd: V830 0x%04x %s",baseAdd+mebEventNumRegOffset,strerror(errno));
			}
			else if(numEvents){
				
				uint32_t enabledMask		= GetDeviceSpecificData()[0];
				uint32_t eventBufferOffset	= GetDeviceSpecificData()[3];
				uint32_t numEnabledChannels	= GetDeviceSpecificData()[4];
				
				for(uint32_t event=0;event<numEvents;event++){
					ensureDataCanHold(5+numEnabledChannels); //event size
					data[dataIndex++] = dataId | (5+numEnabledChannels);
					data[dataIndex++] = locationMask;
                    uint32_t indexForRollOver = dataIndex;  //save a place for the roll over
                    data[dataIndex++] = 0;                  //channel 0 rollover
					data[dataIndex++] = enabledMask;
                    
                    uint32_t indexForHeader         = dataIndex;
                    uint32_t indexForFirstChannel   = dataIndex+1; //save a reference for the first chan location (1 past header)
                    
                    uint32_t numBytesToRead = (numEnabledChannels+1)*4;
                    
                    result = DMARead(baseAdd+eventBufferOffset,
                                     0x0B, //(A32 non-privileged MBLT )
                                     (uint32_t) 4,
                                     (uint8_t*) (data+indexForHeader),
                                     numBytesToRead);
                    dataIndex += (numEnabledChannels+1); //bump the index and include the header
                    
                    if(chan0Enabled){
                        uint32_t chan0Value = data[indexForFirstChannel];
                        //keep a rollover count for channel zero
                        if(chan0Value!=0){
                            if(chan0Value<lastChan0Count){
                                rollOverCount++;
                            }
                            lastChan0Count = chan0Value;
                            data[indexForRollOver]      = rollOverCount;
                            data[indexForFirstChannel]  = chan0Value + chan0Offset; //there's a timing offset
                        }
                        else {
                            data[indexForRollOver]      = 0xffffffff;
                            data[indexForFirstChannel]  = 0xffffffff;
                        }
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
