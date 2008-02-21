//
//  ORIP320Channel.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 23 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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




@class ORAlarm;

#pragma mark ***Param Keys
#define k320ChannelKey @"k320ChannelKey"
#define k320ChannelReadEnabled @"k320ChannelReadEnabled"
#define k320ChannelValue @"k320ChannelValue"
#define k320ChannelRawValue @"k320ChannelRawValue"
#define k320ChannelGain @"k320ChannelGain"
#define k320ChannelMode @"k320ChannelMode"
#define k320ChannelUnits @"k320ChannelUnits"
#define k320ChannelSlope @"k320ChannelSlope"
#define k320ChannelIntercept @"k320ChannelIntercept"
#define k320ChannelAlarmEnabled @"k320ChannelAlarmEnabled"
#define k320ChannelLowValue @"k320ChannelLowValue"
#define k320ChannelHighValue @"k320ChannelHighValue"

@interface ORIP320Channel : NSObject {
	id			adcCard;
    NSMutableDictionary* parameters;
	ORAlarm*	lowAlarm;
	ORAlarm*	highAlarm;
	double		maxValue;
	int			rawValue;
}
- (id) initWithAdc:(id)anAdcCard channel:(unsigned short)aChannel;

- (NSMutableDictionary *)parameters;
- (void) setParameters:(NSMutableDictionary *)aParameters;
- (id)   objectForKey:(id)aKey;
- (void) unableToSetNilForKey:(NSString*)aKey;
- (void) setObject:(id)obj forKey:(id)aKey;
- (void) checkAlarm;
- (int)  mode;
- (int)  gain;
- (int)  channel;
- (BOOL) readEnabled;
- (BOOL) setChannelValue:(int)aValue;
- (void) checkDefaults;
- (double) maxValue;
- (int) rawValue;
@end

@interface NSObject (IP320Card)
- (NSString*) processingTitle;
@end
