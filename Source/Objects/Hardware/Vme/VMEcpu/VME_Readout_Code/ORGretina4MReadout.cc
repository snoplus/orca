#include "ORGretina4MReadout.hh"
#include <errno.h>
#include <stdio.h>
#include <iostream>
using namespace std;
bool ORGretina4MReadout::Readout(SBC_LAM_Data* /*lamData*/)
{

#define kGretinaPacketSeparator ((int32_t)(0xAAAAAAAA))
#define kGretina4MFIFOEmpty			0x100000
#define kGretina4MFIFOAlmostEmpty	0x400000
#define kGretina4MFIFO16KFull       0x800000
#define kGretina4MFIFO30KFull		0x1000000
#define kGretina4MFIFOFull          0x2000000
    
    uint32_t baseAddress      = GetBaseAddress();  
    uint32_t fifoStateAddress = GetDeviceSpecificData()[0];
    uint32_t fifoAddress      = GetDeviceSpecificData()[1];
    uint32_t fifoAddressMod   = GetDeviceSpecificData()[2];
    uint32_t fifoResetAddress = GetDeviceSpecificData()[3];
    uint32_t serialNumber     = GetDeviceSpecificData()[4] & 0xffff;
    uint32_t dataId           = GetHardwareMask()[0];
    uint32_t slot             = GetSlot(); 
    uint32_t crate            = GetCrate(); 
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16) || serialNumber;

    int32_t  result;
    uint32_t fifoState = 0;
    result = VMERead(fifoStateAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     fifoState);
    if (result != sizeof(fifoState)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoStateAddress,strerror(errno));
    }
    else if ((fifoState & kGretina4MFIFOEmpty) == 0 ) {
        
        //we want to read as much as possible to have the highest thru-put
        int32_t                                     numEventsToRead = 1;
        if(fifoState & kGretina4MFIFO30KFull)       numEventsToRead = 16;
        else if(fifoState & kGretina4MFIFO16KFull)  numEventsToRead = 8;

        int32_t i;
        for(i=0;i<numEventsToRead;i++){
            ensureDataCanHold(1024+2);
     
            int32_t savedIndex = dataIndex;
            data[dataIndex++]  = dataId | 1026;
            data[dataIndex++]  = location;
            
            result = DMARead(fifoAddress,fifoAddressMod, (uint32_t) 4, (uint8_t*)(&data[dataIndex]),1024*4);
        
            if ((result < 0) || (data[dataIndex] != kGretinaPacketSeparator)) {
                dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
                if(result < 0)  LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                else            LogBusErrorForCard(slot,"No Separator: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                clearFifo(fifoResetAddress);
                break;
            }
            else {
                dataIndex+=1024;
            }
        }
    }

    return true; 
}

void ORGretina4MReadout::clearFifo(uint32_t fifoClearAddress)
{
    uint32_t slot             = GetSlot();
    uint32_t orginalData = 0;
    int32_t result = VMERead(fifoClearAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData |= (0x1<<27);

    result = VMEWrite(fifoClearAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                      orginalData);

    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData &= ~(0x1<<27);

    result = VMEWrite(fifoClearAddress,
                      GetAddressModifier(),
                      (uint32_t) 0x4,
                      orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
}
