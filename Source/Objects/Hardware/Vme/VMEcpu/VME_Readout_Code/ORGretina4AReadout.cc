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
    uint32_t fifoAddressMod   = GetDeviceSpecificData()[2];
    uint32_t fifoResetAddress = GetDeviceSpecificData()[3];
    uint32_t eventLength      = GetDeviceSpecificData()[4]/2;
    uint32_t dataId           = GetHardwareMask()[0];
    uint32_t slot             = GetSlot(); 
    uint32_t crate            = GetCrate(); 
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
    uint32_t fifoState = 0;
    int32_t result = VMERead(fifoStateAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     fifoState);
    
    fifoState = (fifoState >>20) & 0x7F;

    uint32_t amountToRead = 0;
    if (result != sizeof(fifoState)){
        LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",fifoStateAddress,strerror(errno));
        return true;
    }
    

    if (fifoState & 0x3)        amountToRead = 0;     //fifo is empty
    else if (fifoState & 0x4)   amountToRead = 4095;  //almost empty
    else if (fifoState == 0)    amountToRead = 131072;//partially full
    else if (fifoState & 0x8)   amountToRead = 520192;//half full
    else if (fifoState & 0x10)  amountToRead = 524287;//almost full
    
    if(amountToRead != 0){
        
        //LogMessageForCard(GetSlot(),"Gretina4A Fifo state: 0x%x",fifoState);
        ensureDataCanHold(amountToRead+2);
     
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = dataId | 0; //we will pack in as many events as we can and fill in the length below
        data[dataIndex++] = location;
        int32_t eventStartIndex = dataIndex;

        result = DMARead(fifoAddress,fifoAddressMod, (uint32_t) 4,
                         (uint8_t*)(&data[eventStartIndex]),amountToRead);
        

        if (result < 0) {
            LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",baseAddress,strerror(errno));
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
            clearFifo(fifoResetAddress);
        }
        
        else {
            //step thru the data until we get to the end of the valid data packets
            uint32_t dataLength = 0;
            uint32_t n = 0;
            while(data[eventStartIndex] == kGretinaPacketSeparator){
                eventStartIndex += eventLength+1;
                
                //LogMessage"len: %d",eventLength);
               // LogMessage("-1: 0x%x",data[eventStartIndex-1]);
                //LogMessage("0: 0x%x",data[eventStartIndex]);
                //LogMessage("+1: 0x%x",data[eventStartIndex+1]);

                dataLength += eventLength;
                n++;
                //LogMessage("Length: %u %u %u",n, dataLength,amountToRead);
                if(dataLength>amountToRead)break; //sanity check
            }
            //LogMessage("n: %d",n);

            if(dataLength>0){
                data[savedIndex] |= (dataLength+2); //put the total length + ORCA header into the first word
                dataIndex += dataLength+1; //the next data word is one past this set
            }
            else {
                //oops... really bad -- the buffer read is out of sequence
                dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
                LogBusErrorForCard(GetSlot(),"Fifo Rst: Gretina4A slot %d",slot);
                clearFifo(fifoResetAddress);
            }
        }
    }

    return true; 
}

void ORGretina4AReadout::clearFifo(uint32_t fifoClearAddress)
{
    uint32_t orginalData = 0;
    int32_t result = VMERead(fifoClearAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData |= (0x1<<27);

    result = VMEWrite(fifoClearAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                      orginalData);

    if (result != sizeof(orginalData)){
        LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData &= ~(0x1<<27);

    result = VMEWrite(fifoClearAddress,
                      GetAddressModifier(),
                      (uint32_t) 0x4,
                      orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4A 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
}
