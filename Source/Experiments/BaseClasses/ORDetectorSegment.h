//
//  ORDetectorSegment.h
//  Orca
//
//  Created by Mark Howe on 11/27/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORAdcInfoProviding.h"

#define  kSegmentNumber 0
#define  kCardSlot		1   
#define  kChannel		2
#define	 kName			3  

@interface ORDetectorSegment : NSObject
{
	NSMutableDictionary*	params;
	BOOL					isValid;
	float					rate;
	BOOL					hwPresent;
	BOOL					online;
	BOOL					segmentError;
	NSBezierPath*			shape;
	NSBezierPath*			errorShape;
	id<ORAdcInfoProviding>	hardwareCard;
	NSArray*				mapEntries;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (void) setMapEntries:(NSArray*)someMapEntries;
- (NSArray*) mapEntries;
-(id) mapEntry:(int)index forKey:(id)aKey;
- (id) description;
- (NSString*) name;
- (id) hardwareCard;
- (void) setShape:(NSBezierPath*)aPath;
- (void) setErrorShape:(NSBezierPath*)aPath;
- (BOOL) online;
- (BOOL) hwPresent;
- (void) setHwPresent:(BOOL)state;
- (BOOL) isValid;
- (void) setIsValid:(BOOL)newIsValid;
- (NSMutableDictionary *) params;
- (void) setParams: (NSMutableDictionary *) aParams;
- (void) decodeLine:(NSString*)aString;
- (NSString*) paramsAsString;
- (NSUndoManager*) undoManager;
- (id) objectForKey:(id)key;
- (void) setObject:(id)obj forKey:(id)key;
- (void) setSegmentNumber:(unsigned)index;
- (unsigned) segmentNumber;
- (BOOL) segmentError;
- (void) setSegmentError:(BOOL)state;
- (void) clearSegmentError;
- (void) setSegmentError;
- (short) threshold;
- (void) setGain:(id)aValue;
- (void) setThreshold:(id)aValue;
- (short) gain;
- (float) rate;
- (void) setRate:(float)newRate;
- (void) registerForRates:(NSArray*)rateProviders;
- (void) unregisterRates;
- (void) rateChanged:(NSNotification*)note;
- (void) showDialog;
- (NSString*) hardwareClassName;
- (int) cardSlot;
- (int) channel;
- (void) configurationChanged:(NSArray*)adcCards;
- (BOOL) hardwarePresent;
- (BOOL) partOfEvent;

#pragma mark ¥¥¥Achival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;


@end

extern NSString* KSegmentRateChangedNotification;