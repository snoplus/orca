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
	
	//TODO: multiple FIFOs are obsolete, remove it -tb-
	static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10 
	static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAEOffsetReg   = 0xe00008 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAFOffsetReg   = 0xe0000c >> 2;//obsolete 2012-10
	static const uint32_t BB0csrReg         = 0xe00010 >> 2;//obsolete 2012-10



bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{

         
    uint32_t i;
    
    //init
    uint32_t eventFifoId = GetHardwareMask()[2];
    uint32_t energyId = GetHardwareMask()[3];
    //uint32_t secondsSetSendToFLTs = GetDeviceSpecificData()[0];
    uint32_t runFlags   = GetDeviceSpecificData()[3];//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    uint32_t sltRevision = GetDeviceSpecificData()[6];

    uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 24 (slots go from 0-9, 11-20)
    uint32_t crate      = GetCrate();
	uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ; 

    //SLT read out
    //  
    //extern Pbus *pbus;              //for register access with fdhwlib
    //pbus = srack->theSlt->version;
    //uint32_t sltversion=sltRevision;
    
    
    if(runFlags & kFirstTimeFlag){// firstTime
        //fprintf(stdout, "KatrinSLTv4Readout called ... fast event readout using SLT buffer ... tbtb\n");
        GetDeviceSpecificData()[3]=GetDeviceSpecificData()[3] & ~(kFirstTimeFlag);// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
        GetDeviceSpecificData()[3]=0;//TODO: for testing -tb-

        //TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
        //debug: fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
        //debug: //sleep(1);
    }
    
    if(sltRevision==0x3010003){//we have SLT event FIFO since this revision -> read FIFO (one event = 4 words)
        //DEBUG   fprintf(stdout, "sltRevision>=0x3010003\n");
        //block FIFO readout
        //has FIFO data?
        uint32_t fifomode=pbus->read(FIFO0ModeReg);
        uint32_t fifoavail=fifomode & 0x3fffff;
        uint32_t fifoReadoutBuffer32Len=fifoavail;
        if(fifoReadoutBuffer32Len>8192) fifoReadoutBuffer32Len=8192;
        //testing if(fifoReadoutBuffer32Len>800) fifoReadoutBuffer32Len=800;
        if(fifoReadoutBuffer32Len % 4) fifoReadoutBuffer32Len = (fifoReadoutBuffer32Len>>2)<<2;//always read multiple of 4 word32s
        if(fifoReadoutBuffer32Len>0){
            uint32_t recordLength = fifoReadoutBuffer32Len+4;
            ensureDataCanHold(recordLength);
            data[dataIndex++] = eventFifoId | recordLength;
            data[dataIndex++] = location  ;
            data[dataIndex++] = fifomode; //spare
            data[dataIndex++] = 0; //spare

            if(fifoReadoutBuffer32Len<48){  //if there are more than 48 words, use blockread; blockread should read multiple of 8 words
                for(i=0;i<fifoReadoutBuffer32Len; i++){
                    data[dataIndex++]=pbus->read(FIFO0Addr);
                }
            }
            else {                          //there are more than 48 words -> use DMA
                fifoReadoutBuffer32Len = (fifoReadoutBuffer32Len>>3)<<3;//always read multiple of 8 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long *)(&data[dataIndex]), fifoReadoutBuffer32Len);//read 2048 word32s
                dataIndex += fifoReadoutBuffer32Len;
            }
         }
    }
    
    else if(sltRevision>=0x3010004){//we have SLT event FIFO since last revision -> read FIFO (one event = 6 words)
        //uint32_t numToSkip=0;
        //uint32_t numMisaligned=0;
        //block FIFO readout
        //has FIFO data?
        uint32_t fifomode                = pbus->read(FIFO0ModeReg);
        uint32_t fifoavail               = fifomode & 0x3fffff;
        uint32_t fifoReadoutBuffer32Len  = fifoavail;
        
        if(fifoReadoutBuffer32Len > 8160) fifoReadoutBuffer32Len = 8160;//8160 is 170*48, smallest multiple of 48 smaller than 8192 (8192=max.readout block)
 
        fifoReadoutBuffer32Len = (fifoReadoutBuffer32Len/6)*6;//division for integers will round down -tb-
        if(fifoReadoutBuffer32Len > 0){
            
            //uint32_t savedDataIndex = dataIndex; //in case we need to dump this data packet
            
            uint32_t recordLength = fifoReadoutBuffer32Len + 4;
            ensureDataCanHold(recordLength);
            data[dataIndex++] = energyId | recordLength;
            data[dataIndex++] = location  ;
            data[dataIndex++] = fifomode; //spare //TODO: for debugging - remove it? -tb-
            data[dataIndex++] = 0; //spare
            
            //read out the data....
            if(fifoReadoutBuffer32Len < 48){  //if there are more than 48 words, use blockread; blockread should read multiple of 8 words
                for(i=0;i<fifoReadoutBuffer32Len; i++){
                    data[dataIndex++] = pbus->read(FIFO0Addr);
                }
            }
            else { //more than 48 words -> use DMA
                fifoReadoutBuffer32Len  = (fifoReadoutBuffer32Len/48)*48;//always read multiple of 48 word32s
                /*uint32_t retval = */pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), fifoReadoutBuffer32Len);//read up to 4*2048 word32s
                dataIndex += fifoReadoutBuffer32Len;
            }
            
            //have to do some error check here...
            //if(error){
            // dataIndex = savedDataIndex;
            //}
//            
//            numToSkip=0;
//            //correct data record alignment (check bits 29-31)
//            uint32_t f,pattern=0x1;
//            for(i=0;i<6; i++){
//                f = fifoReadoutBuffer32[i];
//                if((f >> 29) == 0x1){
//                    if(i) printf("ORSLTv4Readout.cc - error; found  alignment error at index %i: 0x%08x (%i)   pattern is %i should be %i\n",i, fifoReadoutBuffer32[i],fifoReadoutBuffer32[i],(f >> 29),pattern);
//                }
//                pattern ++;
//                if(pattern==0x7) pattern=0x1;
//            }
//            numToSkip=i%6;
//            
//            if(numToSkip>0 /*&& numToSkip<6*/){
//                printf("ORSLTv4Readout.cc - error; found  alignment error: numToSkip   %i:  (fifoReadoutBuffer32Len %i) (read instead %i)\n",numToSkip, fifoReadoutBuffer32Len,fifoReadoutBuffer32Len-6);
//                fifoReadoutBuffer32Len-=6;//drop one event
//            }
         }
    }

    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
    return true; 
}


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

// 'simulation' of hitrate is done in HW_Readout.cc in doReadBlock -tb-

bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    //"counter" for debugging/simulation
    static int currentSec=0;
    static int currentUSec=0;
    static int lastSec=0;
    static int lastUSec=0;
    //static long int counter=0;
    static long int secCounter=0;
    
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    //timing
    gettimeofday(&t,NULL);
    currentSec = t.tv_sec;  
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) + ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (SLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        //remember for next call
        lastSec      = currentSec; 
        lastUSec     = currentUSec; 
    }
    else {
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
    
	//loop over FLTs
    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
 
    return true; 
}




#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------



