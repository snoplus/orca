#include "ORCAEN775Readout.hh"
#include <errno.h>


#define ShiftAndExtract(aValue,aShift,aMask) (((aValue)>>(aShift)) & (aMask))
#define v775BufferSizeInLongs 0x1000
#define v775BufferSizeInBytes (v775BufferSizeInLongs * sizeof(uint32_t))
bool ORCAEN775Readout::Start()
{
    uint16_t berrEnable = 0x1<<5;
    if (VMEWrite(GetBaseAddress() + 0x1010UL, GetAddressModifier(),
                 sizeof(berrEnable), berrEnable) < (int16_t) sizeof(berrEnable)){
        LogBusError("BusError: set 775 control Reg1 to 0x%08x\n", berrEnable);
        return false;
    }
 
    return true;
}

bool ORCAEN775Readout::Readout(SBC_LAM_Data* lamData)
{
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: fifo buffer size (in longs)                 */
    /* 3: fifo buffer address                         */
	uint32_t dataId            = GetHardwareMask()[0];
	uint32_t locationMask      = ((GetCrate() & 0x01e)<<21) | ((GetSlot() & 0x0000001f)<<16);
	uint32_t fifoAddress       = GetDeviceSpecificData()[1];
	
    uint32_t buffer[v775BufferSizeInLongs];
    
    int32_t numBytesRead = DMARead(GetBaseAddress()+fifoAddress,
                     0x39,
                     (uint32_t) 4,
                     (uint8_t*) buffer,
                     v775BufferSizeInBytes);
    
    if(numBytesRead > 0){
        bool doingEvent = false;
        int32_t numMemorizedChannels;
        int32_t numDecoded;
        int32_t savedDataIndex = dataIndex;
        uint32_t i;
        for(i=0;i<numBytesRead/4;i++){
            
            uint32_t dataWord = buffer[i];
            uint8_t dataType = ShiftAndExtract(dataWord,24,0x7);
            
            switch (dataType) {
                case 2: //header
                    if (doingEvent){
                        //something pathelogical happend. We were in an event and then
                        //got another header. dump the record in progress and start over.
                        dataIndex = savedDataIndex;
                    }
                    savedDataIndex = dataIndex; 
                    numMemorizedChannels = ShiftAndExtract(dataWord,8,0x3f);
                    ensureDataCanHold(numMemorizedChannels + 3);
                    numDecoded = 0;
                    doingEvent = true;
                break;
                    
                case 0: //data word
                    if(doingEvent){
                        //valid data. put into ORCA record
                        data[dataIndex++] = dataWord;
                        numDecoded++;
                        if(numDecoded > numMemorizedChannels){
                            //something is wrong, dump the event
                            dataIndex = savedDataIndex;
                            doingEvent = false;
                        }
                    }
                    else {
                        //something is wrong, dump the current event
                        dataIndex = savedDataIndex;
                        doingEvent = false;
                    }
                    break;
                    
                case 4: //end of block
                    if(doingEvent){
                        if(numDecoded==numMemorizedChannels){
                            data[dataIndex++] = dataWord;
                            //load the ORCA header
                            data[dataIndex++] = dataId | (numMemorizedChannels + 3);
                            data[dataIndex++] = locationMask;
                        }
                        else {
                            //something is wrong, dump the event
                            dataIndex = savedDataIndex;
                        }
                    }
                    else {
                        //something is wrong, dump the current event
                        dataIndex = savedDataIndex;
                    }
                    doingEvent = false;

                break;
                    
                default:
                    //something is wrong, dump the current event
                    dataIndex = savedDataIndex;
                    doingEvent = false;
                break;
            }
        }
        if(doingEvent){
            //appearently the last event was not complete. Dump it.
            dataIndex = savedDataIndex;
        }
        
    }
    else if(numWordsRead<0) {
        LogBusErrorForCard(GetSlot(),"CAEN 0x%0x dma read error",GetBaseAddress());
        return false; 
    }
	
    return true; 
}
