#include "ORMTCReadout.hh"
#include "readout_code.h" 
#include <errno.h>
#include <iostream>
#include <unistd.h>
#include <time.h>

#include <stdlib.h>
#include <sys/time.h>

using namespace std;

uint32_t ORMTCReadout::last_mem_read_ptr = k_fifo_valid_mask;
uint32_t ORMTCReadout::mem_read_ptr = k_fifo_valid_mask;


bool ORMTCReadout::Start() {
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

    struct timezone tz;
    gettimeofday(&timestamp, &tz);
			
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

bool ORMTCReadout::UpdateStatus() {

    ensureDataCanHold(6);
    int32_t savedIndex = dataIndex;
    data[dataIndex++] = GetHardwareMask()[1] | 7;
    dataIndex++;

    uint32_t aValue;

    //GT
	if (VMERead(GetBaseAddress() + 0x80UL, GetAddressModifier(),
			sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: GT mem_access at: 0x%08x", 0x80);
        dataIndex = savedIndex;
		return true; 
	}
    data[dataIndex++] = aValue;

    //10Mhz low
	if (VMERead(GetBaseAddress() + 0x8CUL, GetAddressModifier(),
			sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: 10MHz mem_access at: 0x%08x", 0x8C);
        dataIndex = savedIndex;
		return true; 
	}
    data[dataIndex++] = aValue;

    //10Mhz high
	if (VMERead(GetBaseAddress() + 0x90UL, GetAddressModifier(),
			sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: mem_access at: 0x%08x", 0x90);
        dataIndex = savedIndex;
		return true; 
	}
    data[dataIndex++] = aValue;

    //read pointer
	if (VMERead(GetBaseAddress() + 0x2CUL, GetAddressModifier(),
			sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: bba mem_access at: 0x%08x", 0x2C);
        dataIndex = savedIndex;
		return true; 
	}
    data[dataIndex++] = aValue;

    //write pointer
    if (VMERead(GetBaseAddress() + 0x28UL, GetAddressModifier(),
			sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError:next bba mem_access at: 0x%08x", 0x2C);
        dataIndex = savedIndex;
		return true; 
	}
    data[dataIndex++] = aValue;

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

    const uint32_t poll_delay = GetDeviceSpecificData()[4]; //msec

    struct timeval tv;
    struct timezone tz;
    gettimeofday(&tv, &tz);

    double time_diff = 1000 * ((tv.tv_sec - timestamp.tv_sec) + (tv.tv_usec - timestamp.tv_usec)/1.e6);
    if (time_diff > poll_delay) {
        timestamp.tv_sec = tv.tv_sec;
        timestamp.tv_usec = tv.tv_usec;

        UpdateStatus();
    }

	//get the read ptr and check the trigger, step 1: data available
	if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
			sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
		LogBusError("BusError: mem_access at: 0x%08x", mem_read_reg);
		return true; 
	}

	triggered = ((mem_read_ptr & k_no_data_available) == 0);
	mem_read_ptr &= k_fifo_valid_mask;

    if (!triggered) return true;

	//check the trigger, step 2: write_ptr > last_read_ptr mod rollover

    if (VMERead(GetBaseAddress() + mem_write_reg, GetAddressModifier(),
            sizeof(mem_write_ptr), mem_write_ptr) < (int32_t) sizeof(mem_write_ptr)) {
        LogBusError("BusError: mem_write at: 0x%08x\n", mem_write_reg);
        return true; 
    }
    mem_write_ptr &= k_fifo_valid_mask;

	//check consistency
    triggered = (last_mem_read_ptr == mem_read_ptr);
    
    if (!triggered) {
        //trust MTCD, restart us
        if (!Start()) {
            LogError("MTCD readout: failed to restart");
        }
             
        return true;

        /*
        //this is a backup plan reset code
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
        */
    }

    /*
     * the idea here is to guarantee MTCD doesn't get behind the CAEN digitizer
     * the lame implementation is to grab a couple events before we switch
     * before you change the 32 events per switch make sure you measure all the times
     * make sure that the time to pull data traces from CAEN is less than the time
     * MTCD needs to get the next event ready
     */
    /*
    struct timeval tv1, tv2;
    struct timezone tz;
    gettimeofday(&tv1, &tz);
    */

    int32_t eventsStored = mem_write_ptr;
    if (mem_write_ptr < mem_read_ptr) {
        eventsStored += 0xfffff;
    }
    eventsStored -= mem_read_ptr;
    if (eventsStored > 32) eventsStored = 32;

    do {
        ensureDataCanHold(7);
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = GetHardwareMask()[0] | 7;

        for (int i = 0; i < 6; i++) {
            if (VMERead(mem_base_address, mem_address_modifier, 
                     sizeof(value), value) < (int32_t) sizeof(value)){
                LogBusError("BusError: reading mtc word %d\n", i);
                dataIndex = savedIndex;
                /* can we recover?
                 * we need to keep reading the fifo until we find the 0th word again
                 * for now just skip this one.
                 */
                
                mem_read_ptr++;
                if (mem_read_ptr > k_fifo_valid_mask) mem_read_ptr = 0UL;
                if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
                         sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
                    LogBusError("BusError: rd ptr inc to 0x%08x\n", mem_read_ptr);
                    return true; 
                }        
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

        eventsStored--;
        last_mem_read_ptr = mem_read_ptr;
    } while(eventsStored);


    /*
    gettimeofday(&tv2, &tz);
    std::cout << "readout took: " << std::dec << tv2.tv_usec - tv1.tv_usec << std::endl;
    std::cout << "gtid: " << std::hex << data[dataIndex-3] << std::endl;
    */

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
