/*
 *  ORCMC203Model.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

 
#pragma mark ¥¥¥Imported Files
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"

@class ORDataPacket;

@interface ORCMC203Model : ORCamacIOCard <ORDataTaker> {
    @private
        unsigned long dataId;
		
        //place to cache some stuff for alittle more speed.
        unsigned long 	unChangingDataPart;
        unsigned short cachedStation;        
		unsigned short controlReg;
		unsigned short reqDelay;
		unsigned short dacValue;
		unsigned short testGateWidth;
		unsigned short feraClrWidth;
		unsigned short histogramControl;
		unsigned short multiHistogram;
		unsigned short gateTimeOut;
		unsigned short busyEndDelay;
		unsigned short vsn;
		unsigned short ledAssigment;
		unsigned short outputSelection;
		unsigned short eventTimeout;
		unsigned short extRenInputSigSel;
		unsigned short pingPong;
		unsigned short histoBlockSize;
    unsigned short histogramMask;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (unsigned short) histogramMask;
- (void) setHistogramMask:(unsigned short)aHistogramMask;
- (unsigned short) histoBlockSize;
- (void) setHistoBlockSize:(unsigned short)aHistoBlockSize;
- (unsigned short) pingPong;
- (void) setPingPong:(unsigned short)aPingPong;
- (unsigned short) extRenInputSigSel;
- (void) setExtRenInputSigSel:(unsigned short)aExtRenInputSigSel;
- (unsigned short) eventTimeout;
- (void) setEventTimeout:(unsigned short)aEventTimeout;
- (unsigned short) outputSelection;
- (void) setOutputSelection:(unsigned short)aOutputSelection;
- (unsigned short) ledAssigment;
- (void) setLedAssigment:(unsigned short)aLedAssigment;
- (unsigned short) vsn;
- (void) setVsn:(unsigned short)aVsn;
- (unsigned short) busyEndDelay;
- (void) setBusyEndDelay:(unsigned short)aBusyEndDelay;
- (unsigned short) gateTimeOut;
- (void) setGateTimeOut:(unsigned short)aGateTimeOut;
- (unsigned short) multiHistogram;
- (void) setMultiHistogram:(unsigned short)aMultiHistogram;
- (unsigned short) histogramControl;
- (void) setHistogramControl:(unsigned short)aHistogramControl;
- (unsigned short) feraClrWidth;
- (void) setFeraClrWidth:(unsigned short)aFeraClrWidth;
- (unsigned short) testGateWidth;
- (void) setTestGateWidth:(unsigned short)aTestGateWidth;
- (unsigned short) dacValue;
- (void) setDacValue:(unsigned short)aDacValue;
- (unsigned short) reqDelay;
- (void) setReqDelay:(unsigned short)aReqDelay;
- (unsigned short) controlReg;
- (void) setControlReg:(unsigned short)aControlReg;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;

#pragma mark ¥¥¥Hardware Access
- (void) loadHardware;
- (void) readAndReport;
- (void) writeControlReg:(unsigned short)aValue;
- (unsigned short) readControlReg;
- (void) writeReqDelay:(unsigned short)aValue;
- (unsigned short) readReqDelay;
- (void) writeDacValue:(unsigned short)aValue;
- (unsigned short) readDacValue;
- (void) writeTestGateWidth:(unsigned short)aValue;
- (unsigned short) readTestGateWidth;
- (void) writeFeraClrWidth:(unsigned short)aValue;
- (unsigned short) readFeraClrWidth;
- (void) writeHistogramControl:(unsigned short)aValue;
- (unsigned short) readHistogramControl;
- (void) writeHistogramBlockSize:(unsigned short)aValue;
- (unsigned short) readHistogramBlockSize;
- (void) writeMultiHistogram:(unsigned short)aValue;
- (unsigned short) readMultiHistogram;
- (void) writeGateTimeOut:(unsigned short)aValue;
- (unsigned short) readGateTimeOut;
- (void) writeBusyEndDelay:(unsigned short)aValue;
- (unsigned short) readBusyEndDelay;
- (void) writeVsn:(unsigned short)aValue;
- (unsigned short) readVsn;
- (void) writePingPong:(unsigned short)aValue;
- (unsigned short) readPingPong;
- (void) writeLedAssigment:(unsigned short)aValue;
- (unsigned short) readLedAssigment;
- (void) writeOuputSel:(unsigned short)aValue;
- (unsigned short) readOuputSel;
- (void) writeEventTimeOut:(unsigned short)aValue;
- (unsigned short) readEventTimeOut;
- (void) writeExtRenInputSigSel:(unsigned short)aValue;
- (unsigned short) readExtRenInputSigSel;
- (void) writeHistogramMask:(unsigned short)aValue;
- (unsigned short) readHistogramMask;
- (void) writeHistogramSize:(unsigned short)aValue;
- (unsigned short) readHistogramSize;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORCMC203ModelHistogramMaskChanged;
extern NSString* ORCMC203ModelHistoBlockSizeChanged;
extern NSString* ORCMC203ModelPingPongChanged;
extern NSString* ORCMC203ModelExtRenInputSigSelChanged;
extern NSString* ORCMC203ModelEventTimeoutChanged;
extern NSString* ORCMC203ModelOutputSelectionChanged;
extern NSString* ORCMC203ModelLedAssigmentChanged;
extern NSString* ORCMC203ModelVsnChanged;
extern NSString* ORCMC203ModelBusyEndDelayChanged;
extern NSString* ORCMC203ModelGateTimeOutChanged;
extern NSString* ORCMC203ModelMultiHistogramChanged;
extern NSString* ORCMC203ModelHistogramControlChanged;
extern NSString* ORCMC203ModelFeraClrWidthChanged;
extern NSString* ORCMC203ModelTestGateWidthChanged;
extern NSString* ORCMC203ModelDacValueChanged;
extern NSString* ORCMC203ModelReqDelayChanged;
extern NSString* ORCMC203ModelControlRegChanged;
extern NSString* ORCMC203SettingsLock;
