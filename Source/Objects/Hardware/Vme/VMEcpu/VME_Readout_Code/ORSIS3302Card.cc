#include "ORSIS3302Card.hh"

ORSIS3302Card::ORSIS3302Card(SBC_card_info* ci) :
  ORVVmeCard(ci), fBankOneArmed(false)
{
  // Start module here?
  
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

bool ORSIS3302Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{
    uint32_t addr = GetBaseAddress() + GetAcquisitionControl(); 
    uint32_t data_rd = 0;
    if (VMERead(addr,GetAddressModifier(),4,data_rd) != sizeof(data_rd)) { 
    	return false;
    }
    if ((data_rd & 0x80000) != 0x80000) return false; // No threshold yet

    // Try disarm current bank and arm the next one
    if (! DisarmAndArmNextBank() ) return false;
    // Otherwise, let's readout
    uint32_t data_wr = 0x0; // Bank 2 is armed and bank one must be read
    if (fBankOneArmed) data_wr = 0x4; // vice versa, must read bank two 

    addr = GetBaseAddress() + GetADCMemoryPageRegister() ;
    if (VMEWrite(addr,GetAddressModifier(),
                 GetDataWidth(),data_wr ) != sizeof(data_wr)) {
        return false;
    }

    // We've selected a particular page to readout for each channel
    for( size_t i=0;i<GetNumberOfChannels();i++) {
        if (!ReadOutChannel(i) ) return false;
    }
    return true;
}

bool ORSIS3302Card::ReadOutChannel(size_t channel) 
{
	// Function to readout a particular channel.
	// This will dump one channel into a data record, should
	// this be changed?
    // read stop sample address
    uint32_t addr = GetBaseAddress() 
           + GetPreviousBankSampleRegisterOffset(channel) ; 
    uint32_t end_sample_address = 0;

    if (VMERead(addr,GetAddressModifier(),
                GetDataWidth(),end_sample_address) != sizeof(end_sample_address)) { 
    	return false;
    }

    // check if bank address flag is valid
    if (((end_sample_address >> 24) & 0x1) != 
        ((fBankOneArmed) ? 0x1 : 0x0) ) {   //  
    	// in this case -> poll right arm flag or implement a delay
    }

    // check buffer address
    end_sample_address &= 0xffffff ; // mask bank2 address bit (bit 24)

    if (end_sample_address > 0x3fffff) {   // more than 1 page memory buffer is used
        // Warning?
    }

    // readout	   	
    if (end_sample_address != 0) {
    	addr = GetBaseAddress() 
               + GetADCBufferRegisterOffset(channel);
        // Do DMA Read
        uint32_t num_bytes_to_read = (end_sample_address & 0x3ffffc);
		uint32_t num_longs_to_read = num_bytes_to_read >> 2;
		ensureDataCanHold(num_longs_to_read + 2);
		size_t savedIndex = dataIndex;
		data[dataIndex++] = GetHardwareMask()[0] | (num_longs_to_read+2); 
        data[dataIndex++] = ((GetCrate() & 0x0000000f)<<21) | 
							((GetSlot()  & 0x0000001f)<<16);
		uint8_t* buffer = (uint8_t*) &data[dataIndex];
    	int32_t error = DMARead(addr, 
				(uint32_t)0x08, // Address Modifier, request MBLT 
                (uint32_t)8, // Read 64-bits at a time
				buffer,  
                num_bytes_to_read);
		
    	if (error != num_bytes_to_read) { // vme error
			// Reset the data
			dataIndex = savedIndex;
            return false;
    	}
		dataIndex += num_longs_to_read;
    } 
    return true;
}

bool ORSIS3302Card::DisarmAndArmBank(size_t bank) 
{
    uint32_t addr = GetBaseAddress() + ((bank == 1) ? 0x420 : 0x424);
    if (bank==1) fBankOneArmed = true;
    else fBankOneArmed = false;
    return (VMEWrite(addr, GetAddressModifier(), 
                     GetDataWidth(), (uint32_t) 0x0) != sizeof(uint32_t));
}
