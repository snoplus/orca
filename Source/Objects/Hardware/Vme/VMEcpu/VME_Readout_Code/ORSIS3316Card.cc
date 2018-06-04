#include "ORSIS3316Card.hh"
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
ORSIS3316Card::ORSIS3316Card(SBC_card_info* ci) :
ORVVmeCard(ci)
{
}


bool ORSIS3316Card::Start()
{
    prevRunningBank=2;
    DisarmAndArmBank();
    //bank one is armed are taking data
	return true;
}

bool ORSIS3316Card::Stop()
{
	return true;
}

bool ORSIS3316Card::Resume()
{
	return true;
}

#define kSIS3316AdcCh1PreviousBankSampleAddressReg   0x1120
#define kSIS3316AdcRegOffset                         0x1000
#define kSIS3316DataTransferBaseReg                  0x80       /* r/w; D32 */
#define kSIS3316DisarmAndArmBank1                    0x420      /* write only; D32 */
#define kSIS3316DisarmAndArmBank2                    0x424      /* write only; D32 */
#define kSIS3316AdcMemOffset                         0x100000
#define kSIS3316AdcMemBase                           0x100000

bool ORSIS3316Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{
    uint32_t dataId              = GetHardwareMask()[0];
    uint32_t locationMask        = ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x0000001f)<<16);
    uint32_t orcaHeaderLen       = 10;
    uint32_t dataHeaderLen       = 7;
    uint32_t rawDataLen          = GetDeviceSpecificData()[0];
    uint32_t numLongsToRead     = rawDataLen/2 + dataHeaderLen;

    int32_t return_code  = 0;
    uint32_t addr        = 0;
    uint32_t acqRegValue = 0;
    uint32_t baseAddress = GetBaseAddress();
    uint32_t addMod      = GetAddressModifier();
    if(VMERead(baseAddress+ 0x60,addMod,4,acqRegValue) != sizeof(uint32_t)){
        LogBusErrorForCard(GetSlot(),"acqReg Err: SIS3316 0x%04x %s", baseAddress,strerror(errno));
        return 1;
    }
    unsigned long bit[4] = {25,27,29,31};
    //bit 19 means at least one channel got data
    if((acqRegValue >> 19) & 0x1){
        DisarmAndArmBank();
         for(int32_t ichan = 0;ichan<16;ichan++){
             int32_t iGroup = ichan/4;
             
             if((acqRegValue>>bit[iGroup] & 0x1)){
                     ; //put chan # in the crate/card location
             
                    uint32_t prevBankEndingRegAddr = baseAddress
                                                   + kSIS3316AdcCh1PreviousBankSampleAddressReg
                                                   + iGroup*kSIS3316AdcRegOffset
                                                   + (ichan%4)*0x4;
             
                    // Verify that the previous bank address is valid
                    uint32_t prevBankEndingAddress  = 0;
                    uint32_t max_poll_counter       = 1000;
                    do {
                        if (VMERead(prevBankEndingRegAddr,addMod,4,prevBankEndingAddress) != sizeof(uint32_t)) {
                            LogBusErrorForCard(GetSlot(),"PrevBankEnd Err: SIS3316 0x%04x %s", baseAddress,strerror(errno));
                            return true;
                        }
                        max_poll_counter--;
                        if (max_poll_counter == 0) {
                            LogBusErrorForCard(GetSlot(),"Poll Err: SIS3316 0x%04x %s", baseAddress,strerror(errno));
                            return true;
                        }
                    } while (((prevBankEndingAddress & 0x1000000) >> 24 )  != (prevRunningBank-1)) ; // bank to read is not valid UNLES bit 24 is equal lastBank

             
                    uint32_t prevBankReadBeginAddress   = (prevBankEndingAddress & 0x03000000) + 0x10000000*((ichan/2)%2);
                    uint32_t expectedNumberOfWords      = prevBankEndingAddress & 0x00FFFFFF;
                    expectedNumberOfWords               = ((expectedNumberOfWords + 1) & 0xfffffE);
                 
                    if(expectedNumberOfWords){
                        
                        //first must transfer data from ADC FIFO to VME FIFO
                        uint32_t offsetData = 0x80000000 + prevBankReadBeginAddress;
                        addr = baseAddress + kSIS3316DataTransferBaseReg + iGroup*0x4;
                        if(VMEWrite(addr, addMod, 4, offsetData) != sizeof(uint32_t)){
                            LogBusErrorForCard(GetSlot(),"Data Transfer: SIS3316 0x%04x %s", baseAddress,strerror(errno));
                            return return_code;
                        }
                        usleep(2); //up to 2 µs for transfer to take place
                        
                        uint32_t numInBuffer = expectedNumberOfWords/numLongsToRead;
                        addr = baseAddress + kSIS3316AdcMemBase +iGroup*kSIS3316AdcMemOffset;
                        for(uint32_t n = 0; n<numInBuffer; n++){
                            ensureDataCanHold(numLongsToRead + orcaHeaderLen);
                            int32_t savedDataIndex = dataIndex;
                            data[dataIndex++] = dataId | (orcaHeaderLen+rawDataLen);
                            data[dataIndex++] = locationMask  | ((ichan & 0x000000ff)<<8);
                            data[dataIndex++] = numInBuffer;
                            data[dataIndex++] = n;
                            data[dataIndex++] = 0;
                            data[dataIndex++] = 0;
                            data[dataIndex++] = 0;
                            data[dataIndex++] = 0;
                            data[dataIndex++] = 0;
                            data[dataIndex++] = 0;
                            uint32_t ret = DMARead(addr,
                                            0xB, //address modifier
                                            0x8, //transfer size
                                            (uint8_t*)&data[dataIndex],
                                            numLongsToRead*sizeof(uint32_t));
                            if(ret>0){
                                dataIndex += numLongsToRead;
                            }
                            else {
                                dataIndex = savedDataIndex;
                                break;
                            }
                        }
                    }
             }
        }
    }
    
	return true;
}

void ORSIS3316Card::DisarmAndArmBank()
{
    if(prevRunningBank==2){
        uint32_t addr = GetBaseAddress() + kSIS3316DisarmAndArmBank2;
        if (VMEWrite(addr, GetAddressModifier(), 4, (uint32_t) 0x0) != sizeof(uint32_t)){
            LogBusErrorForCard(GetSlot(),"BankSwitch Err: SIS3316 0x%04x %s", GetBaseAddress(),strerror(errno));
        }
        currentBank = 2;
        prevRunningBank=1;
    }
    else{
        uint32_t addr = GetBaseAddress() + kSIS3316DisarmAndArmBank1;
        if (VMEWrite(addr, GetAddressModifier(), 4, (uint32_t) 0x0) != sizeof(uint32_t)){
            LogBusErrorForCard(GetSlot(),"BankSwitch Err: SIS3316 0x%04x %s", GetBaseAddress(),strerror(errno));
        }
        currentBank = 1;
        prevRunningBank=2;
    }
}
