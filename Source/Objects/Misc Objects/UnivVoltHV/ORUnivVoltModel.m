//
//  ORUnivVoltModel.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORUnivVoltModel.h"
#import "NetSocket.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORQueue.h"

NSString* ORUVUnitEnabledChanged			= @"ORUVUnitEnabledChanged";
NSString* ORUVUnitDemandHVChanged			= @"ORUVUnitDemandHVChanged";
NSString* ORUVUnitMeasuredHVChanged			= @"ORUVUnitMeasuredHVChanged";
NSString* ORUVUnitMeasuredCurrentChanged	= @"ORUVUnitMeasuredCurrentChanged";
NSString* ORUVUnitTripCurrentChanged		= @"ORUVUnitTripCurrentChanged";
NSString* ORUVUnitRampUpRateChanged			= @"ORUVUnitRampUpRateChanged";
NSString* ORUVUnitRampDownRateChanged		= @"ORUVUnitRampDownRateChanged";
NSString* ORUVUnitMVDZChanged				= @"ORUVUnitMVDZChanged";
NSString* ORUVUnitMCDZChanged				= @"ORUVUnitMCDZChanged";

//NSString* ORUVUnitSlotChanged				= @"ORUVUnitSlotChanged";

// HV Unit parameters
NSString* ORHVkChnlEnabled = @"chnlEnabled";
NSString* ORHVkDemandHV = @"demandHV";
NSString* ORHVkMeasuredHV = @"measuredHV";
NSString* ORHVkMeasuredCurrent = @"measuredCurrent";
NSString* ORHVkTripCurrent = @"tripCurrent";
NSString* ORHVkRampUpRate = @"RampUpRate";
NSString* ORHVkRampDownRate = @"RampDownRate";
NSString* ORHVkStatus = @"Status";
NSString* ORHVkMVDZ = @"MVDZ";
NSString* ORHVkMCDZ = @"MCDZ";



@implementation ORUnivVoltModel
#pragma mark •••Init/Dealloc
/*- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}
*/
- (Class) guardianClass 
{
	return NSClassFromString(@"ORUnivVoltHVCrateModel");
}

- (void) makeMainController
{
    [self linkToController: @"ORUnivVoltController"];
}

- (void) dealloc
{
//	[socket close];
//	[socket release];
//	[meterData release];
	
//	int i;
//	for(i=0;i<kNplpCNumChannels;i++) [dataStack[i] release];
	
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
	
//		int i;
//		for(i = 0; i < kNplpCNumChannels; i++) dataStack[i] = [[ORQueue alloc] init];
		
	NS_HANDLER
	NS_ENDHANDLER
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"UnivVoltHVIcon"]];
}

#pragma mark ***Accessors
- (NSMutableArray*) channelArray
{
	return( mChannelArray );
}

- (void) setChannelArray: (NSMutableArray*) anArray
{
	[anArray retain];
	[mChannelArray release];
	mChannelArray = anArray;
}

- (NSMutableDictionary*) channelDictionary: (int) aCurrentChnl
{
	return( [mChannelArray objectAtIndex: aCurrentChnl] );
}

- (int) chnlEnabled: (int) aCurrentChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	return( [[tmpChnl objectForKey: ORHVkChnlEnabled] intValue] );
}

- (void) setChannelEnabled: (int) anEnabled chnl: (int) aCurrentChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	NSNumber* enabledNumber = [NSNumber numberWithInt: anEnabled];
	[tmpChnl setObject: enabledNumber forKey: enabledNumber];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitEnabledChanged object: self];		
}

- (float) demandHV: (int) aChnl
{
	NSDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	
	return ( [[tmpChnl objectForKey: ORHVkDemandHV] floatValue] );
}

- (void) setDemandHV: (float) aDemandHV chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* demandHV = [NSNumber numberWithFloat: aDemandHV];
	[tmpUnit setObject: demandHV forKey: ORHVkDemandHV];
	
	// Put specific code here to talk with unit.
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitDemandHVChanged object: self];	
}


- (float) measuredHV: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkDemandHV] floatValue] );
}

- (float) tripCurrent: (int) aChnl
{
	// Send command to get trip current
	//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkTripCurrent] floatValue] );
}

- (void) setTripCurrent: (float) aTripCurrent chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* tripCurrent = [NSNumber numberWithFloat: aTripCurrent];
	[tmpUnit setObject: tripCurrent forKey: ORHVkTripCurrent];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitTripCurrentChanged object: self];	
}

- (float) rampUpRate: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkRampUpRate] floatValue] );
}

- (void) setRampUpRate: (float) aRampUpRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampUpRate = [NSNumber numberWithFloat: aRampUpRate];
	[tmpUnit setObject: rampUpRate forKey: ORHVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitRampUpRateChanged object: self];	
}



- (float) rampDownRate: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkRampDownRate] floatValue] );
}

- (void) setRampDownRate: (float) aRampDownRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampDownRate = [NSNumber numberWithFloat: aRampDownRate];
	[tmpUnit setObject: rampDownRate forKey: ORHVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitRampDownRateChanged object: self];	
}


- (float) MVDZ: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkMVDZ] floatValue] );
}

- (void) setMVDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* hvWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpUnit setObject: hvWindow forKey: ORHVkMVDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitMVDZChanged object: self];	
}
- (float) MCDZ: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkMCDZ] floatValue] );
}

- (void) setMCDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpUnit = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* chargeWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpUnit setObject: chargeWindow forKey: ORHVkMCDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVUnitMCDZChanged object: self];	
}

#pragma mark ***Delegate Methods

/*
#pragma mark •••Data Records
- (unsigned long) dataId
{
	return dataId;
}

- (void) setDataId: (unsigned long) aDataId
{
	dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NplpCMeter"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORUnivVoltDecoder",					@"decoder",
        [NSNumber numberWithLong:dataId],       @"dataId",
        [NSNumber numberWithBool:YES],          @"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"NplpCMeter"];
    
    return dataDictionary;
}

- (void) shipValues
{
	if(meterData){
	
		unsigned int numBytes = [meterData length];
		if(numBytes%4 == 0) {											//OK, we know we got a integer number of long words
			if([self validateMeterData]){
				unsigned long data[1003];									//max buffer size is 1000 data words + ORCA header
				unsigned int numLongsToShip = numBytes/sizeof(long);		//convert size to longs
				numLongsToShip = numLongsToShip<1000?numLongsToShip:1000;	//don't exceed the data array
				data[0] = dataId | (3 + numLongsToShip);					//first word is ORCA id and size
				data[1] =  [self uniqueIdNumber]&0xf;						//second word is device number
				
				//get the time(UT!)
				time_t	theTime;
				time(&theTime);
				struct tm* theTimeGMTAsStruct = gmtime(&theTime);
				time_t ut_time = mktime(theTimeGMTAsStruct);
				data[2] = ut_time;											//third word is seconds since 1970 (UT)
				
				unsigned long* p = (unsigned long*)[meterData bytes];
				
				int i;
				for(i=0;i<numLongsToShip;i++){
					p[i] = CFSwapInt32BigToHost(p[i]);
					data[3+i] = p[i];
					int chan = (p[i] & 0x00600000) >> 21;
					if(chan < kNplpCNumChannels) [dataStack[chan] enqueue: [NSNumber numberWithLong:p[i] & 0x000fffff]];
				}
				
				[self averageMeterData];
				
				if(numLongsToShip*sizeof(long) == numBytes){
					//OK, shipped it all
					[meterData release];
					meterData = nil;
				}
				else {
					//only part of the record was shipped, zero the part that was and keep the part that wasn't
					[meterData replaceBytesInRange:NSMakeRange(0,numLongsToShip*sizeof(long)) withBytes:nil length:0];
				}
				
				if([gOrcaGlobals runInProgress] && numBytes>0){
					[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:(3+numLongsToShip)*sizeof(long)]];
				}
				[self setReceiveCount: receiveCount + numLongsToShip];
			}
			
			else {
				[meterData release];
				meterData = nil;
				[self setFrameError:frameError+1];
			}
		}
	}
}

*/
#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setChannelArray: [decoder decodeObjectForKey: @"channelArray"]];
	
	if( !mChannelArray ){
		//first time.... set up the structure....
		[self setChannelArray: [NSMutableArray array]];
		int i;
		for(i=0 ; i<ORHVNumChannels; i++ )
		{
			[mChannelArray addObject: [NSMutableDictionary dictionary]];
		}
	}
	
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void) encodeWithCoder: (NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject: @"mChannelArray"];
}

#pragma mark •••Utilities
- (void) printDictionary: (int) aCurrentChnl
{
	NSDictionary*	tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	float			value;
	
	value = [[tmpChnl objectForKey: ORHVkDemandHV] floatValue];
	NSLog( @"Demand HV: %g", value );
	value = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"Measured HV: %g", value );
	value = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"Measured Current: %f", [tmpChnl objectForKey: ORHVkMeasuredCurrent] );
	value = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"Trip current: %f", [tmpChnl objectForKey: ORHVkTripCurrent] );
	value = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"RampUpRate: %f", [tmpChnl objectForKey: ORHVkRampUpRate] );
	value = [[tmpChnl objectForKey: ORHVkRampDownRate] floatValue];
	NSLog( @"RampDownRate: %f", value );
	value = [[tmpChnl objectForKey: ORHVkStatus] floatValue];
	NSLog( @"Status: %d", value );
	value = [[tmpChnl objectForKey: ORHVkMCDZ] floatValue];
	NSLog( @"MVDZ: %f", value );
	value = [[tmpChnl objectForKey: ORHVkMCDZ] floatValue];
	NSLog( @"MCDZ: %f", value );
}


@end
