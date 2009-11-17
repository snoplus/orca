//
//  HW_Readout.cpp
//  Orca
//
//  Created by Mark Howe on Mon Mar 10, 2008
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>


#ifdef __cplusplus
extern "C" {
#endif
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "SLTv4_HW_Definitions.h"
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include "pbusinterface.h"
#ifdef __cplusplus
}
#endif

#include "hw4/baseregister.h"
#include "katrinhw4/subrackkatrin.h"
#include "katrinhw4/sltkatrin.h"
#include "katrinhw4/fltkatrin.h"

#include "HW_Readout.h"

static hw4::SubrackKatrin *srack=0;
#define USE_PBUS 0

void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

//replace with whatever device driver handle(s) you have
//TUVMEDevice* vmeAM29Handle = NULL;
//TUVMEDevice* controlHandle = NULL;
//TUVMEDevice* vmeAM39Handle = NULL;
//TUVMEDevice* vmeAM9Handle = NULL;

void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
	
    switch(aCmdID){
			//        default:              processUnknownCommand(aPacket); break;
    }
}

void startHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

void stopHWRun (SBC_crate_config* config)
{
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

void FindHardware(void)
{
	//open device driver(s), get device driver handles
	const char* name = "FE.ini";
#if USE_PBUS
	pbusInit((char*)name);
#else
	srack = new hw4::SubrackKatrin((char*)name,0);
	srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-
	
#endif
	// testing the C++ link to fdhwlib -tb-
	if(0){
		printf("Try to create a BaseRegister object -tb-\n");
		fflush(stdout);
		hw4::BaseRegister *reg;
		reg = new hw4::BaseRegister("dummy",3,7,1,1);
		printf("  ->register name is %s, addr 0x%08lx\n", reg->getName(),reg->getAddr());
		fflush(stdout);
	}
}

void ReleaseHardware(void)
{
	//release / close device driver(s)
#if USE_PBUS
    pbusFree();
#else
    delete srack;
#endif
}

void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
	
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;								/*point to the data*/
	int32_t* lptr = (int32_t*)p;		/*cast to the data type*/ 
	if(needToSwap) SwapLongBlock(lptr,numItems);
    
	//**** use device driver call to write data to HW
	int32_t perr = 0;
    if (numItems == 1)	perr = pbusWrite(startAddress, *lptr);
	else				perr = pbusWriteBlock(startAddress, (unsigned long *) lptr, numItems);
	
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_IPEv4WriteBlockStruct* returnDataPtr = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = 0;
	
	//assuming that the device driver returns the number of bytes read
	if(perr == 0){
        returnDataPtr->errorCode = 0;
    }
    else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4WriteBlockStruct);
        returnDataPtr->errorCode = perr;        
    }
	
    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);
	
	//send back to ORCA
    if(reply)writeBuffer(aPacket);    
	
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    int32_t numItems        = p->numItems;
	//TODO: -tb- debug printf("starting read: %08x %d\n",startAddress,numItems);
	
    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSize) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        if(reply)writeBuffer(aPacket);
        return;
    }
	
    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_ReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    = sizeof(SBC_IPEv4ReadBlockStruct) + numItems*sizeof(uint32_t);
	
    SBC_IPEv4ReadBlockStruct* returnDataPtr = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);
    unsigned long *lPtr = (unsigned long *) returnPayload;
	
	int32_t perr   = 0;
    if (numItems == 1)  perr = pbusRead(startAddress, lPtr);
    else				perr = pbusReadBlock(startAddress, lPtr, numItems);
	//TODO: -tb- printf("perr: %d\n",perr);
 	
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = numItems;
    if(perr == 0){
        returnDataPtr->errorCode = 0;
		if(needToSwap) SwapLongBlock((int32_t*)returnPayload,numItems);
    }
    else {
        //TODO: -tb- sprintf(aPacket->message,"error: %d %d : %s\n",perr,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4ReadBlockStruct);
        returnDataPtr->numItems  = 0;
        returnDataPtr->errorCode = perr;        
    }
	
    if(needToSwap) SwapLongBlock(returnDataPtr,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    if(reply)writeBuffer(aPacket);
}

/*************************************************************/
/*  All HW Readout code follows here.						 */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/
int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    if(index<config->total_cards && index>=0) {
        switch(config->card_info[index].hw_type_id){
            case kSLTv4:       index = Readout_Sltv4(config,index,lamData);       break;
            case kFLTv4:       index = Readout_Fltv4(config,index,lamData);       break;
            default:            index = -1;                                       break;
        }
        return index;
    }
    else return -1;
}

/*************************************************************/
/*             Reads out									 */
/*************************************************************/
int32_t Readout_Sltv4(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
#if 0
    //"counter" for debugging
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
	double diffTime = (double)(currentSec  - lastSec) +
	((double)(currentUSec - lastUSec)) * 0.000001;
	
	if(diffTime >1.0){
		secCounter++;
		printf("PrPMC sec %ld: 1 sec is overa ...\n",secCounter);
		fflush(stdout);
		//remember for next call
		lastSec      = currentSec; 
		lastUSec     = currentUSec; 
	}else{
		// skip shipping data record
		return config->card_info[index].next_Card_Index;
	}
#endif
	short leaf_index;
	//read out the children flts that are in the readout list
	leaf_index = config->card_info[index].next_Trigger_Index[0];
	while(leaf_index >= 0) {
		leaf_index = readHW(config,leaf_index,lamData);
	}
    
	
#if 0
    uint32_t dataId            = config->card_info[index].hw_mask[0];
    uint32_t stationNumber     = config->card_info[index].slot;
    uint32_t crate             = config->card_info[index].crate;
    data[dataIndex++] = dataId | 5;
    data[dataIndex++] =  ((stationNumber & 0x0000001f) << 16) | (crate & 0x0f) <<21;
    data[dataIndex++] = 6;
    data[dataIndex++] = 8;
    data[dataIndex++] = 15;
#endif
	
    return config->card_info[index].next_Card_Index;
}            

#define kFifoEmpty 0x01

int32_t Readout_Fltv4(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    
    uint32_t dataId     = config->card_info[index].hw_mask[0];
    uint32_t waveformId = config->card_info[index].hw_mask[1];
    uint32_t histogramId = config->card_info[index].hw_mask[2];
    uint32_t col		= config->card_info[index].slot - 1; //the mac slots go from 1 to n
    uint32_t crate		= config->card_info[index].crate;
	uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
	
	//not used for now..
	//uint32_t postTriggerTime = config->card_info[index].deviceSpecificData[0];
	uint32_t eventType = config->card_info[index].deviceSpecificData[1];
	uint32_t runMode   = config->card_info[index].deviceSpecificData[2];
	uint32_t runFlags  = config->card_info[index].deviceSpecificData[3];
	
	if(srack->theFlt[col]->isPresent()){
		if(runMode == kIpeFltV4Katrin_Run_Mode){
			uint32_t status		 = srack->theFlt[col]->status->read();
			uint32_t  fifoStatus = (status >> 24) & 0xf;
			
			if(fifoStatus != kFifoEmpty){
				//TO DO... the number of events to read could (should) be made variable 
				uint32_t eventN;
				for(eventN=0;eventN<10;eventN++){
					
					//should be something in the fifo, check the read/write pointers and read and package up to 10 events.
					uint32_t fstatus = srack->theFlt[col]->eventFIFOStatus->read();
					uint32_t writeptr = fstatus & 0x3ff;
					uint32_t readptr = (fstatus >>16) & 0x3ff;
					uint32_t diff = (writeptr-readptr+1024) % 512;
					
					if(diff>1){
						uint32_t f1 = srack->theFlt[col]->eventFIFO1->read();
						uint32_t chmap = f1 >> 8;
						uint32_t f2 = srack->theFlt[col]->eventFIFO2->read();
						int eventchan;
						for(eventchan=0;eventchan<24;eventchan++){
							if(chmap & (0x1 << eventchan)){
								//fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
								uint32_t f3			= srack->theFlt[col]->eventFIFO3->read(eventchan);
								uint32_t f4			= srack->theFlt[col]->eventFIFO4->read(eventchan);
								uint32_t pagenr		= f3 & 0x3f;
								uint32_t energy		= f4 ;
								uint32_t evsec		= ( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
								uint32_t evsubsec	= (f2 >> 2) & 0x1ffffff; // 25 bit
								
								uint32_t waveformLength = 2048; 
								if(eventType & kReadWaveForms){
									ensureDataCanHold(9 + waveformLength/2); 
									data[dataIndex++] = waveformId | 9 + waveformLength/2;	
								}
								else {
									ensureDataCanHold(7); 
									data[dataIndex++] = dataId | 7;	
								}
								

								data[dataIndex++] = location | eventchan<<8;
								data[dataIndex++] = evsec;		//sec
								data[dataIndex++] = evsubsec;	//subsec
								data[dataIndex++] = chmap;
								data[dataIndex++] = pagenr;		//was listed as the event ID... put in the pagenr for now 
								data[dataIndex++] = energy;
								
								if(eventType & kReadWaveForms){
									static uint32_t waveformBuffer32[64*1024];
									static uint32_t shipWaveformBuffer32[64*1024];
									static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
									static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
									uint32_t triggerPos = 0;
									
									srack->theSlt->pageSelect->write(0x100 | pagenr);
									
									uint32_t adccount;
									for(adccount=0; adccount<1024;adccount++){
										uint32_t adcval = srack->theFlt[col]->ramData->read(eventchan,adccount);
										waveformBuffer32[adccount] = adcval;
#if 1 //TODO: WORKAROUND - align according to the trigger flag - in future we will use the timestamp, when Denis has fixed it -tb-
										uint32_t adcval1 = adcval & 0xffff;
										uint32_t adcval2 = (adcval >> 16) & 0xffff;
										if(adcval1 & 0x8000) triggerPos = adccount*2;
										if(adcval2 & 0x8000) triggerPos = adccount*2+1;
#endif
									}
									uint32_t copyindex = (triggerPos + 1024) % 2048; // + postTriggerTime;
									uint32_t i;
									for(i=0;i<waveformLength;i++){
										shipWaveformBuffer16[i] = waveformBuffer16[copyindex];
										copyindex++;
										copyindex = copyindex % 2048;
									}
									
									//simulation mode
									if(0){
										for(i=0;i<waveformLength;i++){
											shipWaveformBuffer16[i]= (i>100)*i;
										}
									}
									//ship waveform
									uint32_t waveformLength32=waveformLength/2; //the waveform length is variable	
									data[dataIndex++] = 0;	//spare to remain byte compatible with the v3 record
									data[dataIndex++] = 0;	//spare to remain byte compatible with the v3 record
									for(i=0;i<waveformLength32;i++){
										data[dataIndex++] = shipWaveformBuffer32[i];
									}
								}
							}
						}
					}
					else break;
				}
			}
        }
		else if(runMode == kIpeFltV4Katrin_Histo_Mode) {	
				//uint32_t pagenr,oldpagenr ;
				uint32_t pageAB,oldpageAB;
                uint32_t pStatus[3];
				//fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
				//fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
				//sleep(1);   
				if(runFlags & 0x10000){// firstTime	
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
					config->card_info[index].deviceSpecificData[3]=pageAB;
					fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
					//sleep(1);
				}
				else{//check timing
					//pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
					oldpageAB = config->card_info[index].deviceSpecificData[3]; //
                    pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
					//fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
					//              sleep(1);
					
					if(oldpageAB != pageAB){
						fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
						config->card_info[index].deviceSpecificData[3] = pageAB; 
						//read data
						int chan=0;
						uint32_t adcval, lastFirst, last,first,llast,lfirst;
						static uint32_t histogramBuffer32[1024];
						static uint32_t shipHistogramBuffer32[2*1024];
						for(chan=0;chan<24;chan++)						{//read out histogram
							uint32_t adccount;
							lastFirst = srack->theFlt[col]->histLastFirst->read(chan);
							last = (lastFirst >>16) & 0xffff;
							first = lastFirst & 0xffff;
							fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
							if(last<first){
								//no events
								continue;
							}
							else{
								//read out histogram
								//lfirst= first/2; llast=last/2;
								lfirst= 0; llast=1023;//TODO: there is something wrong with last/first bin information -tb-
								int cnt=0;
						srack->theSlt->pageSelect->write(0x100 | 0);//TODO: do it once? -tb-
								for(adccount=0; adccount<1024;adccount++){
                                    shipHistogramBuffer32[adccount] =  srack->theFlt[col]->ramData->read(chan,adccount);
								}
						srack->theSlt->pageSelect->write(0x100 | 1);//TODO: do it once? -tb-
								for(adccount=0; adccount<1024;adccount++){
                                    shipHistogramBuffer32[adccount+1024] =  srack->theFlt[col]->ramData->read(chan,adccount);
								}
								//fprintf(stdout,"\n");
							}
							
							//prepare data record
							katrinHistogramDataStruct theEventData;
							theEventData.readoutSec = 0;
							theEventData.recordingTimeSec =  0;//histoRunTime; 
							theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
							theEventData.lastBin   = 2048;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
							theEventData.histogramLength =2048;
							//theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
							//if(theEventData.histogramLength < 0){// we had no counts ...
							//    theEventData.histogramLength = 0;
							//}
							theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
							theEventData.binSize    = 1;//histoBinWidth;        
							theEventData.offsetEMin = 0;//histoMinEnergy;
							
							//ship data record
							unsigned long totalLength = 2 + (sizeof(katrinHistogramDataStruct)/sizeof(long)) + theEventData.histogramLength;// 2 = header + locationWord
							data[dataIndex++] = histogramId | totalLength;	
							data[dataIndex++] = location | chan<<8;
							data[dataIndex++] = theEventData.readoutSec;
							data[dataIndex++] = theEventData.recordingTimeSec;
							data[dataIndex++] = theEventData.firstBin;
							data[dataIndex++] = theEventData.lastBin;
							data[dataIndex++] = theEventData.histogramLength;
							data[dataIndex++] = theEventData.maxHistogramLength;
							data[dataIndex++] = theEventData.binSize;
							data[dataIndex++] = theEventData.offsetEMin;
							int i;
							for(i=0; i<theEventData.histogramLength;i++)
								data[dataIndex++] = shipHistogramBuffer32[i];
							
						}
					} 
				}
		}
	}
	
    return config->card_info[index].next_Card_Index;
}

#if (0)
//maybe read hit rates in the pmc at some point..... here's how....
//read hitrates
{
	int col,row;
	for(col=0; col<20;col++){
		if(srack->theFlt[col]->isPresent()){
			//fprintf(stdout,"FLT %i:",col);
			for(row=0; row<24;row++){
				int hitrate = srack->theFlt[col]->hitrate->read(row);
				//if(row<5) fprintf(stdout," %i(0x%x),",hitrate,hitrate);
			}
			//fprintf(stdout,"\n");
			//fflush(stdout);
			
		}
	}
}
#endif
