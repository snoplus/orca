#include "ORSIS3316Card.hh"
#include <errno.h>
#include <unistd.h>
#include <stdio.h>

#define kSIS3316AdcCh1PreviousBankSampleAddressReg   0x1120
#define kSIS3316AdcRegOffset                         0x1000
#define kSIS3316AcqControlStatusReg                  0x60       /* r/w; D32 */
#define kSIS3316DataTransferBaseReg                  0x80       /* r/w; D32 */
#define kSIS3316DisarmAndArmBank1                    0x420      /* write only; D32 */
#define kSIS3316DisarmAndArmBank2                    0x424      /* write only; D32 */
#define kSIS3316AdcMemOffset                         0x100000
#define kSIS3316AdcMemBase                           0x100000

ORSIS3316Card::ORSIS3316Card(SBC_card_info* ci) :
ORVVmeCard(ci)
{
}


bool ORSIS3316Card::Start()
{
    ArmBank2();
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


bool ORSIS3316Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{
    uint32_t dataId             = GetHardwareMask()[0];
    uint32_t locationMask       = ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x0000001f)<<16);
    uint32_t orcaHeaderLen      = 10;
    uint32_t dataHeaderLen      = 7;
    uint32_t rawDataLen         = GetDeviceSpecificData()[0];
    uint32_t longsInOneRecord   = rawDataLen/2 + dataHeaderLen;
    uint32_t maxPayloadLongs    = kSBC_MaxPayloadSizeBytes/4/4; //allow 1/4 of max
    uint32_t maxNumWaveforms    = (maxPayloadLongs/longsInOneRecord) - (10*longsInOneRecord);

    uint32_t acqRegValue        = 0;
    uint32_t baseAddress        = GetBaseAddress();
    uint32_t addMod             = GetAddressModifier();
    uint32_t addr               = baseAddress + kSIS3316AcqControlStatusReg;
    if(VMERead(addr,addMod,4,acqRegValue) != sizeof(uint32_t)){
        LogBusErrorForCard(GetSlot(),"acqReg Err: SIS3316 0x%04x %s", baseAddress,strerror(errno));
        return 1;
    }
    
    if((acqRegValue >> 19) & 0x1) { //checks the OR of the address threshold flags
        unsigned long bit[4] = {25,27,29,31};
        SwitchBanks();
        usleep(2); //let the banks settle. Could do a loop but this is less bus activity and faster we can take data
        for(int32_t ichan = 0;ichan<16;ichan++){
            int32_t iGroup = ichan/4;
             
            uint32_t prevBankEndingAddress  = 0;
            if((acqRegValue>>bit[iGroup] & 0x1)){
                uint32_t prevBankEndingRegAddr = baseAddress
                                               + kSIS3316AdcCh1PreviousBankSampleAddressReg
                                               + iGroup*kSIS3316AdcRegOffset
                                               + (ichan%4)*0x4;
                 if (VMERead(prevBankEndingRegAddr,addMod,4,prevBankEndingAddress) != sizeof(uint32_t)) {
                     LogBusErrorForCard(GetSlot(),"PrevBankEnd Err: SIS3316 0x%04x %s", baseAddress,strerror(errno));
                     return true;
                 }

                // Verify that the previous bank address is valid
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
                } while (((prevBankEndingAddress & 0x1000000) >> 24 )  != (previousBank-1)) ; // bank to read is not valid UNLES bit 24 is equal lastBank

                uint32_t expectedNumberOfWords = prevBankEndingAddress & 0x00FFFFFF;

                if(expectedNumberOfWords>0){
                    //first must transfer data from ADC FIFO to VME FIFO
                    uint32_t prevBankReadBeginAddress   = (prevBankEndingAddress & 0x03000000) + 0x10000000*((ichan/2)%2);
                    uint32_t offset                     = 0x80000000 + prevBankReadBeginAddress;
                    uint32_t addr                       = baseAddress + kSIS3316DataTransferBaseReg + iGroup*0x4;
                    if(VMEWrite(addr, addMod, 4, offset) != sizeof(uint32_t)){
                        LogBusErrorForCard(GetSlot(),"Data Transfer: SIS3316 0x%04x %s", baseAddress,strerror(errno));
                        return true;
                    }
                    
                    usleep(2); //up to 2 µs for transfer to take place
                    
                    expectedNumberOfWords = ((expectedNumberOfWords + 1) & 0xfffffE);
                    uint32_t numInBuffer  = expectedNumberOfWords/longsInOneRecord;
                    uint32_t numToRead    = numInBuffer<maxNumWaveforms ? numInBuffer:maxNumWaveforms;
                    
                    ensureDataCanHold(numToRead*longsInOneRecord + orcaHeaderLen);
                    
                    int32_t savedDataIndex  = dataIndex;
                    data[dataIndex++]       = dataId | (orcaHeaderLen + (numToRead*longsInOneRecord));
                    data[dataIndex++]       = locationMask  | ((ichan & 0x000000ff)<<8);
                    data[dataIndex++]       = numToRead;
                    data[dataIndex++]       = longsInOneRecord;
                    data[dataIndex++]       = numInBuffer;
                    data[dataIndex++]       = 0;
                    data[dataIndex++]       = 0;
                    data[dataIndex++]       = 0;
                    data[dataIndex++]       = 0;
                    data[dataIndex++]       = 0;
                    
                    uint32_t ret = DMARead(baseAddress + kSIS3316AdcMemBase +iGroup*kSIS3316AdcMemOffset,
                                           0xB, //address modifier
                                           0x8, //transfer size
                                           (uint8_t*)&data[dataIndex],
                                           numToRead*longsInOneRecord*sizeof(uint32_t));
                    
                    if(ret>0){
                        dataIndex += numToRead * longsInOneRecord;
                    }
                    else {
                        dataIndex = savedDataIndex;
                        break;
                    }
                    
                    ResetFSM(iGroup);
                 }
            }
        }
    }
	return true;
}

void ORSIS3316Card::ResetFSM(uint32_t iGroup)
{
    uint32_t addr     = GetBaseAddress() + kSIS3316DataTransferBaseReg + iGroup*0x4;
    uint32_t aValue = 0x0;
    if (VMEWrite(addr, GetAddressModifier(), 4, aValue) != sizeof(uint32_t)){
        LogBusErrorForCard(GetSlot(),"Data Transfer: SIS3316 0x%04x %s", GetBaseAddress(),strerror(errno));
    }
}

void ORSIS3316Card::ArmBank1()
{
    uint32_t addr = GetBaseAddress() + kSIS3316DisarmAndArmBank1;
    uint32_t aValue = 0x0;
    if (VMEWrite(addr, GetAddressModifier(), 4, aValue) != sizeof(uint32_t)){
        LogBusErrorForCard(GetSlot(),"Bank1 Err: SIS3316 0x%04x %s", GetBaseAddress(),strerror(errno));
    }
    currentBank  = 1;
    previousBank = 2;
}

void ORSIS3316Card::ArmBank2()
{
    uint32_t addr = GetBaseAddress() + kSIS3316DisarmAndArmBank2;
    uint32_t aValue = 0x0;
    if (VMEWrite(addr, GetAddressModifier(), 4, aValue) != sizeof(uint32_t)){
        LogBusErrorForCard(GetSlot(),"Bank2 Err: SIS3316 0x%04x %s", GetBaseAddress(),strerror(errno));
    }
    currentBank  = 2;
    previousBank = 1;
}

void ORSIS3316Card::SwitchBanks()
{
    if(currentBank==1)  ArmBank2();
    else                ArmBank1();
    
}


