//
//  ORDetectorSegment.m
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


#import "ORDetectorSegment.h"
#import "ORCard.h"
#import "ORRate.h"
#import "ORRateGroup.h"

//sort type  
//  0 = int
//  1 = string
//  2 = float
static struct {
    NSString* key;
    int       sortType;
}kSegmentParam[kNumKeys] = {
	{ @"kSegmentNumber",	0},
	{ @"kCardSlot",			0},
	{ @"kChannel",			0},
};

NSString* KSegmentRateChangedNotification = @"KSegmentRateChangedNotification";

@implementation ORDetectorSegment

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super init];
	[self setParams:[NSMutableDictionary dictionary]];
	
	[self setObject:@"--" forKey:kSegmentParam[kCardSlot].key];
	[self setObject:@"--" forKey:kSegmentParam[kChannel].key];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [params release];
	[shape release];
	[errorShape release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors
- (BOOL) hardwarePresent
{
	return hardwareCard!=nil;
}

- (void) setShape:(NSBezierPath*)aPath
{
	[aPath retain];
	[shape release];
	shape = aPath;
}

- (void) setErrorShape:(NSBezierPath*)aPath
{
	[aPath retain];
	[errorShape release];
	errorShape = aPath;
}


- (short) threshold
{
	int channel = [[params objectForKey:kSegmentParam[kChannel].key] intValue];
	if(channel>=0) return [hardwareCard threshold:channel];
	else return 0;
}
- (void) setThreshold:(id)aValue
{
	if(!hardwareCard)return;
	id channel = [self objectForKey:@"kChannel"];
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[(NSObject*)hardwareCard methodSignatureForSelector:@selector(setThreshold:withValue:)]];
	[setter setSelector:@selector(setThreshold:withValue:)];
	[setter setTarget:hardwareCard];
	[setter setArgument:0  to:channel];
	[setter setArgument:1  to:aValue];
	[setter invoke];
	
}

- (short) gain
{
	int channel = [[params objectForKey:kSegmentParam[kChannel].key] intValue];
	if(channel>=0)return [hardwareCard gain:channel];
	else return 0;
}
- (void) setGain:(id)aValue
{
	if(!hardwareCard)return;
	id channel = [self objectForKey:@"kChannel"];
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[(NSObject*)hardwareCard methodSignatureForSelector:@selector(setGain:withValue:)]];
	[setter setSelector:@selector(setGain:withValue:)];
	[setter setTarget:hardwareCard];
	[setter setArgument:0  to:channel];
	[setter setArgument:1  to:aValue];
	[setter invoke];
	
}

- (BOOL) partOfEvent
{
	int channel = [[params objectForKey:kSegmentParam[kChannel].key] intValue];
	if(channel>=0)return [hardwareCard partOfEvent:channel];
	else return 0;
}


- (float) rate
{
    return rate;
}
- (void) setRate:(float)newRate
{
    rate=newRate;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KSegmentRateChangedNotification
                      object:self];
}

- (BOOL) segmentError
{
	return segmentError;
}

- (void) setSegmentError:(BOOL)state
{
	segmentError = state;
}
- (void) clearSegmentError
{
	segmentError = NO;
}
- (void) setSegmentError
{
	segmentError = YES;
}

- (BOOL) isValid
{
    return isValid;
}

- (void) setIsValid:(BOOL)newIsValid
{
    isValid=newIsValid;
}
- (NSMutableDictionary *) params
{
    return params;
}

- (void) setParams: (NSMutableDictionary *) aParams
{
	[aParams retain];
    [params release];
    params = aParams;
}

- (void) decodeLine:(NSString*)aString
{
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    NSArray* items = [aString componentsSeparatedByString:@","];
    int i;
    int count = [items count];
	if(count == 5){
		//old format
		int x = [[items objectAtIndex:0] intValue];
		int y = [[items objectAtIndex:1] intValue];
		[params setObject:[NSNumber numberWithInt:x + (y*8)] forKey:kSegmentParam[0].key];
		[params setObject:[items objectAtIndex:2] forKey:kSegmentParam[1].key];
		[params setObject:[items objectAtIndex:3] forKey:kSegmentParam[2].key];
		isValid = YES;
	}
	else {
		if(count<=kNumKeys){
			for(i=0;i<count;i++){
				[params setObject:[items objectAtIndex:i] forKey:kSegmentParam[i].key];
			}
			isValid = YES;
		}
    }
    
}

- (NSString*) paramsAsString
{
	NSString* result = [NSString string];
	int i;
	for(i=0;i<kNumKeys;i++){
		id aParam = [params objectForKey:kSegmentParam[i].key];
		if(aParam) result = [result stringByAppendingFormat:@"%@",aParam];
		else result = [result stringByAppendingString:@"0"];
		if(i<kNumKeys-1)result = [result stringByAppendingString:@","];
	}
	return result;
}

- (BOOL) online
{
	return online;
}
- (BOOL) hwPresent
{
	return hwPresent;
}


- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}
- (id) hardwareCard
{
	return hardwareCard;
}

- (NSString*) hardwareClassName
{
	return [(NSObject*)hardwareCard className];
}

- (int) cardSlot
{
	NSNumber* num = [self objectForKey:kSegmentParam[kCardSlot].key];
	if(!num)return -1;
	else return [num intValue];
}

- (int) channel
{
	NSString* s = [self objectForKey:kSegmentParam[kChannel].key];
	if([s isEqualToString:@"--"])return -1;
	else if(!s)return -1;
	else return [s intValue];
}


-(id) objectForKey:(id)key
{
	if([key isEqualToString:@"threshold"]){
		if(hardwareCard) return [NSNumber numberWithInt:[self threshold]];
		else return @"--";
	}
	else if([key isEqualToString:@"gain"]){
		if(hardwareCard) return [NSNumber numberWithInt:[self gain]];
		else return @"--";
	}
	else {
		id obj =  [params objectForKey:key];
		if(!obj)					return @"--";
		else if([obj intValue]<0)	return @"--";
		else						return obj;
	}
}

-(void) setObject:(id)obj forKey:(id)key
{
    [[[self undoManager] prepareWithInvocationTarget:self] setObject:[params objectForKey:key] forKey:key];
    
    [params setObject:obj forKey:key];
    
	//    [[NSNotificationCenter defaultCenter]
	//        postNotificationName:KPixelParamChangedNotification
	//                      object:self];
    
}

- (void) setSegmentNumber:(unsigned)index
{
	[params setObject:[NSNumber numberWithInt:index] forKey:@"kSegmentNumber"];
}
- (unsigned) segmentNumber
{
	return [[params objectForKey:@"kSegmentNumber"] intValue];
}

- (void) unregisterRates
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) rateChanged:(NSNotification*)note
{
	int channel = [[params objectForKey:@"kChannel"] intValue];
    float r = [[note object] rate:channel];
    if(r != rate)[self setRate:r];
}

- (void) registerForRates:(NSArray*)rateProviders
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver : self];
	
    NSEnumerator* e = [rateProviders objectEnumerator];
    ORCard* aCard;
    while(aCard = [e nextObject]){
		int theSlot = [[params objectForKey: kSegmentParam[kCardSlot].key]intValue];
		if(theSlot >=0){
			if( theSlot == [aCard displayedSlotNumber]){
				
				id rateObj = [aCard rateObject:[[params objectForKey: kSegmentParam[kChannel].key]intValue]];
				[notifyCenter addObserver : self
								 selector : @selector(rateChanged:)
									 name : [rateObj rateNotification]
								   object : rateObj];
				break;
			}
        }
    }
}


- (void) configurationChanged:(NSArray*)adcCards
{
	int card;
	
	//assume the worst
	hwPresent = NO;
	online = NO;
	hardwareCard = nil;
	for(card = 0;card<[adcCards count];card++){
		id aCard = [adcCards objectAtIndex:card];
		if(!aCard)break;
		int theSlot = [[params objectForKey: kSegmentParam[kCardSlot].key]intValue];
		if(theSlot>=0){
			if([aCard displayedSlotNumber] == theSlot){
				hwPresent = YES;
				int chan = [[params objectForKey: kSegmentParam[kChannel].key]intValue];
				if([aCard onlineMaskBit:chan])online = YES;
				hardwareCard = aCard;
				break;
			}
		}
	}
}

- (void) showDialog
{
	[hardwareCard makeMainController];
}

- (id) description
{		
	NSString* string = [NSString stringWithFormat:@"Segment  : %d\n",[self segmentNumber]];
	string = [string stringByAppendingFormat:   @"Adc Class: %@\n",[(NSObject*)hardwareCard className]];
	string = [string stringByAppendingFormat:   @"Slot     : %d\n",[self cardSlot]];
	string = [string stringByAppendingFormat:   @"Channel  : %d\n",[self channel]];
	string = [string stringByAppendingFormat:   @"Threshold: %d\n",[self threshold]];
	string = [string stringByAppendingFormat:   @"Gain     : %d\n",[self gain]];
	return string;
}


#pragma mark ¥¥¥Achival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setIsValid:[decoder decodeBoolForKey:@"SegmentIsValid"]];
    [self setParams:[decoder decodeObjectForKey:@"SegmentParams"]];
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeBool:isValid forKey:@"SegmentIsValid"];
    [encoder encodeObject:params forKey:@"SegmentParams"];
}

@end
