#include "ORCAEN1724Readout.hh"
#include <errno.h> 
bool ORCAEN1724Readout::Readout(SBC_LAM_Data* lamData)
{
    // WARNING, this code has *not* been tested!!!!!

    uint32_t numEventsAvailReg  = GetDeviceSpecificData()[0];
    uint32_t eventSizeReg       = GetDeviceSpecificData()[1];
    uint32_t fifoBuffReg        = GetDeviceSpecificData()[2];
    uint32_t fifoAddressMod     = GetDeviceSpecificData()[3];
    uint32_t fifoBuffSize       = GetDeviceSpecificData()[4];
    uint32_t location           = GetDeviceSpecificData()[5];
    uint32_t numBLTEventsReg    = GetDeviceSpecificData()[7];
    uint32_t dataId             = GetHardwareMask()[0];
    
    uint32_t numEventsToReadout = 0;
    
    int32_t result = VMERead(GetBaseAddress()+numBLTEventsReg,
                             GetAddressModifier(),
                             sizeof(numEventsToReadout),
                             numEventsToReadout);
    if ( result != sizeof(numEventsToReadout) ) { 
        LogBusError("CAEN 0x%0x Couldn't read register", numBLTEventsReg);
        return false; 
    }
    if ( numEventsToReadout == 0 ) {
        // We will have a problem, this needs to be set *before*
        // starting a run.
        LogError("CAEN: BLT Events register must be set BEFORE run start");
        return false; 
    }
    
    uint32_t numEventsAvail;    
    result = VMERead(GetBaseAddress()+numEventsAvailReg,
                     GetAddressModifier(),
                     sizeof(numEventsAvail),
                     numEventsAvail);
    if(result == sizeof(numEventsAvail) && (numEventsAvail > 0)){
        //if at least one event is ready
        uint32_t eventSize;
        // Get the event size
        result = VMERead(GetBaseAddress()+eventSizeReg,
                         GetAddressModifier(),
                         sizeof(eventSize),
                         eventSize);
        if(result == sizeof(eventSize) && eventSize>0){
            uint32_t startIndex = dataIndex;
            if ( (int32_t)(numEventsToReadout*(eventSize+1) + 2) > 
                 (kMaxDataBufferSizeLongs-dataIndex) ) {
                /* We can't read out. */ 
                LogError("Temp buffer too small, requested (%d) > available (%d)",
                          numEventsToReadout*(eventSize+1)+2, 
                          kMaxDataBufferSizeLongs-dataIndex);
                return false; 
            } 
            
            //load ORCA header info
            ensureDataCanHold(2+numEventsToReadout*eventSize);
            
            data[dataIndex++] = dataId | (2+numEventsToReadout*eventSize);
            data[dataIndex++] = location; //location = crate and card number
          
            uint32_t numBytesRead = 0;
            result = DMARead(GetBaseAddress()+fifoBuffReg,
                             fifoAddressMod,
                             (uint32_t) 8,
                             (uint8_t*) (data+dataIndex),
                             fifoBuffSize);
            if ( result < 0 ) {
                LogBusError("Error reading DMA for V1724: %s", strerror(errno));
                dataIndex = startIndex;
                return true; 
            }
            dataIndex += result/4;
            if ( dataIndex + fifoBuffSize/4 > kMaxDataBufferSizeLongs ) {
                /* Error checking, for some reason we will 
                   read past our buffer.*/
                /* Reset to not do that. */
                dataIndex = startIndex;
                LogError("CAEN V1724: Error reading into buffer, trying to continue.");
            } 
            numBytesRead += result;
            uint32_t numberOfEndWords = 0;         
            if ( (uint32_t)data[dataIndex-1] == 0xFFFFFFFF ) numberOfEndWords = 1;
          
            if ( numBytesRead != numEventsToReadout*(eventSize+numberOfEndWords)*4 ) {
                dataIndex = startIndex; //just flush the event
                return true; 
            }
            // Reading out with a BERR coudl leave an extra word on the end, 
            // get rid of it.
            dataIndex -= numberOfEndWords;
        } else {
            LogBusError("Rd Err: V1724 0x%04x %s",
                GetBaseAddress(),strerror(errno));                
        }
    }

    return true; 
}
