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

NSString* ORUVChnlEnabledChanged			= @"ORUVChnlEnabledChanged";
NSString* ORUVChnlDemandHVChanged			= @"ORUVChnlDemandHVChanged";
NSString* ORUVChnlMeasuredHVChanged			= @"ORUVChnlMeasuredHVChanged";
NSString* ORUVChnlMeasuredCurrentChanged	= @"ORUVChnlMeasuredCurrentChanged";
NSString* ORUVChnlTripCurrentChanged		= @"ORUVChnlTripCurrentChanged";
NSString* ORUVChnlRampUpRateChanged			= @"ORUVChnlRampUpRateChanged";
NSString* ORUVChnlRampDownRateChanged		= @"ORUVChnlRampDownRateChanged";
NSString* ORUVChnlMVDZChanged				= @"ORUVChnlMVDZChanged";
NSString* ORUVChnlMCDZChanged				= @"ORUVChnlMCDZChanged";
NSString* ORUVChnlHVLimitChanged			= @"ORUVChnlHVLimitChanged";

//NSString* ORUVChnlSlotChanged				= @"ORUVChnlSlotChanged";

// HV Unit parameters
NSString* ORHVkChnlEnabled = @"chnlEnabled";
NSString* ORHVkMeasuredCurrent = @"measuredCurrent";
NSString* ORHVkMeasuredHV = @"measuredHV";
NSString* ORHVkDemandHV = @"demandHV";
NSString* ORHVkRampUpRate = @"RampUpRate";
NSString* ORHVkRampDownRate = @"RampDownRate";
NSString* ORHVkTripCurrent = @"tripCurrent";
NSString* ORHVkStatus = @"Status";
NSString* ORHVkMVDZ = @"MVDZ";
NSString* ORHVkMCDZ = @"MCDZ";
NSString* ORHVkHVLimit = @"HVLimit";


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
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlEnabledChanged object: self];		
}

- (float) demandHV: (int) aChnl
{
	NSDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	
	return ( [[tmpChnl objectForKey: ORHVkDemandHV] floatValue] );
}

- (void) setDemandHV: (float) aDemandHV chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* demandHV = [NSNumber numberWithFloat: aDemandHV];
	[tmpChnl setObject: demandHV forKey: ORHVkDemandHV];
	
	// Put specific code here to talk with unit.
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlDemandHVChanged object: self];	
}

- (float) measuredCurrent: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: ORHVkMeasuredCurrent] floatValue] );
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
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* tripCurrent = [NSNumber numberWithFloat: aTripCurrent];
	[tmpChnl setObject: tripCurrent forKey: ORHVkTripCurrent];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlTripCurrentChanged object: self];	
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
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampUpRate = [NSNumber numberWithFloat: aRampUpRate];
	[tmpChnl setObject: rampUpRate forKey: ORHVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlRampUpRateChanged object: self];	
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
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampDownRate = [NSNumber numberWithFloat: aRampDownRate];
	[tmpChnl setObject: rampDownRate forKey: ORHVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlRampDownRateChanged object: self];	
}

- (NSString*) status: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSString* status = [tmpChnl objectForKey: ORHVkStatus];
	[status autorelease];
	return( status );
}

- (float) MVDZ: (int) aCurChannel
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: ORHVkMVDZ] floatValue] );
}

- (void) setMVDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* hvWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: hvWindow forKey: ORHVkMVDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlMVDZChanged object: self];	
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
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* chargeWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: chargeWindow forKey: ORHVkMCDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: ORUVChnlMCDZChanged object: self];	
}

- (float) HVLimit: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: ORHVkHVLimit] floatValue] );
}

- (void) getValues: (int ) aCurChannel
{
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
		
		// Put in dummy values for testing.
		for(i=0 ; i<ORHVNumChannels; i++ )
		{
			NSNumber* chnl = [NSNumber numberWithInt: i];
			NSNumber* measuredCurrent = [NSNumber numberWithFloat: ((float)i * 1.0)];
			NSNumber* measuredHV = [NSNumber numberWithFloat: (1000.0 + 10.0 * (float)i)];
			NSNumber* demandHV = [NSNumber numberWithFloat: (2000.0 + (float) i)];
			NSNumber* rampUpRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* rampDownRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* tripCurrent = [NSNumber numberWithFloat: 2550.0];
			NSString* status = [NSString stringWithString: @"enabled"];
			NSNumber* enabled = [NSNumber numberWithInt: 1];
			NSNumber* MVDZ = [NSNumber numberWithFloat: 1.5];
			NSNumber* MCDZ = [NSNumber numberWithFloat: 1.3];
			NSNumber* HVLimit = [NSNumber numberWithFloat: 1580.0];
			
			NSMutableDictionary* tmpChnl = [NSMutableDictionary dictionaryWithCapacity: 9];
			
			[tmpChnl setObject: chnl forKey: @"channel"];
			[tmpChnl setObject: measuredCurrent forKey: ORHVkMeasuredCurrent];
			[tmpChnl setObject: measuredHV forKey: ORHVkMeasuredHV];
			[tmpChnl setObject: demandHV forKey: ORHVkDemandHV];
			[tmpChnl setObject: tripCurrent	forKey: ORHVkTripCurrent];
			[tmpChnl setObject: enabled forKey: ORHVkChnlEnabled];
			[tmpChnl setObject: rampUpRate forKey: ORHVkRampUpRate];			
			[tmpChnl setObject: rampDownRate forKey: ORHVkRampDownRate];
			[tmpChnl setObject: status forKey: ORHVkStatus];
			[tmpChnl setObject: MVDZ forKey: ORHVkMVDZ];			
			[tmpChnl setObject: MCDZ forKey: ORHVkMCDZ];
			[tmpChnl setObject: HVLimit forKey: ORHVkHVLimit];			

			[tmpChnl setObject: status forKey: ORHVkStatus];
			
			[mChannelArray insertObject: tmpChnl atIndex: i];
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
- (void) interpretReturn: (NSString* ) aRawData dataStore: (NSMutableDictionary* ) aDataStore
{
	
	if ( [aRawData length] )
	{
		NSString*	values[ ORUVChnlNumParameters ];
		NSScanner* scanner = [NSScanner scannerWithString: aRawData];
		NSCharacterSet* blankSet = [NSCharacterSet characterSetWithCharactersInString: @" "];
		int i = 0;
		for ( i = 0; i < ORUVChnlNumParameters; i++ )
		{
			[scanner scanUpToCharactersFromSet: blankSet intoString: &values[ i ]];
			[scanner setScanLocation: [scanner scanLocation] + 1];

		}
	}
//	[scanner setCharactersToBeSkipped: newlineCharacterSet];

}

- (void) printDictionary: (int) aCurrentChnl
{
	NSDictionary*	tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	float			valuef;
	NSString* 		values;
	
	NSLog( @"Channel: %d\n", aCurrentChnl);
	
	valuef = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"Measured Current: %f\n", [tmpChnl objectForKey: ORHVkMeasuredCurrent] );

	valuef = [[tmpChnl objectForKey: ORHVkMeasuredCurrent] floatValue];
	NSLog( @"Measured HV: %g\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkMeasuredHV] floatValue];
	NSLog( @"Demand HV: %g\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkDemandHV] floatValue];
	NSLog( @"RampUpRate: %f\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkRampDownRate] floatValue];
	NSLog( @"RampDownRate: %f\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkTripCurrent] floatValue];
	NSLog( @"Trip current: %f\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkChnlEnabled] floatValue];
	NSLog( @"Trip current: %f\n", valuef );

	values = [tmpChnl objectForKey: ORHVkStatus];
	NSLog( @"Status: %@\n", values );
	
	valuef = [[tmpChnl objectForKey: ORHVkMCDZ] floatValue];
	NSLog( @"MVDZ: %f\n", valuef );
	
	valuef = [[tmpChnl objectForKey: ORHVkMCDZ] floatValue];
	NSLog( @"MCDZ: %f\n", valuef );

	valuef = [[tmpChnl objectForKey: ORHVkHVLimit] floatValue];
	NSLog( @"MCDZ: %f\n", valuef );	
}


@end
