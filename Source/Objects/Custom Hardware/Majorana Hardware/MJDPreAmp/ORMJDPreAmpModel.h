//
//  MJDPreAmpModel.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORHWWizard.h"
#import "ThresholdCalibrationTask.h"

#define kMJDPreAmpDacChannels   16	//if this ever changes, change the record length also
#define kMJDPreAmpDataRecordLen 21

@interface ORMJDPreAmpModel : OrcaObject {
    NSMutableArray* adcs;
    NSMutableArray* dacs;
    NSMutableArray* amplitudes;
    unsigned short pulserMask;
    int pulseLowTime;
    int pulseHighTime;
    BOOL attenuated[2];
    BOOL finalAttenuated[2];
    BOOL enabled[2];
    int adcRange[2];
    unsigned short pulseCount;
    BOOL loopForever;
    int pollTime;
    BOOL shipValues;
	unsigned long	dataId;
	unsigned long timeMeasured[2];
    unsigned long adcEnabledMask;
}

- (void) setUpArrays;

#pragma mark ¥¥¥Accessors
- (unsigned long) adcEnabledMask;
- (void) setAdcEnabledMask:(unsigned long)aAdcEnabledMask;
- (BOOL) shipValues;
- (void) setShipValues:(BOOL)aShipValues;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (NSMutableArray*) adcs;
- (void) setAdcs:(NSMutableArray*)aAdcs;
- (float) adc:(unsigned short) aChan;
- (void) setAdc:(int) aChan value:(float) aValue;
- (BOOL) loopForever;
- (void) setLoopForever:(BOOL)aLoopForever;
- (unsigned short) pulseCount;
- (void) setPulseCount:(unsigned short)aPulseCount;
- (BOOL) enabled:(int)index;
- (void) setEnabled:(int)index value:(BOOL)aEnabled;
- (int) adcRange:(int)index;
- (void) setAdcRange:(int)index value:(int)aValue;
- (unsigned long) timeMeasured:(int)index;

- (BOOL) attenuated:(int)index;
- (void) setAttenuated:(int)index value:(BOOL)aAttenuated;
- (BOOL) finalAttenuated:(int)index;
- (void) setFinalAttenuated:(int)index value:(BOOL)aAttenuated;
- (unsigned short) pulserMask;
- (void) setPulserMask:(unsigned short)aPulserMask;
- (int) pulseHighTime;
- (void) setPulseHighTime:(int)aPulseHighTime;
- (int) pulseLowTime;
- (void) setPulseLowTime:(int)aPulseLowTime;
- (NSMutableArray*) dacs;
- (void) setAmplitudes:(NSMutableArray*)anArray;
- (NSMutableArray*) amplitudes;
- (void) setDacs:(NSMutableArray*)anArray;
- (unsigned long) dac:(unsigned short) aChan;
- (void) setDac:(unsigned short) aChan withValue:(unsigned long) aValue;
- (unsigned long) amplitude:(int) aChan;
- (void) setAmplitude:(int) aChan withValue:(unsigned long) aValue;

#pragma mark ¥¥¥Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSDictionary*) dataRecordDescription;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObject;
- (void) shipRecords;


#pragma mark ¥¥¥HW Access
- (void) startPulser;
- (void) stopPulser;
- (void) writeFetVds:(int)index;
- (void) writeFetVdsToHW;
- (void) writeAmplitude:(int)index;
- (void) writeAmplitudes;
- (void) zeroAmplitudes;
- (void) writeRangeForAdcChip:(int)index;
- (void) writeAdcChipRanges;
- (void) readAdcsOnChip:(int)aChip;
- (void) readAdcs;
- (void) pollValues;
- (unsigned long) writeAuxIOSPI:(unsigned long)aValue;


#pragma mark ¥¥¥Archival
- (id)      initWithCoder:(NSCoder*)aDecoder;
- (void)    encodeWithCoder:(NSCoder*)anEncoder;
@end

#pragma mark ¥¥¥External Strings
extern NSString* ORMJDPreAmpModelAdcEnabledMaskChanged;
extern NSString*  ORMJDPreAmpModelPollTimeChanged;
extern NSString* ORMJDPreAmpModelShipValuesChanged;
extern NSString* ORMJDPreAmpAdcArrayChanged;
extern NSString* ORMJDPreAmpLoopForeverChanged;
extern NSString* ORMJDPreAmpPulseCountChanged;
extern NSString* ORMJDPreAmpEnabledChanged;
extern NSString* ORMJDPreAmpAttenuatedChanged;
extern NSString* ORMJDPreAmpFinalAttenuatedChanged;
extern NSString* ORMJDPreAmpPulserMaskChanged;
extern NSString* ORMJDPreAmpPulseHighTimeChanged;
extern NSString* ORMJDPreAmpPulseLowTimeChanged;
extern NSString* ORMJDPreAmpDacArrayChanged;
extern NSString* ORMJDPreAmpAmplitudeArrayChanged;
extern NSString* MJDPreAmpSettingsLock;
extern NSString* ORMJDPreAmpDacChanged;
extern NSString* ORMJDPreAmpAmplitudeChanged;
extern NSString* ORMJDPreAmpAdcChanged;
extern NSString* ORMJDPreAmpAdcRangeChanged;

@interface NSObject (ORMJDPreAmpModel)
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;
@end
