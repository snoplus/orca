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
    
	last_good_10mhz_upper = 0;
	last_good_gtid = 0;
    
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
            LogError("MTCD readout: logic restart failed");
        }
        else {
            LogMessage("MTCD readout: logic restarted");
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
    
    int32_t eventsStored;
    eventsStored = mem_write_ptr - mem_read_ptr;
    if (eventsStored < 0) {
        eventsStored += 0x100000;
    }
    if (eventsStored > 32) {
        eventsStored = 32;
    }
    
    if (eventsStored == 0) { //either buffer full or dataAvailable error
        //check GTID
        if (VMERead(GetBaseAddress() + 0x80UL, GetAddressModifier(),
                    sizeof(value), value) < (int32_t) sizeof(value)){
            LogBusError("BusError: GT mem_access at: 0x%08x", 0x80);
            return true;
        }
        if ((value & 0xffffff) == last_good_gtid) {
            LogMessage("dataAvailable error caught");
            return true;
        }
        eventsStored = 32;
    }
    
    /*
     if (mem_write_ptr < 0x400 || mem_read_ptr > 0xfff00) {
     cout << "::read ptr: " << hex << mem_read_ptr << endl;
     cout << "::wrte ptr: " << hex << mem_write_ptr << endl;
     cout << "::events stored " << hex << eventsStored << endl;
     }
     */
    
    do {
        ensureDataCanHold(7);
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = GetHardwareMask()[0] | 7;
        
        //there is a tricky region when WRITE pointer rolls over
        //the land mine is at ANY READ address when
        //write pointer == num bundles left in phys fifo at the moment of roll over
        //it's somewhere between 0x0 and 0x400
        //it took us some time to get here after reading the write pointer, too
        if (mem_write_ptr > 0xffff00 || mem_write_ptr < 0x402) {
            usleep(10);
        }
        
        //always read full bundle of 6 words to reset MTCD counter
        //if bus error throw it away
        //jumping to the next bundle is very BAD idea
        //you are guaranteed to go offsync (as SNO has)
        bool isBusError = false;
        for (int i = 0; i < 6; i++) {
            if (VMERead(mem_base_address, mem_address_modifier,
                        sizeof(value), value) < (int32_t) sizeof(value)){
                LogBusError("BusError: reading mtc word %d at 0x%08x", i, mem_read_ptr);
                isBusError = true;
            }
            data[dataIndex++] = value;
        }
        
        //make sure MTCD received 6 reads even if not acknowledged
        if (isBusError) {
            dataIndex = savedIndex;
            
            //check we are in sync
            if (last_good_10mhz_upper == ((uint32_t)data[dataIndex-5] & 0xfffff) ||
                last_good_gtid + 1 == ((uint32_t)data[dataIndex-3] & 0xffffff)) {
                
                LogMessage("MTCD bus error: data in sync");
                usleep(10);
            }
            else {
                //sync the readout logic, make sure MTCD received 6 reads
                //assumption 1: MTCD received the read cycle but failed to complete
                //we are in sync, just don't have data, do nothing
                //assumption 2. MTCD hasn't seen the read cycle at all
                //we'll look into later words
                unsigned int slip_count = 0;
                for (slip_count = 1; slip_count < 3; slip_count++) {
                    if (last_good_gtid + 1 == ((uint32_t)data[dataIndex - slip_count] & 0xffffff)) {
                        break;
                    }
                }
                if (slip_count < 3) {
                    //check clock matches
                    if (last_good_10mhz_upper == (data[dataIndex - 5 + 3 - slip_count] & 0xfffff)) {
                        //good slip_count
                        do {
                            if (VMERead(mem_base_address, mem_address_modifier,
                                        sizeof(value), value) < (int32_t) sizeof(value)) {
                                //we've failed again
                                //this is really bad
                            }
                            slip_count--;
                        } while (slip_count);
                    }
                }
                else {
                    //use clock and last word error bits to recover
                    //todo...
                    //assumption 3. fifo didn't set us correctly and we are ahead
                    //look into former words, sync, and skip next bundle
                }
            }
        }
        
        if (!isBusError) {
            last_good_10mhz_upper = data[dataIndex-5] & 0xfffff;
            last_good_gtid = data[dataIndex-3] & 0xffffff;
        }
        
        //our 6 tries to pull this bundle are over
        //go for the next one even if we don't have the data
        mem_read_ptr++;
        if (mem_read_ptr > k_fifo_valid_mask) mem_read_ptr = 0UL;
        last_mem_read_ptr = mem_read_ptr;
        
        if (VMEWrite(GetBaseAddress() + mem_read_reg, GetAddressModifier(), 
                     sizeof(mem_read_ptr), mem_read_ptr) < (int32_t) sizeof(mem_read_ptr)){
            LogBusError("BusError: rd ptr inc to 0x%08x\n", mem_read_ptr);
            return true; 
        }        
        
        if (isBusError) {
            return true;
        }
        
        eventsStored--;
    } while(eventsStored > 0);
    
    
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
