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
#import <Cocoa/Cocoa.h>
#import "ORRunScriptModel.h"
#import "ORScriptRunner.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

NSString* ORRunScriptModelCommentsChanged = @"ORRunScriptModelCommentsChanged";
NSString* ORRunScriptModelShowSuperClassChanged = @"ORRunScriptModelShowSuperClassChanged";
NSString* ORRunScriptScriptChanged			= @"ORRunScriptScriptChanged";
NSString* ORRunScriptNameChanged			= @"ORRunScriptNameChanged";
NSString* ORRunScriptArgsChanged			= @"ORRunScriptArgsChanged";
NSString* ORRunScriptLastFileChangedChanged = @"ORRunScriptLastFileChangedChanged";
NSString* ORRunScriptLock					= @"ORRunScriptLock";

@implementation ORRunScriptModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
    [comments release];
	[scriptName release];
	[inputValues release];
	[scriptRunner release];
    [super dealloc];
}

-(void)makeMainController
{
    [self linkToController:@"ORRunScriptController"];
}

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

#pragma mark ***Accessors

- (NSString*) comments
{
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments)aComments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunScriptModelCommentsChanged object:self];
}

- (BOOL) showSuperClass
{
    return showSuperClass;
}

- (void) setShowSuperClass:(BOOL)aShowSuperClass
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowSuperClass:showSuperClass];
    
    showSuperClass = aShowSuperClass;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunScriptModelShowSuperClassChanged object:self];
}

- (NSString*) lastFile
{
	return lastFile;
}

- (void) setLastFile:(NSString*)aFile
{
	if(!aFile)aFile = [[NSHomeDirectory() stringByAppendingPathComponent:@"Untitled"] stringByExpandingTildeInPath];
	[[[self undoManager] prepareWithInvocationTarget:self] setLastFile:lastFile];
    [lastFile autorelease];
    lastFile = [aFile copy];		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunScriptLastFileChangedChanged object:self];
}

- (NSString*) script
{
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunScriptScriptChanged object:self];
}

- (void) setScriptNoNote:(NSString*)aString
{
    [script autorelease];
    script = [aString copy];	
}

- (NSString*) scriptName
{
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
	if(!aString)aString = @"OrcaScript";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptName:scriptName];
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunScriptNameChanged object:self];
	[self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ %d",[self scriptName],[self uniqueIdNumber]];
}

- (NSMutableArray*) inputValues
{
	return inputValues;
}

- (void) addInputValue
{
	if(!inputValues)inputValues = [[NSMutableArray array] retain];
	[inputValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"$%d",[inputValues count]],	@"name",
							[NSDecimalNumber numberWithUnsignedLong:0],				@"iValue",
							nil]];
	
}

- (void) removeInputValue:(int)i
{
	[inputValues removeObjectAtIndex:i];
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
	if(inputValues) [objDictionary setObject:inputValues forKey:@"inputValues"];
    if(scriptName)  [objDictionary setObject:scriptName forKey:@"scriptName"];
    if(lastFile) [objDictionary setObject:lastFile forKey:@"lastFile"];
    [dictionary setObject:objDictionary forKey:@"RunScript"];
	return objDictionary;
}

#pragma mark ***Script Methods
- (ORScriptRunner*) scriptRunner
{
	return scriptRunner;
}

- (BOOL) parsedOK
{
	return parsedOK;
}

- (BOOL) scriptExists
{
	return scriptExists;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		scriptExists = [scriptRunner scriptExists];
		if(([[NSApp currentEvent] modifierFlags] & 0x80000)>0){
			//option key is down
			[scriptRunner printAll];
		}
		[scriptRunner release];
		scriptRunner = nil;
	}
}

- (void) runScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		if(parsedOK){
			if([scriptRunner scriptExists]){
				[scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
				[scriptRunner run:inputValues sender:self];
			}
			else {
				[self scriptRunnerDidFinish:YES returnValue:[NSNumber numberWithInt:1]];
			}
		}
	}
	else {
		[scriptRunner stop];
		[scriptRunner release];
		scriptRunner = nil;
	}
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
	if(normalFinish){
		NSLog(@"[%@] Returned with: %@\n",[self identifier],aValue);
		if([aValue intValue]!=0) [target performSelector:selectorOK withObject:anArg];
		else					 [target performSelector:selectorBAD withObject:nil];
	}
	else {
		NSLogColor([NSColor redColor],@"[%@] Abnormal exit!\n",[scriptRunner scriptName]);
		[target performSelector:selectorBAD withObject:nil];
	}
	[anArg release];
	anArg = nil;
	[target release];
	target = nil;
}

- (void) stopScript
{
	[scriptRunner stop];
	[scriptRunner release];
	scriptRunner = nil;
}

- (BOOL) running
{
	return [scriptRunner running];
}

- (void) loadScriptFromFile:(NSString*)aFilePath
{
	[self setLastFile:aFilePath];
	[self setScript:[NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath]]];
}

- (void) saveFile
{
	[self saveScriptToFile:lastFile];
}

- (void) saveScriptToFile:(NSString*)aFilePath
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[aFilePath stringByExpandingTildeInPath]]){
		[fm removeFileAtPath:[aFilePath stringByExpandingTildeInPath] handler:nil];
	}
	NSData* theData = [script dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:[aFilePath stringByExpandingTildeInPath] contents:theData attributes:nil];
	[self setLastFile:aFilePath];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setComments:[decoder decodeObjectForKey:@"ORRunScriptModelComments"]];
    [self setShowSuperClass:[decoder decodeBoolForKey:@"showSuperClass"]];
    [self setScript:[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    inputValues = [[decoder decodeObjectForKey:@"inputValues"] retain];	
    [[self undoManager] enableUndoRegistration];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:comments forKey:@"ORRunScriptModelComments"];
    [encoder encodeBool:showSuperClass forKey:@"showSuperClass"];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:inputValues forKey:@"inputValues"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
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

