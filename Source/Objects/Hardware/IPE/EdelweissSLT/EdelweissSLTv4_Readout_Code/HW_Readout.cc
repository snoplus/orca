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

// options of general read and write ops, history and description: see below
#define kCodeVersion     2
#define kFdhwLibVersion  2 //2011-06-16 currently not necessary as it is now fetched dirctly from fdhwlib -tb-

//history and description
//
//The SBC protocol provides functions 
// void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply)
// and
// void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)
//
// option 'kGetSoftwareVersion' returns kCodeVersion as value of the code version, current value: see above.


/*
kCodeVersion history:
after all major changes in HW_Readout.cc, FLTv4Readout.cc, FLTv4Readout.hh, SLTv4Readout.cc, SLTv4Readout.hh
kCodeVersion should be increased!

kCodeVersion 2:
2011-06-16 readout code ships now new register value 'fifoEventID'

kCodeVersion 1:
January 2011,  implemented general read and write, new
*/ //-tb-


#define USE_PBUS 0
//Define USE_PBUS for usage of the pbusaccess library (obsolete, will be removed/changed in the future) -tb- 2010-04-09


#ifdef __cplusplus
extern "C" {
#endif
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "EdelweissSLTv4_HW_Definitions.h"
#include "EdelweissSLTv4GeneralOperations.h"
#ifdef __cplusplus
}
#endif

#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if (PMC_COMPILE_IN_SIMULATION_MODE == 1)
    #warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    #warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 0
#endif


#if USE_PBUS
#ifdef __cplusplus
extern "C" {
#endif
#include "pbusinterface.h"
#ifdef __cplusplus
}
#endif
#endif


#if PMC_COMPILE_IN_SIMULATION_MODE
    # warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    //# warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "fdhwlib.h"
	//already included #include "Pbus/Pbus.h"
	#include "hw4/baseregister.h"
	//#include "katrinhw4/subrackkatrin.h"
	#include "katrinhw4/sltkatrin.h"
	#include "katrinhw4/fltkatrin.h"
#endif

#include "HW_Readout.h"


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

//hw4::SubrackKatrin* get_sub_rack() { return srack; }



#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------


void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
            //        default:              processUnknownCommand(aPacket); break;
    }
}

void FindHardware(void)
{
    //open device driver(s), get device driver handles
    const char* name = "FE.ini";
#if USE_PBUS
    pbusInit((char*)name);
#else
    //TODO: check here blocking semaphores? -tb-
	
	
	
    //TODO: changed for EW ... -tb- ... 
	#if 0
    srack = new hw4::SubrackKatrin((char*)name,0);
	srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-
    pbus = srack->theSlt->version; //all registers inherit from Pbus, we choose "version" as it shall exist for all FPGA configurations
	#else
	//similar to readword.cpp:
	int err = 0;
	try {
		if (pbus > 0) pbus->free();
		pbus = new Pbus();
		pbus->init();
	} catch (PbusError &e){
		err = 1;
	}
	if(err) printf("HW_Readout.cc (IPE EW DAQ V4): ERROR: Creating Pbus failed!\n");
#endif
    if(!pbus) fprintf(stdout,"HW_Readout.cc (IPE EW DAQ V4): ERROR: could not connect to Pbus!\n");

    //pbus test
    std::string getStr, cmdStr;
    cmdStr = "blockmode";
    pbus->get(cmdStr,&getStr);
    printf("   Pbus:: get %s: result: %s \n",cmdStr.c_str(),getStr.c_str());

    // test/force the C++ link to fdhwlib -tb-
    if(0){// unused, but compiled! -tb-
        printf("Try to create a BaseRegister object -tb-\n");
        fflush(stdout);
        hw4::BaseRegister *reg;
        reg = new hw4::BaseRegister("dummy",3,7,1,1);
        printf("  ->register name is %s, addr 0x%08lx\n", reg->getName(),reg->getAddr());
        fflush(stdout);
    }
#endif
}

void ReleaseHardware(void)
{
    //release / close device driver(s)
#if USE_PBUS
    pbusFree();
#else
    pbus = 0;
    //delete srack;
#endif
}

void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    int32_t* lptr = (int32_t*)p;        /*cast to the data type*/ 
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
#if USE_PBUS
    if (numItems == 1)    perr = pbusWrite(startAddress, *lptr);
    else                perr = pbusWriteBlock(startAddress, (unsigned long *) lptr, numItems);
#else
    try{
        if (numItems == 1)  pbus->write(startAddress, *lptr);
        else                pbus->writeBlock(startAddress, (unsigned long *) lptr, numItems);
    }catch(PbusError &e){
        perr = 1;
    }
#endif
    
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
    
    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSizeBytes) {
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
#if USE_PBUS
    if (numItems == 1)  perr = pbusRead(startAddress, lPtr);
    else                perr = pbusReadBlock(startAddress, lPtr, numItems);
    //TODO: -tb- printf("perr: %d\n",perr);
#else
    try{
        if (numItems == 1){
		    *lPtr = pbus->read(startAddress);
			//printf("read from 0x%x, value is %i (0x%x)\n",startAddress, *lPtr,*lPtr);//TODO: debugging
		}
        else                pbus->readBlock(startAddress, (unsigned long *) lPtr, numItems);
    }catch(PbusError &e){
        perr = 1;
    }
#endif
     
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

#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

void processHWCommand(SBC_Packet* aPacket)  // 'simulation' version -tb-
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
            //        default:              processUnknownCommand(aPacket); break;
    }
}

void FindHardware(void)  // 'simulation' version -tb-
{
	printf("Called HW_Readout-FindHardware\n");
}

void ReleaseHardware(void)  // 'simulation' version -tb-
{
	printf("Called HW_Readout-ReleaseHardware\n");
}


void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)  // 'simulation' version -tb-
{
	printf("Called HW_Readout-doWriteBlock\n");
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    int32_t* lptr = (int32_t*)p;        /*cast to the data type*/ 
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
	//hardware write access removed (was here) -tb-
    
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

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)  // 'simulation' version -tb-
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    int32_t numItems        = p->numItems;
	//DEBUGGING
	{
	static int counter=0;
	counter++;
	if(counter<150){ printf("Called HW_Readout-doReadBlock in Simulation mode, log some accesses: addr: 0x%x, (numitems %i)\n",startAddress,numItems);fflush(stdout);}
	}
    //TODO: -tb- debug printf("starting read: %08x %d\n",startAddress,numItems);
    
    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSizeBytes) {
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
	//hardware read access removed (was here) -tb-
	for(int i=0; i<numItems;i++) lPtr[i] = 0;
	{
		//this simulates a hitrate (startAddress &  0x001100>>2  are the hitrate registers) -tb
		if(startAddress & (0x001100>>2)){ //this is KATRINv4FLT specific! -tb-
			//printf("Probably Hitrate readout: addr 0x%x (numItems %i)\n",startAddress,numItems);
			//fflush(stdout);
			for(int i=0; i<numItems;i++) lPtr[i] = 100 * ((startAddress>>17)&0x1f)+ ((startAddress>>12)&0x1f) + i*1000;
			//*lPtr = 2;
		}
	}
	
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


#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------

void doGeneralWriteOp(SBC_Packet* aPacket,uint8_t reply)
{
	SBC_WriteBlockStruct* p = (SBC_WriteBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_WriteBlockStruct)/sizeof(int32_t));
	int32_t operation = p->address;
	int32_t num = p->numLongs;
	p++;
	int32_t* dataToWrite = (int32_t*)p;
	if(needToSwap)SwapLongBlock(dataToWrite,num);
	switch(operation){
		//nothing defined yet
		default:
		break;
	}
	//just return the packet for now...	
	if(reply)writeBuffer(aPacket);
}

void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)
{
	//what to read?
	SBC_ReadBlockStruct* p = (SBC_ReadBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_ReadBlockStruct)/sizeof(int32_t));
	int32_t numLongs = p->numLongs;
	int32_t operation  = p->address;

	//OK, got address and # to read, set up the response and go get the data
	aPacket->cmdHeader.destination	= kSBC_Process;
	aPacket->cmdHeader.cmdID		= kSBC_GeneralRead;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_ReadBlockStruct) + numLongs*sizeof(int32_t);
	
	SBC_ReadBlockStruct* dataPtr = (SBC_ReadBlockStruct*)aPacket->payload;
	dataPtr->numLongs = numLongs;
	dataPtr->address  = operation;
	if(needToSwap)SwapLongBlock(dataPtr,sizeof(SBC_ReadBlockStruct)/sizeof(int32_t));
	dataPtr++;
	
	int32_t* lPtr		= (int32_t*)dataPtr;
	int32_t* startPtr	= lPtr;
	int32_t i;
	switch(operation){
		case kGetSoftwareVersion:
			if(numLongs == 1) *lPtr = kCodeVersion;
		break;
		case kGetFdhwLibVersion:
			//first test: if(numLongs == 1) *lPtr = kFdhwLibVersion; 
			#if defined FDHWLIB_VER
			if(numLongs == 1) *lPtr = FDHWLIB_VER; //in fdhwlib.h -tb-
			#else
			if(numLongs == 1) *lPtr = 0xffffffff; //we are probably in simulation mode and not linking with fdhwlib -tb-
			#endif
		break;
		case kGetSltPciDriverVersion:
			if(numLongs == 1) *lPtr = getSltLinuxKernelDriverVersion(); 
		break;
		default:
			for(i=0;i<numLongs;i++)*lPtr++ = 0; //undefined operation so just return zeros
		break;
	}
	if(needToSwap)SwapLongBlock(startPtr,numLongs/sizeof(int32_t));

	if(reply)writeBuffer(aPacket);
}



/*--------------------------------------------------------------------------------------
 *int getSltLinuxKernelDriverVersion(): search string in /proc/devices, works only for Linux!!
 *--------------------------------------------------------------------------------------
 */
//#include <stdlib.h>  //atioi, strtol
//#include <stdio.h>
//#include <string.h>  //strtstr

//currently we have only Linux, but we want to run simulation mode on all OSs -tb-
#ifdef __linux__
#define DRIVERNAME "fzk_ipe_slt"
int getSltLinuxKernelDriverVersion(void)
{
	char buf[1024 * 4];
	char *cptr;
	FILE *p;
	int version = -2;
	p = popen("cat /proc/devices | grep fzk_ipe_slt","r");
	if(p==0){ fprintf(stderr, "could not start popen... -tb-\n"); return version; }
	
	while (!feof(p)){
	    fscanf(p,"%s",buf);
		if( cptr=strstr(buf, DRIVERNAME) ){  // dont use strncmp, it finds fzk_ipe_slt1, too, which does not exist -tb-
		     version = -1;
			 if( strlen(buf) == strlen(DRIVERNAME)){ version = 0; break; }   // v0, 1st version "fzk_ipe_slt"
			 if( strstr(buf, DRIVERNAME "_dma") ){ version = 1; break;}      // v1, 2nd version "fzk_ipe_slt_dma"
			 cptr = cptr + strlen(DRIVERNAME);                               // vX, (X+1)nd version "fzk_ipe_sltX" -> go to string after basename
			 version = atoi(cptr);
			 //alternative: version = strtol(cptr, (char **) NULL, 10);
			 break;
		}
		if(feof(p)) break; //??? is this necessary??? -tb-
	};

	pclose(p);
	//printf("version is: %i\n",version);
	return version;
}
#else
//non Linux version
int getSltLinuxKernelDriverVersion(void)
{
	int version = -2;
	return version;
}
#endif
