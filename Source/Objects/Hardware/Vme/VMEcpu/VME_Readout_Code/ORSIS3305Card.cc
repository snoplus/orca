#include "ORSIS3305Card.hh"
#include <errno.h>
#include <unistd.h>






ORSIS3305Card::ORSIS3305Card(SBC_card_info* ci) :
ORVVmeCard(ci), 
firstTime(true)
{
}




bool ORSIS3305Card::Start()
{
    LogBusError("Entering start.../n");

    int group;
    for(group=0;group<2;group++){
//        uint32_t sisHeaderLength = 4;  // 4 long words in the normal sis headers

        orcaHeaderLength = 3;   // 3 words in the Orca header
        
        // data record length is the length in longs without the Orca header (how much we will read)
        // total record length is how much space it will take in longs on disk (with Orca header)
        dataRecordLength[group] = kSISHeaderSizeInLongsNoWrap + ORSIS3305Card::longsInSample(group);
        totalRecordLength[group] = dataRecordLength[group] + orcaHeaderLength;
        

    }
    firstTime = false;
    
    enableSampleLogic();
//    [self pulseExternalTriggerOut];     // this may or may not be desired
	return true;
    
    return 0;
}

bool ORSIS3305Card::Stop()
{
	//read out the last buffer, if there's a problem, just continue
	//if (!DisarmAndArmNextBank())return true;
	//usleep(50);
	//for( size_t i=0;i<GetNumberOfChannels();i++) {
	//	ReadOutChannel(i);
	//}	
	return true;
}

bool ORSIS3305Card::Resume()
{
	return true;
}

bool ORSIS3305Card::IsEvent()
{
    /*
    uint32_t addr = GetBaseAddress() + ORSIS3305Card::GetAcquisitionControl();
    uint32_t data_rd = 0;
    if (VMERead(addr,GetAddressModifier(),4,data_rd) != sizeof(data_rd)) { 
		LogBusError("Bank Arm Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno)); 
    	return false;
    }
	uint32_t bankMask = fBankOneArmed?0x10000:0x20000;
	return  ((data_rd & 0x80000) == 0x80000) &&  
			((data_rd & bankMask) == bankMask);
    */
    return 0;
}



//bool ORSIS3305Card::resetSampleLogic()
//{
//	uint32_t data_wr = 0;				
//	uint32_t addr = GetBaseAddress() + 0x404 ;
//	if (VMEWrite(addr , GetAddressModifier(), GetDataWidth(),data_wr) != sizeof(data_wr)){
//		LogBusError("Logic Reset Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
//		return false;
//	}
//	return DisarmAndArmNextBank();
//}

bool ORSIS3305Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{
    
//    uint32_t dataId            = GetHardwareMask()[0];  // FIX: Oughtn't this to be used?
//    uint32_t locationMask      = ((GetCrate() & 0xf)<<21) |
//    ((GetSlot() & 0x1f)<<16);
    
//    uint32_t onlineMask        = GetDeviceSpecificData()[0];
//    uint32_t firstAdcRegOffset = GetDeviceSpecificData()[2];
//    uint8_t  shipTimeStamp     = GetDeviceSpecificData()[3];
    
    uint32_t ac; // acquisition control reg value
    uint32_t addr = kSIS3305AcquisitionControl + GetBaseAddress();;
    
    LogBusError("Entering readout loop.../n");
//    uint32_t* dataRecord[group]	= malloc((totalRecordLength[group])*sizeof(uint32_t));
    
    
//    ac = VMERead(addr,GetAddressModifier(),GetDataWidth(),1,sizeof(uint32_t)) != sizeof(uint32_t))
    
    int32_t error =  VMERead(addr,                      // address
                             GetAddressModifier(),      // address modifier
                             GetDataWidth(),            // data width/unit size (1,2, or 4)
                             (uint8_t*)&ac,             // buffer* (short)
                             sizeof(uint32_t));         // number of bytes
    if (error != sizeof(int32_t)){
        LogBusError("Acquisition Control Reg Readout Error: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
        return 0;
    }
    
    if(!((ac>>19)&0x1))
        return false;
    //if we get here, there may be something to read out
	
    // stop sampling while reading out
    ORSIS3305Card::disarmSampleLogic();
    
    // first prepare some variables we'll want
    // the "2" in these is the number of groups in the 3305
//    uint32_t sampleAddress[2];      // apparently unused? should be actualSampleAddress[group]... this is the same as numberBytesToRead[group]
    uint32_t numberOfWords[2];      // 16*actualSampleAddress(group)
    uint32_t numberBytesToRead[2];  // 4*numberOfWords[group]
    
    // write the data transfer control regs
    // Transfer Control ch1to4, start internal readout (copy from Memory to VME FPGA)
    // Transfer Control ch5to8, start internal readout (copy from Memory to VME FPGA)
    ORSIS3305Card::writeDataTransferControlReg(0,2,0);  // (group, command, address)
    ORSIS3305Card::writeDataTransferControlReg(1,2,0);
    // Can't add this to the loop because we don't know which one is producing data, so we have to write both...
    
    uint8_t group = 0;
    for(group=0; group<2;group++)
    {
        uint32_t adcBufferLength = 0x10000000; // 256 MLWorte ; 1G Mbyte MByte (from sis3305_global.h:440)
        
        // FIX: The following computations are a bit redundant (but are not expensive)
        numberBytesToRead[group]    = ORSIS3305Card::readActualSampleAddress(group);
        numberOfWords[group]        = numberBytesToRead[group] * 16;        // 1 block == 64 bytes == 16 Lwords
        numberBytesToRead[group]    = numberOfWords[group] * 4;

        // we can only readout at max one full buffer at once
        if (numberOfWords[group] > adcBufferLength){
            numberOfWords[group] = adcBufferLength;
            // FIX: Does this mess something up? I guess if there is more data, it should get caught on the next poll? No, actually, next time through this loop, the readActualSampleAddress should be different...
        }
        
        if (numberBytesToRead[group] > 0){
            uint32_t addrOffset = 0;    // should cumulatively indicate the amount of data read out?
            uint32_t eventCount = 0;
            
            do {
                bool wrapMode = 0;//(wrapMaskForRun & (1L<<group))!=0; // FIX: Implement wrap mode

                size_t numLongsToRead = numberBytesToRead[group]/4;
                
                int32_t error = DMARead(
                                        (ORSIS3305Card::GetFIFOAddressOfGroup(group) + GetBaseAddress() ),       // FIFO read address
                                        (uint32_t)0x08, // Address Modifier, request MBLT
                                        (uint32_t)8,	// Read 64-bits at a time (redundant request)
                                        (uint8_t*)dmaBuffer,
                                        numberBytesToRead[group]);
                
                if (error != (int32_t) numberBytesToRead[group]) {
                				if(error > 0) LogError("DMA:SIS3305 0x%04x %d!=%d", GetBaseAddress(),error,numberBytesToRead);
                				return false;
                }
                
                // Put the data into the data stream
                
                // FIX: These loop variables MUST be wrong?
//                uint32_t startDataIndex = dataIndex;
                for (size_t i = 0; i < numLongsToRead; i += numLongsToRead) {
                				if(dmaBuffer[i+numLongsToRead-1] == 0xdeadbeef){
                                    ensureDataCanHold(numLongsToRead + 4);
                                    
                                    // data[] is a special block of memory given by the superclass?
                                    // dataIndex is the current position in the data, and is also from super
                                    
                                    // manually adding in the Orca header dataRecord[0,1,2] as the first 3 words
                                    data[dataIndex++] =  GetHardwareMask()[0] | (numLongsToRead+orcaHeaderLength); //  dataId | totalRecordLength[group];
                                    
                                    data[dataIndex++] =
                                        ((GetCrate()                                    & 0xf) << 28)   |
                                        ((GetSlot()                                     & 0x1f)<< 20)   |
                                        ((ORSIS3305Card::GetChannelMode(group)          & 0xF) << 16)   |
                                        ((group                                         & 0xF) << 12)   |
                                        ((ORSIS3305Card::GetDigitizationRate(group)     & 0xF) << 8)    |
                                        ((ORSIS3305Card::GetEventSavingMode(group)      & 0xF) << 4)    |
                                        (wrapMode                                       & 0x1);
                                    
                                    data[dataIndex++] = dataRecordLength[group];
                                    
                                    memcpy(data + dataIndex, &dmaBuffer[i], totalRecordLength[group]*sizeof(uint32_t));
                                    
                                    dataIndex += totalRecordLength[group];
                                }
                                else {
                                    break;
                                }
                }
                // end add to data stream
                
                // FIX: the following isn't needed for a auto-incremented FIFO?
                addrOffset += (dataRecordLength[group])*4;
                if(++eventCount > 25)break;
            } while (addrOffset < numberBytesToRead[group]);
            

        
        }
    
    } // end of loop over groups in readout
	
//		//if we wait too long, do a logic reset
//		fWaitCount++;
//		if(fWaitCount > 1000){
//			LogError("SIS3305 0x%x Rd delay reset:  0x%02x", GetBaseAddress(),fChannelsToReadMask);
//			
//			ensureDataCanHold(3);
//			data[dataIndex++] = GetHardwareMask()[1] | 3; 
//			data[dataIndex++] = ((GetCrate()     & 0x0000000f) << 21) | 
//								((GetSlot()      & 0x0000001f) << 16) | 1; //1 == reset event
//			data[dataIndex++] = fChannelsToReadMask<<16;
//			resetSampleLogic();
//		}

	
	return true;
}




bool ORSIS3305Card::armSampleLogic()
{
    
    uint32_t addr = kSIS3305KeyArmSampleLogic + GetBaseAddress();;
    uint32_t data_wr = 1;
    
    if (VMEWrite(addr, GetAddressModifier(), GetDataWidth(), data_wr) != sizeof(data_wr)) {
        LogBusError("Arm Sample Logic Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
        return false;
    }
    
    return true;
}

bool ORSIS3305Card::enableSampleLogic()
{
    
    uint32_t addr = kSIS3305KeyEnableSampleLogic + GetBaseAddress();;
    uint32_t data_wr = 1;
    
    if (VMEWrite(addr, GetAddressModifier(), GetDataWidth(), data_wr) != sizeof(data_wr)) {
        LogBusError("Enable Sample Logic Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
        return false;
    }
    
    return true;
}

bool ORSIS3305Card::disarmSampleLogic()
{
    
    uint32_t addr = kSIS3305KeyDisarmSampleLogic + GetBaseAddress();;
    uint32_t data_wr = 1;
    
    if (VMEWrite(addr, GetAddressModifier(), GetDataWidth(), data_wr) != sizeof(data_wr)) {
        LogBusError("Disarm/Disable Sample Logic Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
        return false;
    }
    
    return true;
}


uint32_t ORSIS3305Card::longsInSample(uint8_t group)
{
    switch (group) {
        case 0: return GetDeviceSpecificData()[0];
        case 1: return GetDeviceSpecificData()[1];
        default:
            LogBusError("Error reading device specific data (longs in sample): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return 0;
    }
}

uint32_t ORSIS3305Card::GetChannelMode(uint8_t group)
{
    switch(group) {
        case 0: return GetDeviceSpecificData()[2];
        case 1: return GetDeviceSpecificData()[3];
        default:
            LogBusError("Error reading device specific data (channel mode): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return 0;
    }
}

uint32_t ORSIS3305Card::GetDigitizationRate(uint8_t group)
{
    switch(group) {
        case 0: return GetDeviceSpecificData()[4];
        case 1: return GetDeviceSpecificData()[5];
        default:
            LogBusError("Error reading device specific data (digitization rate): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return 0;
    }
}

uint32_t ORSIS3305Card::GetEventSavingMode(uint8_t group)
{
    switch(group) {
        case 0: return GetDeviceSpecificData()[6];
        case 1: return GetDeviceSpecificData()[7];
        default:
            LogBusError("Error reading device specific data (event saving mode): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return 0;
    }
}

uint32_t ORSIS3305Card::GetFIFOAddressOfGroup(uint8_t group)
{
    
    switch(group){
        case 0: return kSIS3305Space1ADCDataFIFOCh14;
        case 1: return kSIS3305Space1ADCDataFIFOCh58;
    }
    
    LogBusError("FIFO Address Err (invalid group requested): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
    return (uint32_t)(-1);
}

bool ORSIS3305Card::writeDataTransferControlReg(uint8_t group, uint8_t command, uint32_t value)
{
    // this could be written less generally, since we're only going to write command = 2 and address/value = 0...
    // not sure how much this impacts speed, but it will get called for each poll that shows data is present.
 
    uint32_t addr;
    switch (group) {
        case 0:
            addr = kSIS3305DataTransferADC14CtrlReg + GetBaseAddress();
            break;
        case 1:
            addr = kSIS3305DataTransferADC58CtrlReg + GetBaseAddress();
            break;
        default:
            return false;
            break;
    }
    if (group >= 0 && group < 2) {
        uint32_t writeValue = command << 30;
        writeValue |= value;
        
        if( VMEWrite(addr, GetAddressModifier(), GetDataWidth(), writeValue)
            != sizeof(writeValue) )
        {
            LogBusError("Write Data Transfer Control Reg Err: SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return false;
        }
    }

    return true;
}

uint32_t ORSIS3305Card::readActualSampleAddress(uint8_t group)
{
    
    uint32_t addr;      // address to read from
    uint32_t value;     // returned value;
    
    switch (group) {
        case 0:
            addr = ORSIS3305Card::kSIS3305ActualSampleAddressADC14 + GetBaseAddress();
            break;
        case 1:
            addr = ORSIS3305Card::kSIS3305ActualSampleAddressADC58 + GetBaseAddress();
            break;
        default:
            addr = 0;
            LogBusError("Read Sample Address Err (bad group): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
            return 0;
            break;
    }
    
    int32_t error =  VMERead(addr,
                             GetAddressModifier(),
                             GetDataWidth(),    //sizeof(uint32_t),
                             (uint8_t*)&value,
                             sizeof(uint32_t));
    
    if (error != sizeof(int32_t))
    {
        LogBusError("Sample Address readout error (read failed): SIS3305 0x%04x %s", GetBaseAddress(),strerror(errno));
        return 0;
    }
    return (value & 0xFFFFFF); // sample memory address is only 23:0

    return 0;
}





