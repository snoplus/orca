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
@class PCM_Link;
@class SBC_Link;

#define IsBitSet(A,B) (((A) & (B)) == (B))
#define ExtractValue(A,B,C) (((A) & (B)) >> (C))

#define SLT_TRIGGER_SW    0x01  // Software
#define SLT_TRIGGER_I_N   0x07  // Internal + Neighbors
#define SLT_TRIGGER_LEFT  0x04  // left neighbor
#define SLT_TRIGGER_RIGHT 0x02  // right neighbor
#define SLT_TRIGGER_INT   0x08  // Internal only
#define SLT_TRIGGER_EXT   0x10  // External

#define SLT_INHIBIT_SW    0x01  // Software
#define SLT_INHIBIT_INT   0x02  // Internal
#define SLT_INHIBIT_EXT   0x04  // External
#define SLT_INHIBIT_ALL   0x07  // Internal + External
#define SLT_INHIBIT_NO    0x01  // None of both (only Software)

// not required any more !
#define SLT_NXPG_INT      0x00   // Internal
#define SLT_NXPG_EXT      0x01   // External
#define SLT_NXPG_SW       0x01   // Software

#define SLT_TESTPULS_NO   0x00   // None
#define SLT_TESTPULS_EXT  0x02   // External
#define SLT_TESTPULS_SW   0x01   // Software

#define SLT_SECSTROBE_INT 0x00   // Internal SecStrobe Signal
#define SLT_SECSTROBE_EXT 0x01   // Extern
#define SLT_SECSTROBE_SW  0x00   // Software - not available -
#define SLT_SECSTROBE_CAR 0x00   // Carry of Subsecond Counter
                                 //   - not available -

// called also watchdog in the slt hardware documentation
#define SLT_WATCHDOGSTART_INT   0x02   // Start with internal second strobe
#define SLT_WATCHDOGSTART_EXT   0x00   // External  - not available -
#define SLT_WATCHDOGSTART_SW    0x01   // Software

//control reg bit masks
#define kCtrlLedOffmask	(0x00000001 << 17) //RW
#define kCtrlIntEnMask	(0x00000001 << 16) //RW
#define kCtrlTstSltMask	(0x00000001 << 15) //RW
#define kCtrlRunMask	(0x00000001 << 14) //RW
#define kCtrlShapeMask	(0x00000001 << 13) //RW
#define kCtrlTpEn		(0x00000003 << 11) //RW
#define kCtrlPPS		(0x00000001 << 10) //RW
#define kCtrlInhEn		(0x0000000F <<  6) //RW
#define kCtrlTrgEn		(0x0000003F <<  0) //RW

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
#define kCmdFltRes			(0x00000001 <<  6) //W - self cleared
#define kCmdSltRes			(0x00000001 <<  5) //W - self cleared
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
#define kPageMngReset			(0x00000001 << 22) //W - self cleared
#define kPageMngNumFreePages	(0x0000007F << 15) //R
#define kPageMngPgFull			(0x00000001 << 14) //W
#define kPageNextPage			(0x0000003F <<  8) //W
#define kPageReady				(0x00000001 <<  7) //W
#define kPageOldestBuffer		(0x0000003F <<  1) //W
#define kPageRelease			(0x00000001 <<  0) //W - self cleared

//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W

@interface ORIpeV4SLTModel : ORIpeCard <ORDataTaker,SBC_Linking>
{
	@private
		unsigned long hwVersion;
	
		//status reg 
		BOOL watchDogError;
		BOOL pixelBusError;
		BOOL ppsError;
		BOOL clockError;
		BOOL gpsError;
		BOOL vttError;
		BOOL fanError;
	
		BOOL veto;
		BOOL extInhibit;
		BOOL nopgInhibit;
		BOOL swInhibit;
		BOOL inhibit;

		//status reg
		BOOL ledInhibit;
		BOOL ledVeto;
		int triggerSource;
		int inhibitSource;
		int testPulseSource;
		int secStrobeSource;
		int watchDogStart;
		int enableDeadTimeCounter;
		NSString*		patternFilePath;

		//page status
		unsigned long pageStatusLow;
		unsigned long pageStatusHigh;
		unsigned long actualPage;
		unsigned long nextPage;

		//interrupts
		unsigned long interruptMask;

		//time management
		unsigned long nextPageDelay;

		//pulser generation
		float pulserAmp;
		float pulserDelay;

		// Register information
		unsigned short  selectedRegIndex;
		unsigned long   writeValue;

		//multiplicity trigger
		unsigned short nHit;
		unsigned short nHitThreshold;
		BOOL		   readAll;
		
		unsigned long	eventDataId;
		unsigned long	multiplicityId;
		unsigned long   eventCounter;
		
		float fpgaVersion;
		int actualPageIndex;
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
		
		
    	BOOL usingPBusSimulation;
		unsigned long   lastSimSec;
		unsigned long   pageSize; //< Length of the ADC data (0..100us)

		PCM_Link*		pcmLink;
        
		unsigned long controlReg;
		unsigned long statusReg;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setGuardian:(id)aGuardian;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) checkAndLoadFPGAs;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;

#pragma mark •••Accessors
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

- (unsigned long) pageStatusLow;
- (void) setPageStatusLow:(unsigned long)loPart 
					 high:(unsigned long)hiPart 
				   actual:(unsigned long)p0 
					 next:(unsigned long)p1;
- (unsigned long) pageStatusHigh;
- (unsigned long) actualPage;
- (unsigned long) nextPage;
- (unsigned long) nextPageDelay;
- (void) setNextPageDelay:(unsigned long)aDelay;
- (unsigned long) interruptMask;
- (void) setInterruptMask:(unsigned long)aInterruptMask;
- (float) fpgaVersion;
- (void) setFpgaVersion:(float)aFpgaVersion;
- (unsigned short) nHitThreshold;
- (void) setNHitThreshold:(unsigned short)aNHitThreshold;
- (unsigned short) nHit;
- (void) setNHit:(unsigned short)aNHit;
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
- (BOOL)	readAll;
- (void)    setReadAll:(BOOL)aState;
//- (void) loadPatternFile;

- (BOOL) displayTrigger; //< Staus of dispaly of trigger information
- (void) setDisplayTrigger:(BOOL) aState; 
- (BOOL) displayEventLoop; //< Status of display of event loop performance information
- (void) setDisplayEventLoop:(BOOL) aState;
- (unsigned long) pageSize; //< Length of the ADC data (0..100us)
- (void) setPageSize: (unsigned long) pageSize;   
 
//status reg assess
- (BOOL) inhibit;
- (void) setInhibit:(BOOL)aInhibit;
- (BOOL) swInhibit;
- (void) setSwInhibit:(BOOL)aSwInhibit;
- (BOOL) nopgInhibit;
- (void) setNopgInhibit:(BOOL)aNopgInhibit;
- (BOOL) extInhibit;
- (void) setExtInhibit:(BOOL)aExtInhibit;
- (BOOL) veto;
- (void) setVeto:(BOOL)aVeto;

//control reg access
- (BOOL) ledInhibit;
- (void) setLedInhibit:(BOOL)aState;
- (BOOL) ledVeto;
- (void) setLedVeto:(BOOL)aState;
- (BOOL) enableDeadTimeCounter;
- (void) setEnableDeadTimeCounter:(BOOL)aState;
- (int) watchDogStart;
- (void) setWatchDogStart:(int)aWatchDogStart;
- (int) secStrobeSource;
- (void) setSecStrobeSource:(int)aSecStrobeSource;
- (int) testPulseSource;
- (void) setTestPulseSource:(int)aTestPulseSource;
- (int) inhibitSource;
- (void) setInhibitSource:(int)aInhibitSource;
- (int) triggerSource;
- (void) setTriggerSource:(int)aTriggerSource;
//- (void) releaseSwInhibit;
//- (void) setSwInhibit;
- (BOOL) usingNHitTriggerVersion;

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
- (void)		  printStatusReg;
//- (void)		  writeNextPageDelay;
//- (void)		  writeStatusReg;
//- (void)		  writeInterruptMask;
//- (void)		  readInterruptMask;
//- (void)		  printInterruptMask;
//- (void)		  readPageStatus;
//- (void)		  releaseAllPages;
//- (void)		  dumpTriggerRAM:(int)aPageIndex;

- (void)		  writeReg:(unsigned short)index value:(unsigned long)aValue;
- (unsigned long) readReg:(unsigned short) index;
- (float)		  readHwVersion;
//- (unsigned long long) readDeadTime;
//- (unsigned long long) readVetoTime;
- (void)		reset;
- (void)		hw_config;
- (void)		hw_reset;
//- (void)		loadPulseAmp;
//- (void)		pulseOnce;
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
						 
- (void) readRegisterBlock:(unsigned long)  anAddress
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots;
			 
- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr;
		 
- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;
		  
- (void) clearBlock:(unsigned long)  anAddress 
		 pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;

#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

@end

extern NSString* ORIpeV4SLTModelStatusRegChanged;
extern NSString* ORIpeV4SLTModelControlRegChanged;
extern NSString* ORIpeV4SLTModelHwVersionChanged;

extern NSString* ORIpeV4SLTModelPatternFilePathChanged;
extern NSString* ORIpeV4SLTModelInterruptMaskChanged;
extern NSString* ORIpeV4SLTModelFpgaVersionChanged;
extern NSString* ORIpeV4SLTModelNHitThresholdChanged;
extern NSString* ORIpeV4SLTModelNHitChanged;
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
extern NSString* ORIpeV4SLTModelPageStatusChanged;
extern NSString* ORIpeV4SLTModelPollRateChanged;
extern NSString* ORIpeV4SLTModelReadAllChanged;

extern NSString* ORSLTV4cpuLock;	

