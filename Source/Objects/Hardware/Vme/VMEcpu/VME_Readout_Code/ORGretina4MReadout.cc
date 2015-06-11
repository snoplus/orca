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
    uint32_t dataId           = GetHardwareMask()[0];
    uint32_t slot             = GetSlot(); 
    uint32_t crate            = GetCrate(); 
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);

    int32_t  result;
    uint32_t fifoState = 0;

    result = VMERead(fifoStateAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     fifoState);
    if (result != sizeof(fifoState)){
        LogBusError("Rd Err: Gretina4 0x%04x %s",fifoStateAddress,strerror(errno));
    }
    else if ((fifoState & kGretina4MFIFOEmpty) == 0 ) {
        //we want to read as much as possible to have the highest thru-put
        int32_t numEventsToRead = 1;
        if(fifoState & kGretina4MFIFO30KFull) numEventsToRead = 16;
        else if(fifoState & kGretina4MFIFO16KFull)numEventsToRead = 8;

        ensureDataCanHold((1024*numEventsToRead)+2);
     
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = dataId | 0; //we will pack in as many events as we can and fill in the length below
        data[dataIndex++] = location;
        
        int32_t eventStartIndex = dataIndex;
        
        result = DMARead(fifoAddress,fifoAddressMod, (uint32_t) 4,
                         (uint8_t*)(&data[eventStartIndex]),1024*4*numEventsToRead);
        
        if (result < 0) {
            LogBusError("Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
            clearFifo(fifoResetAddress);
        }
        
        else {
            int32_t eventCount = 0;
            while(data[eventStartIndex] == kGretinaPacketSeparator){
                eventCount++;
                if(eventCount>=numEventsToRead)break;
                eventStartIndex+=1024;
            }
            
            if(eventCount>0){
                data[savedIndex] |= ((numEventsToRead*1024)+2);
                dataIndex += eventCount*1024;
            }
            else {
                //oops... really bad -- the buffer read is out of sequence
                dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
                LogBusError("Fifo Rst: Gretina4 slot %d",slot);
                clearFifo(fifoResetAddress);
            }
        }
    }

    return true; 
}

void ORGretina4MReadout::clearFifo(uint32_t fifoClearAddress)
{
    uint32_t orginalData = 0;
    int32_t result = VMERead(fifoClearAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusError("Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData |= (0x1<<27);

    result = VMEWrite(fifoClearAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                      orginalData);

    if (result != sizeof(orginalData)){
        LogBusError("Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData &= ~(0x1<<27);

    result = VMEWrite(fifoClearAddress,
                      GetAddressModifier(),
                      (uint32_t) 0x4,
                      orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusError("Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
}
