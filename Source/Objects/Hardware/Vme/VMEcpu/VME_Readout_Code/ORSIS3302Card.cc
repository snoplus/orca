#include "ORSIS3302Card.hh"
#include <errno.h>

ORSIS3302Card::ORSIS3302Card(SBC_card_info* ci) :
	ORVVmeCard(ci), 
	fWaitForBankSwitch(false),
	fBankOneArmed(false),
	fWaitCount(0)

{
}

uint32_t ORSIS3302Card::GetPreviousBankSampleRegisterOffset(size_t channel) 
{
    switch (channel) {
        case 0: return 0x02000018;
        case 1: return 0x0200001c;
        case 2: return 0x02800018;
        case 3: return 0x0280001c;
        case 4: return 0x03000018;
        case 5: return 0x0300001c;
        case 6: return 0x03800018;
        case 7: return 0x0380001c;
    }
    return (uint32_t)-1;
}

uint32_t ORSIS3302Card::GetADCBufferRegisterOffset(size_t channel) 
{
    switch (channel) {
        case 0: return 0x04000000;
        case 1: return 0x04800000;
        case 2: return 0x05000000;
        case 3: return 0x05800000;
        case 4: return 0x06000000;
        case 5: return 0x06800000;
        case 6: return 0x07000000;
        case 7: return 0x07800000;
    }
    return (uint32_t)-1;
}

bool ORSIS3302Card::Start()
{
	DisarmAndArmBank(2);
	DisarmAndArmBank(1);
	fWaitForBankSwitch = false;
	return true;
}

bool ORSIS3302Card::Stop()
{
	return true;
}

bool ORSIS3302Card::IsEvent()
{
	uint32_t addr = GetBaseAddress() + GetAcquisitionControl(); 
    uint32_t data_rd = 0;
    if (VMERead(addr,GetAddressModifier(),4,data_rd) != sizeof(data_rd)) { 
		LogBusError("Bank Arm Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno)); 
    	return false;
    }
    if ((data_rd & 0x80000) != 0x80000) return false;
	else return true;
}

bool ORSIS3302Card::SetupPageReg()
{
	uint32_t data_wr;				
	if (fBankOneArmed)  data_wr = 0x4;	// Bank 1 is armed and bank two must be read 
	else				data_wr = 0x0;	// Bank 2 is armed and bank one must be read
	uint32_t addr = GetBaseAddress() + GetADCMemoryPageRegister() ;
	if (VMEWrite(addr,GetAddressModifier(), GetDataWidth(),data_wr) != sizeof(data_wr)){
		LogBusError("Page Reg Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno)); 
		return false;
	}
	else return true;
}

bool ORSIS3302Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{		
	uint32_t addr = GetBaseAddress() + GetAcquisitionControl(); 
	uint32_t data_rd = 0;
	if (VMERead(addr,GetAddressModifier(),4,data_rd) != sizeof(data_rd)) { 
		LogBusError("Bank Arm Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno)); 
		return false;
	}	
	if (fBankOneArmed) {
		if ((data_rd & 0x10000) != 0x10000) return false;
	} 
	else {
		if ((data_rd & 0x20000) != 0x20000) return false;
	}		
	if ((data_rd & 0x80000) != 0x80000)	return false;
	
	if (!fWaitForBankSwitch){
		if (!DisarmAndArmNextBank())return false;
		if (!SetupPageReg())		return false;
		fWaitCount = 0;
	}
	else {
		fWaitCount++;
		if(fWaitCount>1000){
			LogError("Switch Delay: SIS3302 0x%04x %d", GetBaseAddress(),fWaitCount); 
			fWaitCount = 0; 
		}
	}
	
	fWaitForBankSwitch = false;
	for( size_t i=0;i<GetNumberOfChannels();i++) {
		uint32_t addr = GetBaseAddress() + GetPreviousBankSampleRegisterOffset(i) ; 
		endSampleAddress[i] = 0;
		
		if (VMERead(addr,GetAddressModifier(),GetDataWidth(),(uint8_t*)&endSampleAddress[i],sizeof(uint32_t)) != sizeof(uint32_t)) { 
			LogBusError("Rd NextSpl Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno)); 
			return false;
		}
		if (((endSampleAddress[i] >> 24) & 0x1) ==  (fBankOneArmed ? 0:1)) { 
			//bit 24 is the bank bit. It must match the bank that we are reading out or chaos will result. 
			//The bit doesn't match so we set a flag and we will try again the next time thru the readout loop.
			fWaitForBankSwitch = true;
			return false;
		}

	}
	for( size_t i=0;i<GetNumberOfChannels();i++) {
		endSampleAddress[i] &= 0x7fffff; //limit to 8MB. 
		if (endSampleAddress[i] != 0) {
			ReadOutChannel(i);
		}
	}
	return true;
}

void ORSIS3302Card::ReadOutChannel(size_t channel) 
{	
	size_t group	= channel/2;
	
	uint32_t addr = GetBaseAddress() + GetADCBufferRegisterOffset(channel);
	uint32_t numberBytesToRead = endSampleAddress[channel] * 2;
	
	int32_t error = DMARead(addr, 
							(uint32_t)0x08, // Address Modifier, request MBLT 
							(uint32_t)8,	// Read 64-bits at a time (redundant request)
							(uint8_t*)dmaBuffer,  
							numberBytesToRead);
	
	if (error != (int32_t) numberBytesToRead) { 
		if(error > 0) LogBusError("DMA Err: SIS3302 0x%04x %s",     GetBaseAddress(),strerror(errno)); 
		else		  LogError   ("DMA Err: SIS3302 0x%04x %d!=%d", GetBaseAddress(),error,numberBytesToRead); 
	   return ;
	}
	
	// Put the data into the data stream
	size_t numberLongsInRawData	   = GetDeviceSpecificData()[group];
	size_t numberLongsInEnergyData = GetDeviceSpecificData()[4];
	size_t bufferWrapMask		   = GetDeviceSpecificData()[5];

	//the header size changes if the wrap mode is selected for a group
	size_t sisHeaderSize;						

	bool bufferWrap = (bufferWrapMask & (1L<<group))!=0;
	if(bufferWrap) sisHeaderSize = kHeaderSizeInLongsWrap;
	else		   sisHeaderSize = kHeaderSizeInLongsNoWrap;

	size_t sizeOfRecord	= sisHeaderSize		    + 
						  kTrailerSizeInLongs   + 
						  numberLongsInRawData  + 
						  numberLongsInEnergyData;
	size_t numLongsToRead = numberBytesToRead/4;
	for (size_t i = 0; i < numLongsToRead; i += sizeOfRecord) {
					
		ensureDataCanHold(sizeOfRecord + 4);
		
		data[dataIndex++] = GetHardwareMask()[0] | (sizeOfRecord+4); 
		data[dataIndex++] = ((GetCrate() & 0x0000000f)<<21) | 
							((GetSlot()  & 0x0000001f)<<16) | 
							((channel & 0x000000ff)<<8) |
							bufferWrap;
		data[dataIndex++] = numberLongsInRawData;
		data[dataIndex++] = numberLongsInEnergyData;
		
		memcpy(data + dataIndex, &dmaBuffer[i], sizeOfRecord*sizeof(uint32_t));
					
		dataIndex += sizeOfRecord;
		
	}
    return;
}

bool ORSIS3302Card::DisarmAndArmBank(size_t bank) 
{
    uint32_t addr;
	fBankOneArmed = (bank==1);
    if (bank==1) addr = GetBaseAddress() + 0x420;
    else		 addr = GetBaseAddress() + 0x424;
	
    if (VMEWrite(addr, GetAddressModifier(), GetDataWidth(), (uint32_t) 0x0) == sizeof(uint32_t)){
		return true;
	}
	else {
		LogBusError("Page Reg Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno)); 
		return false;
	}
}

bool ORSIS3302Card::DisarmAndArmNextBank()
{ 
	if(fBankOneArmed)	return DisarmAndArmBank(2);
	else				return DisarmAndArmBank(1);
}

