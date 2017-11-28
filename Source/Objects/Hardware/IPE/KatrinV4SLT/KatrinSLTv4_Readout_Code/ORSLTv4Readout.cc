#include "ORSLTv4Readout.hh"
#include "KatrinV4_HW_Definitions.h"
#include "readout_code.h"

#include <fcntl.h>
#include <unistd.h>


#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORSLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
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

ORSLTv4Readout::ORSLTv4Readout(SBC_card_info* ci) : ORVCard(ci)
{
    const char*  sMode[] = { "Standard mode - data transport via SBC protocol to Orca",
        "Local readout mode - local storage of events at the crate PC",
        "Simulation mode - shipping simulation records via SBC protocol to Orca"};
    
    //
    // Warning:
    //
    // Don't have here other than kStandard selected, when checking code in to the repositories
    // Do change this flag only for test purpose at the crate PC and start OrcaReadout manually
    // by ./orcaReadout 44667
    //
    
    mode = kStandard;
    //mode = kLocal;
    //mode = lSimulation;
    
    // Start message
    printf("ORSLTv4Readout: %s\n", sMode[mode%3]);
    
    // Initiolize analysis variables
    maxLoopsPerSec = 0;
    
}

bool ORSLTv4Readout::Start()
{
    struct timezone tz;
    
    switch (mode){
        case kStandard:
            break;
        case kLocal:
            LocalReadoutInit();
            break;
        case kSimulation:
            SimulationInit();
            break;
    }
    
    // Start readout performance measurement
    nWords = 0;
    nLoops = 0;
    nReadout = 0;
    nReducedSize = 0;
    nNoReadout = 0;
    
    gettimeofday(&t0, &tz);
    printf("%ld.%06ld: Start readout loop\n", t0.tv_sec, t0.tv_usec);
    
    // Prepare the header
    uint32_t energyId   = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    header[0] = energyId | 8164; // id + length
    header[1] = location;
    header[2] = 0; //spare
    header[3] = 0; //spare
    
    //printf("Header: %08x %08x %08x %08x\n", header[0], header[1], header[2], header[3]);
    
    
    // Select the readoutfunction depending on the mode
    uint32_t sltRevision = GetDeviceSpecificData()[6];
    if(sltRevision>=0x3010004){
        
        switch (mode){
            case kStandard:
                readoutCall = &ORSLTv4Readout::ReadoutEnergyV31;
                break;
            case kLocal:
                readoutCall = &ORSLTv4Readout::LocalReadoutEnergyV31;
                break;
            case kSimulation:
                readoutCall = &ORSLTv4Readout::SimulationReadoutEnergyV31;
                break;
        }
        
    } else {
    
        readoutCall = &ORSLTv4Readout::ReadoutLegacyCode;
    }
    
    return true;
}


bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    nLoops = nLoops + 1;

    (*this.*readoutCall)(lamData);

    if ((mode == kStandard) && (nNoReadout > 1)){
        // Read out the children flts that are in the readout list
        // Leave out for the high rate tests
        int32_t leaf_index = GetNextTriggerIndex()[0];
        while(leaf_index >= 0) {
            leaf_index = readout_card(leaf_index,lamData);
        }
    }
    
    return true; 
}

bool ORSLTv4Readout::Stop()
{
    float runTime;
    float loopsPerSec;
    unsigned long long int tDeadTicks;
    float tNoReadout;
    uint32_t meanBlockSize;
    float load;
    //float tReadout;
    
    struct timezone tz;
    unsigned long long int t0Ticks, t1Ticks;
    float rate;
    
    switch (mode){
        case kStandard:
            break;
        case kLocal:
            LocalReadoutClose();
            break;
        case kSimulation:
            break;
    }

    // Measure readout time
    gettimeofday(&t1, &tz);
    t0Ticks = (long long int) t0.tv_sec * 1000000 + t0.tv_usec;
    t1Ticks = (long long int) t1.tv_sec * 1000000 + t1.tv_usec;
    runTime = (float) (t1Ticks - t0Ticks) / 1000000;
    rate = (float) nWords * 4 / (t1Ticks - t0Ticks); // MB/s

    
    
    printf("%ld.%06ld: Stop readout loop, recording %.3f sec, data %.1f MB rate %.1f MB/s\n",
        t1.tv_sec, t1.tv_usec, runTime,
        (float) nWords * 4 / 1024 / 1024, rate);
    
    // Readout loops
    
    // For performance testing always run the first run without signal, to measure the loop time
    loopsPerSec = (float) nLoops / runTime;
    if ((unsigned ) loopsPerSec > maxLoopsPerSec) maxLoopsPerSec = (unsigned) loopsPerSec;
    
    printf("%17s: loops %lld, readout %lld, red size %lld loop time %.3f us (max loops %lld)\n", "",
           nLoops, nReadout, nReducedSize,
           (float) (t1Ticks - t0Ticks) / nLoops,  maxLoopsPerSec);
    
    // Estimation of readout time
    tDeadTicks = ((1000000 - t0.tv_usec) + t1.tv_usec );
    tNoReadout = 0;
    if (maxLoopsPerSec >0) tNoReadout = (float) (nLoops - nReadout) / maxLoopsPerSec ;
    
    load = 0;
    if (nReadout > 0) {
        meanBlockSize =  nWords / nReadout;
        load = 100 * nWords / nReadout / 8160;
    }
    
    printf("%17s: dead time %0.3f us no readout %.3f s, mean block size %d, load %f %s\n", "",
           (float) tDeadTicks / 1000000, tNoReadout, meanBlockSize, load, "%");
    
    return true;
}


bool ORSLTv4Readout::ReadoutEnergyV31(SBC_LAM_Data* lamData)
{
    uint32_t headerLen  = 4;
    uint32_t numWordsToRead  = pbus->read(FIFO0ModeReg) & 0x3fffff;
    
    if (numWordsToRead >= 8160){ // full block readout
        nNoReadout = 0; // Clear no readout
        nReadout = nReadout + 1;
        
        numWordsToRead = 8160;
        ensureDataCanHold(numWordsToRead + headerLen);

        memcpy(&data[dataIndex], header, headerLen * sizeof(uint32_t));
        dataIndex += headerLen;
        
        pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), numWordsToRead);
        dataIndex += numWordsToRead;
        
        nWords = nWords + numWordsToRead+headerLen;

    } else if ((numWordsToRead > 0) && (nNoReadout > 10)) { // partial readout
        nNoReadout = 0; // Clear no readout
        nReadout = nReadout + 1;
        nReducedSize = nReducedSize + 1;
        
        uint32_t firstIndex = dataIndex; //so we can insert the length
        ensureDataCanHold(numWordsToRead + headerLen);
        
        memcpy(&data[dataIndex], header, headerLen * sizeof(uint32_t));
        dataIndex += headerLen;
        
        if (numWordsToRead < 48) {
            numWordsToRead = (numWordsToRead/6)*6; //make sure we are on event boundary
            for(uint32_t i=0;i<numWordsToRead; i++){
                data[dataIndex++] = pbus->read(FIFO0Addr);
            }
        }
        else {
            numWordsToRead  = (numWordsToRead/48)*48;//always read multiple of 48 word32s
            pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), numWordsToRead);
            dataIndex += numWordsToRead;
        }
    
        data[firstIndex] = (header[0] & 0xffff0000) | (numWordsToRead+headerLen); //fill in the record length
        
        
        nWords = nWords + numWordsToRead+headerLen;
        
    } else { // no readout
        nNoReadout = nNoReadout + 1;
    }
    
   
    return true;
}

bool ORSLTv4Readout::LocalReadoutEnergyV31(SBC_LAM_Data* lamData)
{
    // Write the Orca data blocks to file; do not transmit anything to Orca

    uint32_t i;
    uint32_t bufferIndex = 0;
    
    uint32_t energyId   = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    
    uint32_t headerLen  = 4;
    uint32_t numWordsToRead  = pbus->read(FIFO0ModeReg) & 0x3fffff;
    if(numWordsToRead > 0){
        
        if(numWordsToRead > 8160) numWordsToRead = 8160;    //8160 is 170*48, smallest multiple of 48 smaller than 8192 (8192=max.readout block)
        numWordsToRead = (numWordsToRead/6)*6;              //make sure we are on event boundary
        
        uint32_t firstIndex = bufferIndex; //so we can insert the length
        
        dataBuffer[bufferIndex++] = energyId | 0; //fill in the length below
        dataBuffer[bufferIndex++] = location  ;
        dataBuffer[bufferIndex++] = 0; //spare
        dataBuffer[bufferIndex++] = 0; //spare
        
        //if more than 8 Events (48 words) -> use DMA
        if(numWordsToRead < 48) {
            for(i=0;i<numWordsToRead; i++){
                dataBuffer[bufferIndex++] = pbus->read(FIFO0Addr);
            }
        }
        else {
            numWordsToRead  = (numWordsToRead/48)*48;//always read multiple of 48 word32s
            pbus->readBlock(FIFO0Addr, (unsigned long*)(&dataBuffer[bufferIndex]), numWordsToRead);
            bufferIndex += numWordsToRead;
        }
        dataBuffer[firstIndex] |=  (numWordsToRead+headerLen); //fill in the record length
    }
    
    
    // Write block to local file
    // Merge late with the Orca readout file
    
    // Install SSD first !!!
    //write(filePtr, dataBuffer, (numWordsToRead+headerLen) * sizeof(uint32_t));
    nWords = nWords + numWordsToRead+headerLen;
    
    return true;
    
}

void ORSLTv4Readout::LocalReadoutInit()
{
    // Read the file name from inifile
    // Get the run number from Orca
    
    // Open the readout file
    filePtr = open("/home/katrin/data/Run000.part", O_WRONLY | O_CREAT, 0777);
    
    
}

void ORSLTv4Readout::LocalReadoutClose()
{
    // Close the readout file
    if (filePtr) {
        close(filePtr);
        filePtr = 0;
    }
}

bool ORSLTv4Readout::SimulationReadoutEnergyV31(SBC_LAM_Data*)
{
 
    
    // Send the simulated data to Orca
    // Parameter: block size; data rate
    
    // Check time
    
    // Check space in the buffer
    
    // Copy data packet
    
    // Update length
    
    
    return true;
}

void ORSLTv4Readout::SimulationInit()
{
    uint32_t i;
    uint32_t bufferIndex;
    
    // Write usefull data ti the simulation data block
    // Each block has a header of 4 words and upto 8160 words of data
    
    // Parameter: block size
   
    //
    // Todo: Set this paraeters by any other measns (e.g. preprocessor, inifile, etc)
    //
    simBlockSize = 1365; // max 8160 / 6
    simDataRate = 10;    // MB/s
    
    
    bufferIndex = 0;
    if (simBlockSize > 1365) simBlockSize = 1365;
    
    
    uint32_t energyId   = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    
    uint32_t time       = 1510872785; // Put always the same time in the data
                                     // having real time take too long to prepare
    
    uint32_t headerLen  = 4;
    uint32_t firstIndex = bufferIndex; //so we can insert the length
    
    dataBuffer[bufferIndex++] = energyId | 0; //fill in the length below
    dataBuffer[bufferIndex++] = location  ;
    dataBuffer[bufferIndex++] = 0; //spare
    dataBuffer[bufferIndex++] = 0; //spare
    
    
    for (i=0;i<simBlockSize;i++)
    {
        // Todo: Fill data according to the hardware specification
        dataBuffer[bufferIndex++] = (0x1 << 29) | (1234567 << 3) | ((time) >> 29); // sub seconds 3:27
        dataBuffer[bufferIndex++] = (0x2 << 29) | (time & 0x1fffffff) ; // seconds
        dataBuffer[bufferIndex++] = (0x3 << 29) | ((i%4) << 24) | ((i%24) << 19) | (i+1); // flt ch eventId
        dataBuffer[bufferIndex++] = (0x4 << 29) | 0; // pileup peak
        dataBuffer[bufferIndex++] = (0x5 << 29) | 0; // pileup valley
        dataBuffer[bufferIndex++] = (0x6 << 29) | (2000-(i*i)%20) * 32 ; //energy, 1,6us filer
    }
    
    dataBuffer[firstIndex] |=  (simBlockSize*6 + headerLen); //fill in the record length
    
    return;
}


bool ORSLTv4Readout::ReadoutLegacyCode(SBC_LAM_Data* lamData)
{
    uint32_t i;
    
    //init
    uint32_t eventFifoId = GetHardwareMask()[2];
    //uint32_t energyId    = GetHardwareMask()[3];
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



