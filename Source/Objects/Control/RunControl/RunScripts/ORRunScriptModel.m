//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORRunScriptModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

@implementation ORRunScriptModel

#pragma mark ***Initialization

- (void) connectionChanged
{
	[self setUpImage];
}

- (void) setUpImage
{
	// [self setImage:[NSImage imageNamed:@"RunScript"]];
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"RunScript"];
	
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSSize imageSize = [aCachedImage size];
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont labelFontOfSize:12], NSFontAttributeName,
								nil];		
	[[self identifier] drawInRect:NSMakeRect(30,-4, imageSize.width,imageSize.height) 
				   withAttributes:attributes];
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (void) setUniqueIdNumber:(unsigned long)anIdNumber
{
	[super setUniqueIdNumber:anIdNumber];
	[self setUpImage];
}

#pragma mark ***Data ID
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId        = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORDecoderRunScript",					@"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],           @"variable",
								 [NSNumber numberWithLong:3],            @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"runScript"];
    
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORRunScriptModel"];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	if([super inputValues]) [objDictionary setObject:inputValues forKey:@"inputValues"];
    if([super scriptName])  [objDictionary setObject:scriptName forKey:@"scriptName"];
    if([super lastFile]) [objDictionary setObject:lastFile forKey:@"lastFile"];
    [dictionary setObject:objDictionary forKey:@"RunScript"];
	return objDictionary;
}


- (void) setSelectorOK:(SEL)aSelectorOK bad:(SEL)aSelectorBAD withObject:(id)anObject target:(id)aTarget
{
	selectorOK	= aSelectorOK;
	selectorBAD	= aSelectorBAD;
	anArg		= [anObject retain];
	target		= [aTarget retain];
}

- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{
	[super scriptRunnerDidFinish:normalFinish returnValue:aValue];
	if(normalFinish){
		if([aValue intValue]!=0) [target performSelector:selectorOK withObject:anArg];
		else					 [target performSelector:selectorBAD withObject:nil];
	}
	else {
		[target performSelector:selectorBAD withObject:nil];
	}
	[anArg release];
	anArg = nil;
	[target release];
	target = nil;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

- (void) shipTaskRecord:(id)aTask running:(BOOL)aState
{
    if(dataId!= -1){
		unsigned long data[3];
		data[0] = dataId | 3; 
		data[1] = [self uniqueIdNumber]; 
		data[2] = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*3]];
    }
}
@end

@implementation ORDecoderRunScript
- (unsigned long) decodeData:(void*)someData  fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Script Task\n\n";
    NSString* state = [NSString stringWithFormat:    @"Task %d State = %@\n",ptr[1],ptr[2]?@"Started":@"Stopped"];
    return [NSString stringWithFormat:@"%@%@",title,state];               
}
@end

