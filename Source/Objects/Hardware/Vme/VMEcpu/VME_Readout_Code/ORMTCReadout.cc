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
uint32_t ORMTCReadout::last_mem_write_ptr = k_fifo_valid_mask;
uint32_t ORMTCReadout::mem_write_ptr = k_fifo_valid_mask;
uint32_t ORMTCReadout::simm_empty_space = k_fifo_valid_mask + 1;

bool ORMTCReadout::Start() {

    ResetTheMemory(); //takes care of last_good_gtid and simm_empty_space

	const uint32_t mem_read_reg = GetDeviceSpecificData()[0]; // 0x2CUL;
	uint32_t value = 0;
    
	if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
                sizeof(value), value) < (int32_t) sizeof(value)){
		LogBusError("BusError: mem_access at: 0x%08x", mem_read_reg);
		return true;
	}
    
	value &= k_fifo_valid_mask;
	last_mem_read_ptr = value;
	mem_read_ptr = value;

	const uint32_t mem_write_reg = 0x28UL;
	value = 0;
    
	if (VMERead(GetBaseAddress() + mem_write_reg, GetAddressModifier(),
                sizeof(value), value) < (int32_t) sizeof(value)){
		LogBusError("BusError: mem_access at: 0x%08x", mem_write_reg);
		return true;
	}
    
	value &= k_fifo_valid_mask;
	last_mem_write_ptr = value;
	mem_write_ptr = value;

	last_good_10mhz_upper = 0;
	//last_good_gtid = 0; //see ResetTheMemory()
    //simm_empty_space = 0x100000; //ditto
    
    struct timezone tz;
    gettimeofday(&timestamp, &tz);
    
	return true;
}

bool ORMTCReadout::Stop() {
/*
    unsigned int sweep;
    for (sweep=0; sweep<100; sweep++) {
        usleep(10); // let the last MTC bundle propagate through MTCD
        Readout(0);
    }
*/
	return true;
}

bool ORMTCReadout::UpdateStatus() {
    
    ensureDataCanHold(7);
    int32_t savedIndex = dataIndex;
    data[dataIndex++] = GetHardwareMask()[1] | 7;
    dataIndex++;
    
    uint32_t aValue;
    
    //GTID
	if (VMERead(GetBaseAddress() + 0x80UL, GetAddressModifier(),
                sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: GT mem_access at: 0x%08x", 0x80);
        dataIndex = savedIndex;
		return false;
	}
    data[dataIndex++] = aValue;
    
    //10Mhz low
	if (VMERead(GetBaseAddress() + 0x8CUL, GetAddressModifier(),
                sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: 10MHz mem_access at: 0x%08x", 0x8C);
        dataIndex = savedIndex;
		return false;
	}
    data[dataIndex++] = aValue;
    
    //10Mhz high
	if (VMERead(GetBaseAddress() + 0x90UL, GetAddressModifier(),
                sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: mem_access at: 0x%08x", 0x90);
        dataIndex = savedIndex;
		return false;
	}
    data[dataIndex++] = aValue;
    
    //read pointer
	if (VMERead(GetBaseAddress() + 0x2CUL, GetAddressModifier(),
                sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError: bba mem_access at: 0x%08x", 0x2C);
        dataIndex = savedIndex;
		return false;
	}
    data[dataIndex++] = aValue;
    
    //write pointer
    if (VMERead(GetBaseAddress() + 0x28UL, GetAddressModifier(),
                sizeof(aValue), aValue) < (int32_t) sizeof(aValue)){
		LogBusError("BusError:next bba mem_access at: 0x%08x", 0x2C);
        dataIndex = savedIndex;
		return false;
	}
    data[dataIndex++] = aValue;

    return true;
}

bool ORMTCReadout::ResetTheMemory()
{
    uint32_t csr = 0;
    if (VMERead(GetBaseAddress(), GetAddressModifier(),
            sizeof(csr), csr) < (int32_t) sizeof(csr)){
        LogBusError("BusError: csr mem_access at: 0x%08x", 0x0);
		return false;
	}

    mem_read_ptr = 0;
	last_mem_read_ptr = 0;

    //reset mem_read_ptr
    if (VMEWrite(GetBaseAddress() + 0x2CUL, GetAddressModifier(), 
                 sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
        LogBusError("BusError: rd ptr inc to 0x%08x\n", mem_read_ptr);
        return false; 
    }        
 
    csr |= 0x00010000; //fifo reset bit
    if (VMEWrite(GetBaseAddress(), GetAddressModifier(), 
                 sizeof(csr), csr) < (int32_t) sizeof(csr)){
        LogBusError("BusError: csr access at 0x%08x\n", csr);
        return false; 
    }        
 
    csr &= ~0x00010000;
    if (VMEWrite(GetBaseAddress(), GetAddressModifier(), 
                 sizeof(csr), csr) < (int32_t) sizeof(csr)){
        LogBusError("BusError: csr access at 0x%08x\n", csr);
        return false; 
    }        

    mem_write_ptr = 0;
    last_mem_write_ptr = 0;
    simm_empty_space = 0x100000;

    //update GTID
    uint32_t gtid_value = 0;
    if (VMERead(GetBaseAddress() + 0x80UL, GetAddressModifier(),
                sizeof(gtid_value), gtid_value) < (int32_t) sizeof(gtid_value)){
        LogBusError("BusError GTID mem_access at: 0x%08x", 0x80);
        return true;
    }
    gtid_value &= 0xffffff;

    if (gtid_value > 0) {
        last_good_gtid = gtid_value - 1;
    }
    else {
        last_good_gtid = 0xffffff;
    }

    return true;
}

bool ORMTCReadout::Readout(SBC_LAM_Data* /*lamData*/)
{
    const uint32_t mem_read_reg = GetDeviceSpecificData()[0]; // 0x2CUL;
    const uint32_t mem_write_reg = GetDeviceSpecificData()[1]; // 0x28UL;
    const uint32_t mem_base_address = GetDeviceSpecificData()[2]; // 0x03800000UL;
    const uint32_t mem_address_modifier = GetDeviceSpecificData()[3]; // 0x09UL;
    const uint32_t max_allowed_gtid_jump = 0x1000U;    

    uint32_t value = 0;
    bool triggered = false;
    
    const uint32_t poll_delay = GetDeviceSpecificData()[4]; //msec
    
    struct timeval tv;
    struct timezone tz;
    gettimeofday(&tv, &tz);
    
    double time_diff = 1000 * ((tv.tv_sec - timestamp.tv_sec) + (tv.tv_usec - timestamp.tv_usec)/1.e6);
    if (time_diff > poll_delay) {
        timestamp.tv_sec = tv.tv_sec;
        timestamp.tv_usec = tv.tv_usec;

        if (!UpdateStatus()) {
            reset_the_memory = true;
            return false;
        }
    }

    if (reset_the_memory) {
        if (ResetTheMemory()) {
            reset_the_memory = false;
        }
        else {
            return false;
        }
    }

    //get the write ptr
    if (VMERead(GetBaseAddress() + mem_write_reg, GetAddressModifier(),
                sizeof(mem_write_ptr), mem_write_ptr) < (int32_t) sizeof(mem_write_ptr)) {
        LogBusError("BusError: mem_write at: 0x%08x\n", mem_write_reg);
        return true;
    }
    mem_write_ptr &= k_fifo_valid_mask;

    triggered = false;
    if (mem_write_ptr > mem_read_ptr) {
        triggered = true;
    }
    else if (mem_write_ptr < last_mem_write_ptr) { // rollover or jump back
        if (last_mem_write_ptr - mem_write_ptr < 0x1000) { //jump
            LogError("MTCD write ptr jumped from 0x%05x to 0x%05x gtid 0x%06x",
                    last_mem_write_ptr, mem_write_ptr, last_good_gtid); 
            reset_the_memory = true;
            return true;
        }
        triggered = true;
    }
    else if (mem_write_ptr != mem_read_ptr) { // rollover
        triggered = true;
    }
    else { //buffer full?
        //check GTID
        uint32_t gtid_value = 0;
        if (VMERead(GetBaseAddress() + 0x80UL, GetAddressModifier(),
                    sizeof(gtid_value), gtid_value) < (int32_t) sizeof(gtid_value)){
            LogBusError("BusError GTID mem_access at: 0x%08x", 0x80);
            return true;
        }
        gtid_value &= 0xffffff;

        if ((gtid_value > last_good_gtid && gtid_value - last_good_gtid > 0xfffff) ||
                (gtid_value < last_good_gtid && gtid_value + 0x1000000 - last_good_gtid > 0xfffff)) {
            triggered = true;
        }
    }

    if (!triggered) {
        return true;
    }

    int32_t eventsStored = 0;
    eventsStored = mem_write_ptr - mem_read_ptr;
    if (eventsStored < 0) {
        eventsStored += 0x100000;
    }
    //check the rate
    if (eventsStored > 32) {
        eventsStored = 32;
    }

    if (mem_write_ptr >= last_mem_write_ptr) {
        simm_empty_space -= mem_write_ptr - last_mem_write_ptr;
    }
    else {
        simm_empty_space -= mem_write_ptr + 0x100000 - last_mem_write_ptr;
    }
    
    last_mem_write_ptr = mem_write_ptr;

/* 
    //get the read ptr and check the trigger, step 1: data available
    if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
                sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
	    LogBusError("BusError: mem_access at: 0x%08x", mem_read_reg);
	    return true;
    }
    triggered = ((mem_read_ptr & k_no_data_available) == 0);
    mem_read_ptr &= k_fifo_valid_mask;
    
    if (!triggered) return true;
*/
   
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
 
    do {
        ensureDataCanHold(7);
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = GetHardwareMask()[0] | 7;
       
        bool isBusError = false;
        for (int i = 0; i < 6; i++) {
            if (VMERead(mem_base_address, mem_address_modifier,
                        sizeof(value), value) < (int32_t) sizeof(value)){
                LogBusError("BusError: reading mtc word %d at 0x%08x", i, mem_read_ptr);
                isBusError = true;
                break;
            }
            data[dataIndex++] = value;
        }
        
        //make sure MTCD received 6 reads even if not acknowledged
        //recover from a bus error
        //both replaced by the memory reset
        if (isBusError) {
            dataIndex = savedIndex;
            reset_the_memory = true;
        }
        
        if (!isBusError) {
            last_good_10mhz_upper = data[dataIndex-5] & 0xfffff;

            uint32_t current_gtid;
            current_gtid = data[dataIndex-3] & 0xffffff;
            if (current_gtid > last_good_gtid) {
                if (current_gtid - last_good_gtid > max_allowed_gtid_jump) {
                    reset_the_memory = true;
                    LogError("MTCD GTID jumped forward from 0x%06x to 0x%06x",
                            last_good_gtid, current_gtid);
                    last_good_gtid = current_gtid;
                    return true;
                }
            }
            else if (current_gtid == last_good_gtid) {
                    reset_the_memory = true;
                    LogError("MTCD stuck GTID 0x%06x", current_gtid);
                    return true;
            }
            else { //rollover?
                if (current_gtid + 0x1000000 - last_good_gtid > max_allowed_gtid_jump) {
                    reset_the_memory = true;
                    LogError("MTCD GTID jumped back from 0x%06x to 0x%06x",
                            last_good_gtid, current_gtid);
                    return true;
                }
            }

            last_good_gtid = current_gtid;
        }
        
        //our 6 tries to pull this bundle are over
        //go for the next one even if we don't have the data
        mem_read_ptr++;
        if (mem_read_ptr > k_fifo_valid_mask) mem_read_ptr = 0UL;
        last_mem_read_ptr = mem_read_ptr;
        
        if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
                     sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
            LogBusError("BusError: rd ptr inc to 0x%08x", mem_read_ptr);
            reset_the_memory = true;
            return true; 
        }        
        
        if (isBusError) {
            return true;
        }
        
        eventsStored--;
        simm_empty_space++;
    } while(eventsStored > 0);
    
    /*
     gettimeofday(&tv2, &tz);
     std::cout << "readout took: " << std::dec << tv2.tv_usec - tv1.tv_usec << std::endl;
     std::cout << "gtid: " << std::hex << data[dataIndex-3] << std::endl;
     */
 
    return true; 
}
