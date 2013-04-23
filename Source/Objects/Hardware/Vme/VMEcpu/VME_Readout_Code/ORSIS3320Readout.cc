#include "ORSIS3320Readout.hh"
#include <errno.h>
#include <unistd.h>

ORSIS3320Readout::ORSIS3320Readout(SBC_card_info* ci) :
ORVVmeCard(ci), 
fBankOneArmed(false)
{
}

uint32_t ORSIS3320Readout::GetNextBankSampleRegisterOffset(size_t channel)
{
    switch (channel) {
        case 0: return 0x02000010;
        case 1: return 0x02000014;
        case 2: return 0x02800010;
        case 3: return 0x02800014;
        case 4: return 0x03000010;
        case 5: return 0x03000014;
        case 6: return 0x03800010;
        case 7: return 0x03800014;
    }
    return (uint32_t)-1;
}

uint32_t ORSIS3320Readout::GetADCBufferRegisterOffset(size_t channel){
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

bool ORSIS3320Readout::Readout(SBC_LAM_Data* /*lam_data*/) 
{		
    uint32_t dataId   = GetHardwareMask()[0];
    uint32_t status   = 0x0;
    uint32_t location = ((GetCrate()&0x0000000f)<<21) | ((GetSlot()& 0x0000001f)<<16);

    if (VMERead(GetBaseAddress() + kAcquisitionControlReg,
                GetAddressModifier(),
                sizeof(status),
                status) != sizeof(uint32_t)) {
		LogBusError("Rd Status Err: SIS3320 0x%04x %s", GetBaseAddress() + kAcquisitionControlReg,strerror(errno));
	}
    else if((status & kEndAddressThresholdFlag) == kEndAddressThresholdFlag){
        //if we get here, there may be something to read out
        for (size_t i=0;i<kNumberOfChannels;i++) {
            uint32_t endSampleAddress = 0;
            
            if (VMERead(GetBaseAddress() + GetNextBankSampleRegisterOffset(i),
                        GetAddressModifier(),
                        sizeof(endSampleAddress),
                        endSampleAddress) != sizeof(uint32_t)) {
                LogBusError("Rd End Add Err: SIS3320 0x%04x %s", GetBaseAddress() + GetNextBankSampleRegisterOffset(i),strerror(errno));
            }

            endSampleAddress &= 0xffffff;
            
            if (endSampleAddress != 0) {
                uint32_t bufferSize = GetDeviceSpecificData()[i/2]; //longs
                ensureDataCanHold(bufferSize+2);
                
                uint32_t savedDataStart = dataIndex;
                
                data[dataIndex++] = dataId | (bufferSize+2);
                data[dataIndex++] = location;
                
                if(VMERead(GetBaseAddress() +
                           GetADCBufferRegisterOffset(i),
                           GetAddressModifier(),
                           (uint32_t) 4,
                           (uint8_t*)&(data[dataIndex]),
                           bufferSize*4) == (int32_t)bufferSize*4) {
                    dataIndex+=bufferSize;
               }
                else {
                    //something wrong.. dump the data
                    dataIndex = savedDataStart;
                    LogBusError("Rd Buffer Err: SIS3320 0x%04x %s", GetBaseAddress() +
                                GetADCBufferRegisterOffset(i),strerror(errno));

                }
            }
        }
        if(fBankOneArmed)  armBank2();
        else               armBank1();
    }
    return true;
}

void ORSIS3320Readout::armBank1()
{
    uint32_t addr = GetBaseAddress() + kDisarmAndArmBank1;
    uint32_t data_wr = 1;
    if (VMEWrite(addr, GetAddressModifier(),sizeof(data_wr),data_wr) != sizeof(data_wr)){
		LogBusError("Arm 1 Err: SIS3320 0x%04x %s", addr,strerror(errno));
	}
    
    fBankOneArmed = true;
	
}

void ORSIS3320Readout::armBank2()
{
    uint32_t addr = GetBaseAddress() + kDisarmAndArmBank2;
    uint32_t data_wr = 1;
    if (VMEWrite(addr, GetAddressModifier(),sizeof(data_wr),data_wr) != sizeof(data_wr)){
		LogBusError("Arm 2 Err: SIS3320 0x%04x %s", addr,strerror(errno));
	}
    fBankOneArmed = false;
}

