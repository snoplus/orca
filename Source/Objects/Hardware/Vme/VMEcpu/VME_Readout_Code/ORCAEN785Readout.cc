#include "ORCAEN785Readout.hh"
#include <errno.h>

#define ShiftAndExtract(aValue,aShift,aMask) (((aValue)>>(aShift)) & (aMask))

bool ORCaen785Readout::Readout(SBC_LAM_Data* lamData)
{
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: fifo buffer size (in longs)                 */
    /* 3: fifo buffer address                         */
    uint16_t statusOne, statusTwo;
    int32_t result;
	uint32_t dataId            = GetHardwareMask()[0];
	uint32_t locationMask      = ((GetCrate() & 0x01e)<<21) | 
                                    ((GetSlot() & 0x0000001f)<<16);
    uint32_t statusOneAddress  = GetBaseAddress() + GetDeviceSpecificData()[0];
    uint32_t statusTwoAddress  = GetBaseAddress() + GetDeviceSpecificData()[1];
    uint32_t fifoAddress       = GetDeviceSpecificData()[3];
	
	//read the states
    result = VMERead(statusOneAddress,
                     0x39,
                     sizeof(statusOne),
                     statusOne);
	
    if (result != sizeof(statusOne)) {
        LogBusError("CAEN 0x%0x status 1 read",GetBaseAddress());
        return false; 
    }
	
	result = VMERead(statusTwoAddress,
                     0x39,
                     sizeof(statusTwo),
                     statusTwo);
    if (result != sizeof(statusTwo)) {
        LogBusError("CAEN 0x%0x status 2 read",GetBaseAddress());
        return false; 
    }
	
	uint8_t bufferIsNotBusy =  !((statusOne & 0x0004) >> 2);
    uint8_t dataIsReady     =  statusOne & 0x0001;
    uint8_t bufferIsFull    =  (statusTwo & 0x0004) >> 2;
	
    if ((bufferIsNotBusy && dataIsReady) || bufferIsFull) {
		//OK, at least one data value is ready, first value read should be a header
		uint32_t dataValue;
		result = VMERead(GetBaseAddress()+fifoAddress, 0x39, sizeof(dataValue), dataValue);
		if((result == sizeof(dataValue)) && (ShiftAndExtract(dataValue,24,0x7) == 0x2)){
			int32_t numMemorizedChannels = ShiftAndExtract(dataValue,8,0x3f);
			int32_t i;
			if((numMemorizedChannels>0)){
				//make sure the data buffer can hold our data. Note that we do NOT ship the end of block. 
				ensureDataCanHold(numMemorizedChannels + 3);
				
				int32_t savedDataIndex = dataIndex;
				data[dataIndex++] = dataId | (numMemorizedChannels + 3);
				data[dataIndex++] = locationMask;
				uint8_t dataOK = true;
				for(i=0;i<numMemorizedChannels;i++){
					result = VMERead(GetBaseAddress()+fifoAddress, 0x39, sizeof(dataValue), dataValue);
					if((result == sizeof(dataValue)) && (ShiftAndExtract(dataValue,24,0x7) == 0x0))data[dataIndex++] = dataValue;
					else {
						dataOK = false;
						dataIndex = savedDataIndex;
						LogBusError("Rd Err: CAEN 785 0x%04x %s", GetBaseAddress(),strerror(errno)); 
						FlushDataBuffer();
						break;
					}
				}
				if(dataOK){
					//OK we read the data, get the end of block
					result = VMERead(GetBaseAddress()+fifoAddress, 0x39, sizeof(dataValue), dataValue);
					if((result != sizeof(dataValue)) || (ShiftAndExtract(dataValue,24,0x7) != 0x4)){
						//some kind of bad error, report and flush the buffer
						LogBusError("Rd Err: CAEN 785 0x%04x %s", GetBaseAddress(),strerror(errno)); 
						dataIndex = savedDataIndex;
						FlushDataBuffer();
					}
					else data[dataIndex++] = dataValue;
				}
			}
		}
	}
	
    return true; 
}

void ORCaen785Readout::FlushDataBuffer()
{
 	uint32_t fifoAddress     = GetDeviceSpecificData()[3];
	//flush the buffer, read until not valid datum
	int32_t i;
	for(i=0;i<0x07FC;i++) {
		uint32_t dataValue;
		int32_t result = VMERead(GetBaseAddress()+fifoAddress, 0x39, sizeof(dataValue), dataValue);
		if(result<0){
			LogBusError("Flush Err: CAEN 785 0x%04x %s", GetBaseAddress(),strerror(errno)); 
			break;
		}
		if(ShiftAndExtract(dataValue,24,0x7) == 0x6) break;
	}
}
