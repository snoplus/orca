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
float ORMTCReadout::trigger_rate = 0;
uint32_t ORMTCReadout::last_good_gtid = 0;
bool ORMTCReadout::is_next_stop_hard = false;

bool ORMTCReadout::Start() {

    const bool resetFifoOnStart = GetDeviceSpecificData()[5];
    if (resetFifoOnStart) {
        ResetTheMemory(); //takes care of last_good_gtid and simm_empty_space

        //set correct trigger mask
        uint32_t trigger_mask = GetDeviceSpecificData()[6];
        if (VMEWrite(GetBaseAddress() + 0x34UL, GetAddressModifier(), 
                     sizeof(trigger_mask), trigger_mask) < (int32_t) sizeof(trigger_mask)){
            LogBusError("BusError: set trigger_mask to 0x%08x\n", trigger_mask);
            return false; 
        }        
    }

	last_good_10mhz_upper = 0;
    is_next_stop_hard = false;
    //it's set from MTCModel::runIsStopping -> SNO.c::tellMtcReadout
    
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
    trigger_rate = 0;

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
        last_good_gtid = 0x0;
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

    uint32_t check_mem_write_ptr = 0;
    if (VMERead(GetBaseAddress() + mem_write_reg, GetAddressModifier(),
                sizeof(check_mem_write_ptr), check_mem_write_ptr) < (int32_t) sizeof(check_mem_write_ptr)) {
        LogBusError("BusError: mem_write at: 0x%08x\n", mem_write_reg);
        return true;
    }
    check_mem_write_ptr &= k_fifo_valid_mask;

    //the check is to avoid a bad read of the write ptr, jump forward here only
    //bad read resulting in jump back, and real jumps are handled below
    if ((check_mem_write_ptr > 15 && check_mem_write_ptr < mem_write_ptr) ||
            (check_mem_write_ptr > mem_write_ptr + 15) ||
            (check_mem_write_ptr < 15 && mem_write_ptr > 15 && mem_write_ptr < 0xffff1)) {

        LogMessage("MTCD bad write ptr reads: 0x%05x, 0x%05x",
                mem_write_ptr, check_mem_write_ptr);
        return true;
    }

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
    uint32_t number_new_events = 0;
    if (mem_write_ptr >= last_mem_write_ptr) {
        number_new_events = mem_write_ptr - last_mem_write_ptr;
    }
    else {
        number_new_events = mem_write_ptr + 0x100000 - last_mem_write_ptr;
    }
   
    simm_empty_space -= number_new_events;
    trigger_rate = 0.9 * trigger_rate + 0.1 * number_new_events;
    last_mem_write_ptr = mem_write_ptr;

    if (simm_empty_space < 10000) {
        reset_the_memory = true;
        LogMessage("MTCD SIMM out of empty space, reset");
        return true;
    }

    //trigger rate too high, skip some events
    int32_t event_flood_bar = trigger_rate * 256 * 2 + 4096;
    if ((trigger_rate > 32 && eventsStored > 190000) || eventsStored > event_flood_bar) {
        //set read pointer ahead
        uint32_t jump_ahead = trigger_rate - 31;
        if (eventsStored > event_flood_bar) {
            jump_ahead += 1 / 2048. * (eventsStored - event_flood_bar) + 1;
        }
        mem_read_ptr += jump_ahead;
        if (mem_read_ptr > k_fifo_valid_mask) {
            mem_read_ptr -= 0x100000;
        }
        last_mem_read_ptr = mem_read_ptr;
        
        if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
                     sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
            LogBusError("BusError: rd ptr inc to 0x%08x", mem_read_ptr);
            reset_the_memory = true;
            return true; 
        }
    } 

    //check the rate
    if (eventsStored > 32) {
        eventsStored = 32;
    }

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
            else { //rollover? 0xfefffe -> 0x0
                if (current_gtid + 0xff0000 - last_good_gtid > max_allowed_gtid_jump) {
                    //false zero bit? misplaced bit?
                    uint32_t expected_gtid = last_good_gtid + 1;
                    if (expected_gtid > 0xfefffe) {
                        expected_gtid = 0;
                    }
                    expected_gtid = current_gtid ^ expected_gtid;
                    uint32_t num_bits;
                    for (num_bits = 0; expected_gtid; num_bits++) {
                        expected_gtid &= expected_gtid - 1;
                    }
                    if (num_bits < 3) {
                        //throw away the event, don't reset
                        dataIndex = savedIndex;
                        LogMessage("MTCD GTID bit err from 0x%06x to 0x%06x",
                                last_good_gtid, current_gtid);
                        current_gtid = last_good_gtid;
                    }
                    else {
                        reset_the_memory = true;
                        LogError("MTCD GTID jumped back from 0x%06x to 0x%06x",
                                last_good_gtid, current_gtid);
                        return true;
                    }
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

void ORMTCReadout::setIsNextStopHard(bool aStop)
{
    is_next_stop_hard = aStop;
}
