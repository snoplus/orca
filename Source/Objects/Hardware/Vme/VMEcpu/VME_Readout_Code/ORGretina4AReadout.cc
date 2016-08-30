#include "ORGretina4AReadout.hh"
#include <errno.h>
#include <stdio.h>
#include <iostream>
#include <sys/time.h>
using namespace std;
bool ORGretina4AReadout::Readout(SBC_LAM_Data* /*lamData*/)
{

#define kGretinaPacketSeparator ((int32_t)(0xAAAAAAAA))
    
    uint32_t baseAddress      = GetBaseAddress();  
    uint32_t fifoStateAddress = GetDeviceSpecificData()[0];
    uint32_t fifoAddress      = GetDeviceSpecificData()[1];
//    uint32_t fifoAddressMod   = GetDeviceSpecificData()[2];
    uint32_t fifoResetAddress = GetDeviceSpecificData()[3];
    uint32_t packetLength     = GetDeviceSpecificData()[4]/2;
    uint32_t dataId           = GetHardwareMask()[0];
    uint32_t slot             = GetSlot(); 
    uint32_t crate            = GetCrate(); 
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
    uint32_t fifoState        = 0;
    int32_t result            = VMERead(fifoStateAddress,
                                        GetAddressModifier(),
                                        0x4,
                                        fifoState);

    if (result != sizeof(fifoState)) {
        LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",fifoStateAddress,strerror(errno));
        return true;
    }

    if(((fifoState>>20) & 0x3)!=0x3) { //both bits are high if FIFO is empty

        printf("got an event; %d\n",packetLength);
        ensureDataCanHold(packetLength+2);
 
        int32_t savedIndex      = dataIndex;
        data[dataIndex++]       = dataId | (packetLength+2); //longs!!
        data[dataIndex++]       = location;
        int32_t eventStartIndex = dataIndex;

        result = DMARead(fifoAddress,
                         0x0B,
                         4,
                         (uint8_t*)(&data[eventStartIndex]),
                         packetLength*4); //bytes!!
        

        if (result < 0) {
            printf("result: %d\n",result);
            LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",baseAddress,strerror(errno));
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
            clearFifo(fifoResetAddress);
            return true;
        }
        
        printf("0: 0x%08x\n",data[eventStartIndex]);
        printf("1: 0x%08x\n",data[eventStartIndex+1]);
        printf("2: 0x%08x\n",data[eventStartIndex+2]);
        printf("3: 0x%08x\n",data[eventStartIndex+3]);
        printf("4: 0x%08x\n",data[eventStartIndex+4]);
        printf("5: 0x%08x\n",data[eventStartIndex+5]);
        printf("6: 0x%08x\n",data[eventStartIndex+6]);

        if(data[eventStartIndex] != kGretinaPacketSeparator){
            LogBusErrorForCard(GetSlot(),"Packet Err: Gretina4A 0x%04x %s",baseAddress,strerror(errno));
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
            clearFifo(fifoResetAddress);
        }
    }
    return true; 
}

void ORGretina4AReadout::clearFifo(uint32_t fifoClearAddress)
{
    uint32_t val = 0x1<<27;
    VMEWrite(fifoClearAddress,GetAddressModifier(),0x4,val);
    val = 0;
    VMEWrite(fifoClearAddress,GetAddressModifier(),0x4,val);
}
