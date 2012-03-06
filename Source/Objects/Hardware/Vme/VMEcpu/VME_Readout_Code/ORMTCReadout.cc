#include "ORMTCReadout.hh"
#include "readout_code.h" 
#include <errno.h>
#include <iostream>
#include <unistd.h>

using namespace std;

uint32_t ORMTCReadout::last_mem_read_ptr = k_fifo_valid_mask;
uint32_t ORMTCReadout::mem_read_ptr = k_fifo_valid_mask;


bool ORMTCReadout::Start() {
	//should we reset the fifo? what about subruns?

	const uint32_t mem_read_reg = GetDeviceSpecificData()[0]; // 0x2CUL;
	uint32_t value = 0;

	if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
		    sizeof(value), value) < (int32_t) sizeof(value)){
		LogBusError("BusError: mem_access at: 0x%08x", mem_read_reg); //limited to 64 * 0.75 chars
		return true; 
	}
	
	value &= k_fifo_valid_mask;
	last_mem_read_ptr = value;
	mem_read_ptr = value;
			
	return true;
}

bool ORMTCReadout::Stop() {
    unsigned int sweep;
    for (sweep=0; sweep<100; sweep++) {
        usleep(10); // let the last MTC bundle propagate through MTCD
        Readout(0);
    }
	return true;
}

bool ORMTCReadout::Readout(SBC_LAM_Data* /*lamData*/)
{
	//the fecs are independent of the mtc trigger now
	//data are pushed to orca, so the idea with leaf_indices doesn't work

	const uint32_t mem_read_reg = GetDeviceSpecificData()[0]; // 0x2CUL;
	const uint32_t mem_write_reg = GetDeviceSpecificData()[1]; // 0x28UL;
	const uint32_t mem_base_address = GetDeviceSpecificData()[2]; // 0x03800000UL;
	const uint32_t mem_address_modifier = GetDeviceSpecificData()[3]; // 0x09UL;
	uint32_t mem_write_ptr;
	
	uint32_t value = 0;
	bool triggered = 0;
        
	//get the read ptr and check the trigger, step 1: data available
	if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
			sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
		LogBusError("BusError: mem_access at: 0x%08x", mem_read_reg);
		return true; 
	}
		
	triggered = ((mem_read_ptr & k_no_data_available) == 0);
	mem_read_ptr &= k_fifo_valid_mask;
	
	//check the trigger, step 2: write_ptr > last_read_ptr mod rollover
	if (triggered) {
		if (VMERead(GetBaseAddress() + mem_write_reg, GetAddressModifier(),
				sizeof(mem_write_ptr), mem_write_ptr) < (int32_t) sizeof(mem_write_ptr)) {
			LogBusError("BusError: mem_write at: 0x%08x\n", mem_write_reg);
			return true; 
		}
		mem_write_ptr &= k_fifo_valid_mask;
		//smarter check, taking into account gtid and clocks
		triggered = (last_mem_read_ptr != mem_write_ptr); 
	}

	//check consistency
	if (triggered) {
		triggered = (last_mem_read_ptr == mem_read_ptr);
		
		if (!triggered) {
			//can we recover?
			LogError("MTC readout broken, reseting\n");
			value = 0UL;
			if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
					sizeof(value), value) < (int32_t) sizeof(value)){
				LogBusError("BusError: reset read ptr\n");
				return true; 
			}        
			
			//todo: replace reset of the write pointer with full fifo reset
			if (VMEWrite(GetBaseAddress() + mem_write_reg, GetAddressModifier(), 
					sizeof(value), value) < (int32_t) sizeof(value)){
				LogBusError("BusError: reset write ptr\n");
				return true; 
			}        
			
			//todo: maybe...
			last_mem_read_ptr = 0UL;
			mem_read_ptr = 0UL;
			LogMessage("MTC readout reset done.\n");
			
			return true;
		}
	}
	
	if (triggered) {
		ensureDataCanHold(7);
		int32_t savedIndex = dataIndex;
		data[dataIndex++] = GetHardwareMask()[0] | 7;
		
		for (int i = 0; i < 6; i++) {
			if (VMERead(mem_base_address, mem_address_modifier, 
					 sizeof(value), value) < (int32_t) sizeof(value)){
				LogBusError("BusError: reading mtc word %d\n", i);
				dataIndex = savedIndex;
				// can we recover?
				// we have to 1. reset the controller, and 2. make sure we start from scratch
				// todo: reset fifo here and set bba to zero
				return true; 
			}
			
			data[dataIndex++] = value;
		}

		mem_read_ptr++;
		if (mem_read_ptr > k_fifo_valid_mask) mem_read_ptr = 0UL;
		if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
			     sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
			LogBusError("BusError: rd ptr inc to 0x%08x\n", mem_read_ptr);
			return true; 
		}        
		
		last_mem_read_ptr = mem_read_ptr;
	}
	
/*	
    if(triggered){
        //we have a trigger so read out the FECs for event
        leaf_index = GetNextTriggerIndex()[0];
        while(leaf_index >= 0) {
            leaf_index = readout_card(leaf_index,lamData);
        }
    }
*/
	
    return true; 
}
