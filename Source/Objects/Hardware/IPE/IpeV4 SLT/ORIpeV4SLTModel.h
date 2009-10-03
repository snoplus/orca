//
//  ORIpeV4SLTModel.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORDataTaker.h"
#import "ORIpeCard.h"
#import "SBC_Linking.h"
#import "SBC_Config.h"

@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORIpeFLTModel;
@class PMC_Link;
@class SBC_Link;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))

//control reg bit masks
#define kCtrlTrgEnShift		0
#define kCtrlInhEnShift		6
#define kCtrlPPSShift		10
#define kCtrlTpEnEnShift	11

#define kCtrlLedOffmask	(0x00000001 << 17) //RW
#define kCtrlIntEnMask	(0x00000001 << 16) //RW
#define kCtrlTstSltMask	(0x00000001 << 15) //RW
#define kCtrlRunMask	(0x00000001 << 14) //RW
#define kCtrlShapeMask	(0x00000001 << 13) //RW
#define kCtrlTpEnMask	(0x00000003 << kCtrlTpEnEnShift)	//RW
#define kCtrlPPSMask	(0x00000001 << kCtrlPPSShift)		//RW
#define kCtrlInhEnMask	(0x0000000F <<  kCtrlInhEnShift)	//RW
#define kCtrlTrgEnMask	(0x0000003F <<  kCtrlTrgEnShift)	//RW

//status reg bit masks
#define kStatusIrq			(0x00000001 << 31) //R
#define kStatusFltStat		(0x00000001 << 30) //R
#define kStatusGps2			(0x00000001 << 29) //R
#define kStatusGps1			(0x00000001 << 28) //R
#define kStatusInhibitSrc	(0x0000000f << 24) //R
#define kStatusInh			(0x00000001 << 23) //R
#define kStatusSemaphores	(0x00000007 << 16) //R - cleared on W
#define kStatusFltTimeOut	(0x00000001 << 15) //R - cleared on W
#define kStatusPgFull		(0x00000001 << 14) //R - cleared on W
#define kStatusPgRdy		(0x00000001 << 13) //R - cleared on W
#define kStatusEvRdy		(0x00000001 << 12) //R - cleared on W
#define kStatusSwRq			(0x00000001 << 11) //R - cleared on W
#define kStatusFanErr		(0x00000001 << 10) //R - cleared on W
#define kStatusVttErr		(0x00000001 <<  9) //R - cleared on W
#define kStatusGpsErr		(0x00000001 <<  8) //R - cleared on W
#define kStatusClkErr		(0x0000000F <<  4) //R - cleared on W
#define kStatusPpsErr		(0x00000001 <<  3) //R - cleared on W
#define kStatusPixErr		(0x00000001 <<  2) //R - cleared on W
#define kStatusWDog			(0x00000001 <<  1) //R - cleared on W
#define kStatusFltRq		(0x00000001 <<  0) //R - cleared on W

//Cmd reg bit masks
#define kCmdDisCnt			(0x00000001 << 10) //W - self cleared
#define kCmdEnCnt			(0x00000001 <<  9) //W - self cleared
#define kCmdClrCnt			(0x00000001 <<  8) //W - self cleared
#define kCmdSwRq			(0x00000001 <<  7) //W - self cleared
#define kCmdFltReset		(0x00000001 <<  6) //W - self cleared
#define kCmdSltReset		(0x00000001 <<  5) //W - self cleared
#define kCmdFwCfg			(0x00000001 <<  4) //W - self cleared
#define kCmdTpStart			(0x00000001 <<  3) //W - self cleared
#define kCmdSwTr			(0x00000001 <<  2) //W - self cleared
#define kCmdClrInh			(0x00000001 <<  1) //W - self cleared
#define kCmdSetInh			(0x00000001 <<  0) //W - self cleared

//Interrupt Request and Mask reg bit masks
//Interrupt Request Read only - cleared on Read
//Interrupt Mask Read/Write only
#define kIrptFtlTmo		(0x00000001 << 15) 
#define kIrptPgFull		(0x00000001 << 14) 
#define kIrptPgRdy		(0x00000001 << 13) 
#define kIrptEvRdy		(0x00000001 << 12) 
#define kIrptSwRq		(0x00000001 << 11) 
#define kIrptFanErr		(0x00000001 << 10) 
#define kIrptVttErr		(0x00000001 <<  9) 
#define kIrptGPSErr		(0x00000001 <<  8) 
#define kIrptClkErr		(0x0000000F <<  4) 
#define kIrptPpsErr		(0x00000001 <<  3) 
#define kIrptPixErr		(0x00000001 <<  2) 
#define kIrptWdog		(0x00000001 <<  1) 
#define kIrptFltRq		(0x00000001 <<  0) 

//Revision Masks
#define kRevisionProject (0x0000000F << 28) //R
#define kDocRevision	 (0x00000FFF << 16) //R
#define kImplemention	 (0x0000FFFF <<  0) //R

//Page Manager Masks
#define kPageMngResetShift			22
#define kPageMngNumFreePagesShift	15
#define kPageMngPgFullShift			14
#define kPageMngNextPageShift		8
#define kPageMngReadyShift			7
#define kPageMngOldestPageShift	1
#define kPageMngReleaseShift		0

#define kPageMngReset			(0x00000001 << kPageMngResetShift)			//W - self cleared
#define kPageMngNumFreePages	(0x0000007F << kPageMngNumFreePagesShift)	//R
#define kPageMngPgFull			(0x00000001 << kPageMngPgFullShift)			//W
#define kPageMngNextPage		(0x0000003F << kPageMngNextPageShift)		//W
#define kPageMngReady			(0x00000001 << kPageMngReadyShift)			//W
#define kPageMngOldestPage		(0x0000003F << kPageMngOldestPageShift)	//W
#define kPageMngRelease			(0x00000001 << kPageMngReleaseShift)		//W - self cleared

//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W

@interface ORIpeV4SLTModel : ORIpeCard <ORDataTaker,SBC_Linking>
{
	@private
		unsigned long	hwVersion;
		NSString*		patternFilePath;
		unsigned long	interruptMask;
		unsigned long	nextPageDelay;
		float			pulserAmp;
		float			pulserDelay;
		unsigned short  selectedRegIndex;
		unsigned long   writeValue;
		unsigned long	eventDataId;
		unsigned long	multiplicityId;
		unsigned long   eventCounter;
		int				actualPageIndex;
        TimedWorker*    poller;
		BOOL			pollingWasRunning;
		ORReadOutList*	readOutGroup;
		NSArray*		dataTakers;			//cache of data takers.
		BOOL			first;
		// ak, 9.12.07
		BOOL            displayTrigger;    //< Display pixel and timing view of trigger data
		BOOL            displayEventLoop;  //< Display the event loop parameter
		unsigned long   lastDisplaySec;
		unsigned long   lastDisplayCounter;
		double          lastDisplayRate;
		
		unsigned long   lastSimSec;
		unsigned long   pageSize; //< Length of the ADC data (0..100us)

		PMC_Link*		pmcLink;
        
		unsigned long controlReg;
		unsigned long statusReg;
		unsigned long secondsSet;
		unsigned long pageManagerReg;
		unsigned long deadTime;
		unsigned long vetoTime;
		unsigned long runTime;
		unsigned long clockTime;
		BOOL countersEnabled;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setGuardian:(id)aGuardian;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;

#pragma mark •••Accessors
- (BOOL) countersEnabled;
- (void) setCountersEnabled:(BOOL)aContersEnabled;
- (float) clockTime;
- (void) setClockTime:(float)aClockTime;
- (unsigned long) runTime;
- (void) setRunTime:(unsigned long)aRunTime;
- (unsigned long) vetoTime;
- (void) setVetoTime:(unsigned long)aVetoTime;
- (unsigned long) deadTime;
- (void) setDeadTime:(unsigned long)aDeadTime;
- (unsigned long) pageManagerReg;
- (void) setPageManagerReg:(unsigned long)aPageManagerReg;
- (unsigned long) secondsSet;
- (void) setSecondsSet:(unsigned long)aSecondsSet;
- (unsigned long) statusReg;
- (void) setStatusReg:(unsigned long)aStatusReg;
- (unsigned long) controlReg;
- (void) setControlReg:(unsigned long)aControlReg;

- (SBC_Link*)sbcLink;
- (unsigned long) projectVersion;
- (unsigned long) documentVersion;
- (unsigned long) implementation;
- (void) setHwVersion:(unsigned long) aVersion;

- (NSString*) patternFilePath;
- (void) setPatternFilePath:(NSString*)aPatternFilePath;

- (unsigned long) nextPageDelay;
- (void) setNextPageDelay:(unsigned long)aDelay;
- (unsigned long) interruptMask;
- (void) setInterruptMask:(unsigned long)aInterruptMask;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
//- (unsigned long) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)		setWriteValue: (unsigned long) anIndex;
//- (void) loadPatternFile;

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (unsigned long) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (unsigned long) pageSize;   
 
#pragma mark ***Polling
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
- (void)		  readAllStatus;
- (void)		  checkPresence;
- (unsigned long) readControlReg;
- (void)		  writeControlReg;
- (void)		  printControlReg;
- (unsigned long) readStatusReg;
- (unsigned long) readPageManagerReg;
- (void)		  printStatusReg;
- (void)		  printPageManagerReg;
- (void)		  loadSecondsReg;
- (void)		writeSetInhibit;
- (void)		writeClrInhibit;
- (void)		writeSwTrigger;
- (void)		writeTpStart;
- (void)		writeFwCfg;
- (void)		writeSltReset;
- (void)		writeFltReset;
- (void)		writeSwRq;
- (void)		writeClrCnt;
- (void)		writeEnCnt;
- (void)		writeDisCnt;
- (void)		writeReleasePage;		
- (void)		writePageManagerReset;
- (unsigned long long) readBoardID;
- (void) readEventStatus:(unsigned long*)eventStatusBuffer;

//- (void)		  writeNextPageDelay;
//- (void)		  writeStatusReg;
- (void)		  writeInterruptMask;
- (void)		  readInterruptMask;
- (void)		  readInterruptRequest;
- (void)		  printInterruptRequests;
- (void)		  printInterruptMask;
- (void)		  printInterrupt:(int)regIndex;
//- (void)		  releaseAllPages;
//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(unsigned short)index value:(unsigned long)aValue;
- (unsigned long) readReg:(unsigned short) index;
- (unsigned long) readHwVersion;
- (unsigned long long) readDeadTime;
- (unsigned long long) readVetoTime;
- (unsigned long long) readRunTime;
- (unsigned long) readSecondsCounter;
- (unsigned long) readSubSecondsCounter;
- (unsigned long) getSeconds;

- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		loadPulserValues;
//- (void)		swTrigger;
- (void)		initBoard;
- (void)		autoCalibrate;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (unsigned long) eventDataId;
- (void) setEventDataId: (unsigned long) DataId;
- (unsigned long) multiplicityId;
- (void) setMultiplicityId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

#pragma mark •••DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj;

#pragma mark •••SBC_Linking Protocol
- (NSString*) cpuName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;

#pragma mark •••SBC I/O layer

- (void) read:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len;

- (void) writeBitsAtAddress:(unsigned long)address 
					   value:(unsigned long)dataWord 
					   mask:(unsigned long)aMask 
					shifted:(int)shiftAmount;
					
- (void) setBitsHighAtAddress:(unsigned long)address 
						 mask:(unsigned long)aMask;
						 
		  
#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

@end

extern NSString* ORIpeV4SLTModelCountersEnabledChanged;
extern NSString* ORIpeV4SLTModelClockTimeChanged;
extern NSString* ORIpeV4SLTModelRunTimeChanged;
extern NSString* ORIpeV4SLTModelVetoTimeChanged;
extern NSString* ORIpeV4SLTModelDeadTimeChanged;
extern NSString* ORIpeV4SLTModelPageManagerRegChanged;
extern NSString* ORIpeV4SLTModelSecondsSetChanged;
extern NSString* ORIpeV4SLTModelStatusRegChanged;
extern NSString* ORIpeV4SLTModelControlRegChanged;
extern NSString* ORIpeV4SLTModelHwVersionChanged;

extern NSString* ORIpeV4SLTModelPatternFilePathChanged;
extern NSString* ORIpeV4SLTModelInterruptMaskChanged;
extern NSString* ORIpeV4SLTModelPageSizeChanged;
extern NSString* ORIpeV4SLTModelDisplayEventLoopChanged;
extern NSString* ORIpeV4SLTModelDisplayTriggerChanged;
extern NSString* ORIpeV4SLTPulserDelayChanged;
extern NSString* ORIpeV4SLTPulserAmpChanged;
extern NSString* ORIpeV4SLTSelectedRegIndexChanged;
extern NSString* ORIpeV4SLTWriteValueChanged;
extern NSString* ORIpeV4SLTSettingsLock;
extern NSString* ORIpeV4SLTStatusRegChanged;
extern NSString* ORIpeV4SLTControlRegChanged;
extern NSString* ORIpeV4SLTModelNextPageDelayChanged;
extern NSString* ORIpeV4SLTModelPollRateChanged;
extern NSString* ORIpeV4SLTModelReadAllChanged;

extern NSString* ORSLTV4cpuLock;	

