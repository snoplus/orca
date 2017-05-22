#include "ORSLTv4Readout.hh"
#include "SLTv4_HW_Definitions.h"
#include "readout_code.h"


#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORSLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
    #include <sys/time.h> // for gettimeofday on MAC OSX -tb-
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------
extern hw4::SubrackKatrin* srack; 
extern Pbus* pbus; 

static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10
static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10

bool ORSLTv4Readout::Start() {
    firstTime = true;
    return true;
}   

bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t i;
    
    //init
    uint32_t eventFifoId = GetHardwareMask()[2];
    uint32_t energyId    = GetHardwareMask()[3];
    //uint32_t runFlags    = GetDeviceSpecificData()[3];
    uint32_t sltRevision = GetDeviceSpecificData()[6];

    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
	uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ; 
    
    //SLT read out
    //  
    //extern Pbus *pbus;              //for register access with fdhwlib
    //pbus = srack->theSlt->version;
    //uint32_t sltversion=sltRevision;
    
    if(firstTime){
        //not sure what Till had in mind for the firstTime flag... it wasn't used in his code
        //I kept it for now, but moved it to a private variable
        firstTime = false;
    }
    
    if(sltRevision==0x3010003){//we have SLT event FIFO since this revision -> read FIFO (one event = 4 words)
        uint32_t headerLen  = 4;
        uint32_t numWordsToRead = pbus->read(FIFO0ModeReg) & 0x3fffff;
        if(numWordsToRead>8192) numWordsToRead=8192;
        if(numWordsToRead % 4)  numWordsToRead = (numWordsToRead>>2)<<2;//always read multiple of 4 word32s
        if(numWordsToRead>0){
            uint32_t firstIndex   = dataIndex; //so we can insert the length
            ensureDataCanHold(numWordsToRead+headerLen);
            
            data[dataIndex++] = eventFifoId | 0;//fill in the length below
            data[dataIndex++] = location  ;
            data[dataIndex++] = 0; //spare
            data[dataIndex++] = 0; //spare

            //there are more than 48 words -> use DMA
            if(numWordsToRead<48) {
                for(i=0;i<numWordsToRead; i++){
                    data[dataIndex++]=pbus->read(FIFO0Addr);
                }
            }
            else {
                numWordsToRead = (numWordsToRead>>3)<<3;//always read multiple of 8 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long *)(&data[dataIndex]), numWordsToRead);//read 2048 word32s
                dataIndex += numWordsToRead;
            }
            data[firstIndex] |=  (numWordsToRead+headerLen); //fill in the record length

         }
    }
    
    else if(sltRevision>=0x3010004){
        uint32_t headerLen  = 4;
        uint32_t numWordsToRead  = pbus->read(FIFO0ModeReg) & 0x3fffff;
        if(numWordsToRead > 0){

            if(numWordsToRead > 8160) numWordsToRead = 8160;    //8160 is 170*48, smallest multiple of 48 smaller than 8192 (8192=max.readout block)
            numWordsToRead = (numWordsToRead/6)*6;              //make sure we are on event boundary
        
            uint32_t firstIndex = dataIndex; //so we can insert the length
            
            ensureDataCanHold(numWordsToRead + headerLen);
            data[dataIndex++] = energyId | 0; //fill in the length below
            data[dataIndex++] = location  ;
            data[dataIndex++] = 0; //spare
            data[dataIndex++] = 0; //spare
            
            //if more than 8 Events (48 words) -> use DMA
            if(numWordsToRead < 48) {
                for(i=0;i<numWordsToRead; i++){
                    data[dataIndex++] = pbus->read(FIFO0Addr);
                }
            }
            else {
                numWordsToRead  = (numWordsToRead/48)*48;//always read multiple of 48 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), numWordsToRead);
                dataIndex += numWordsToRead;
            }
            data[firstIndex] |=  (numWordsToRead+headerLen); //fill in the record length
         }
    }

    //read out the children flts that are in the readout list
    int32_t leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
    return true; 
}


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------
bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    static int currentSec   = 0;
    static int currentUSec  = 0;
    static int lastSec      = 0;
    static int lastUSec     = 0;
    //static long int counter =0; //for debugging
    static long int secCounter=0;
    
    struct timeval t;
    gettimeofday(&t,NULL);
    currentSec  = t.tv_sec;
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) + ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (SLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        lastSec      = currentSec;
        lastUSec     = currentUSec; 
    }
    else {
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
    
    //read out the children flts that are in the readout list
    int32_t leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    return true; 
}

#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------



