//
//  ORFilterModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
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
#import "ORFilterModel.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORFilterSymbolTable.h"
#import "FilterScript.h"
#import "ORDataTypeAssigner.h"
#import "ORQueue.h"

static NSString* ORFilterInConnector 		= @"Filter In Connector";
static NSString* ORFilterOutConnector 		= @"Filter Out Connector";
static NSString* ORFilterFilteredConnector  = @"Filtered Out Connector";

NSString* ORFilterLastFileChanged			= @"ORFilterLastFileChanged";
NSString* ORFilterNameChanged				= @"ORFilterNameChanged";
NSString* ORFilterArgsChanged				= @"ORFilterArgsChanged";
NSString* ORFilterDisplayValuesChanged		= @"ORFilterDisplayValuesChanged";
NSString* ORFilterBreakChainChanged			= @"ORFilterBreakChainChanged";
NSString* ORFilterLastFileChangedChanged	= @"ORFilterLastFileChangedChanged";
NSString* ORFilterScriptChanged				= @"ORFilterScriptChanged";
NSString* ORFilterTimerEnabledChanged		= @"ORFilterTimerEnabledChanged";
NSString* ORFilterUpdateTiming				= @"ORFilterUpdateTiming";
NSString* ORFilterLock                      = @"ORFilterLock";

//========================================================================
#pragma mark •••YACC interface
#import "OrcaScript.tab.h"
extern void resetFilterState();
extern void FilterScriptrestart();
extern int FilterScriptparse();
extern void freeNode(nodeType *p);
extern void startFilterScript(id delegate);
extern void runFilterScript(id delegate);
extern void finishFilterScript(id delegate);

extern long startFilterNodeCount;
extern nodeType** startFilterNodes;
extern long filterNodeCount;
extern nodeType** filterNodes;
extern long finishFilterNodeCount;
extern nodeType** finishFilterNodes;

extern long numFilterLines;
extern int graphNumber;
extern BOOL parsedSuccessfully;
extern ORFilterSymbolTable* symbolTable;

ORFilterModel* theFilterRunner = nil;
int FilterScriptYYINPUT(char* theBuffer,int maxSize) 
{
	return [theFilterRunner yyinputToBuffer:theBuffer withSize:maxSize];
}
int ex(nodeType*, id);
int filterGraph(nodeType*);
//========================================================================

@interface ORFilterModel (private)
- (void) loadDataIDsIntoSymbolTable:(ORDataPacket*)aDataPacket;
@end

@implementation ORFilterModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
        
	return self;
}

-(void)dealloc
{	
	[self freeNodes];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduledUpdate) object:nil];

	[transferDataPacket release];
	[expressionAsData release];
    [super dealloc];
}

- (void) freeNodes
{
	int i;
	if(filterNodes){
		for(i=0;i<filterNodeCount;i++){
			freeNode(filterNodes[i]);
		}
		free(filterNodes);
		filterNodes = nil;
	}
	if(startFilterNodes){
		for(i=0;i<startFilterNodeCount;i++){
			freeNode(startFilterNodes[i]);
		}
		free(startFilterNodes);
		startFilterNodes = nil;
	}
	if(finishFilterNodes){
		for(i=0;i<finishFilterNodeCount;i++){
			freeNode(finishFilterNodes[i]);
		}
		free(finishFilterNodes);
		finishFilterNodes = nil;
	}

}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Filter"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFilterController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterInConnector];
    [aConnector release];

    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width/2 - kConnectorSize/2 , 0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterFilteredConnector];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width-kConnectorSize,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterOutConnector];
    [aConnector release];
}

#pragma mark •••Accessors
- (BOOL)	exitNow
{
	return exitNow;
}

- (id) inputValue
{
	return inputValue;
}

- (void) setInputValue:(id)aValue
{
	[aValue retain];
	[inputValue release];
	inputValue = aValue;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterLastFileChangedChanged object:self];
}

- (unsigned long) processingTimeHist:(int)index
{
    return processingTimeHist[index];
}

- (void) clearTimeHistogram
{
    memset(processingTimeHist,0,kFilterTimeHistoSize*sizeof(unsigned long));
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterUpdateTiming object:self];
}

- (BOOL) timerEnabled
{
	return timerEnabled;
}

- (void) setTimerEnabled:(int)aState
{
	timerEnabled = aState;
	if(timerEnabled){
		[self clearTimeHistogram];
		mainTimer = [[ORTimer alloc]init];
		[mainTimer start];
	}
	else {
		[mainTimer release];
		mainTimer = nil;
	}
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORFilterTimerEnabledChanged
                      object:self];
}

#pragma mark •••Data Handling
- (void) processData:(ORDataPacket*)someData userInfo:(NSDictionary*)userInfo
{

	if(someData != currentDataPacket){
		[someData generateObjectLookup];	 //MUST be done before data header will work.
		[self loadDataIDsIntoSymbolTable:someData];
		if(firstTime){
			startFilterScript(self);
			firstTime = NO;
		}
		currentDataPacket = someData;
		if(transferDataPacket){
			[transferDataPacket release];
			transferDataPacket = nil;
		}
		transferDataPacket  = [someData copy];
		[transferDataPacket generateObjectLookup];	//MUST be done before data header will work.
		[transferDataPacket clearData];	
	}

	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
	[theNextObject processData:someData userInfo:userInfo];


	//each block of data is an array of NSData objects, each potentially containing many records..
	NSArray* theDataArray = [someData dataArray];
	int n = [theDataArray count];
	int i;
	for(i=0;i<n;i++){
		//each record must be filtered by the filter code. 
		NSData* data = [theDataArray objectAtIndex:i];
		long totalLen = [data length]/sizeof(long);
		if(totalLen>0){
			long* ptr = (long*)[data bytes];
			while(totalLen>0){
				long recordLen = ExtractLength(*ptr);
				filterData tempData;
				
				tempData.type		= kFilterPtrType;
				tempData.val.pValue = ptr;
				[symbolTable setData:tempData forKey:"CurrentRecordPtr"];
				
				tempData.type		= kFilterLongType;
				tempData.val.lValue = recordLen;
				[symbolTable setData:tempData forKey:"CurrentRecordLen"];
				
				unsigned long t = [runTimer microseconds]/1000;
				if(t!=lastRunTimeValue){
					lastRunTimeValue = t;
					tempData.type		= kFilterLongType;
					tempData.val.lValue = t;
					[symbolTable setData:tempData forKey:"ElapsedTime"];
				}
				
				if(timerEnabled) [mainTimer reset];
				
				runFilterScript(self);
				
				if(timerEnabled){
					float delta = [mainTimer microseconds];
					if(delta<kFilterTimeHistoSize)processingTimeHist[(int)delta]++;
					else processingTimeHist[kFilterTimeHistoSize-1]++;
				}
			
				ptr += recordLen;
				totalLen -= recordLen;
			}
		}
		else {
			[symbolTable removeKey:"CurrentRecordPtr"];
			[symbolTable removeKey:"CurrentRecordLen"];
		}
	}
}

- (unsigned long) dataId1D { return dataId1D; }
- (void) setDataId1D: (unsigned long) aDataId
{
    dataId1D = aDataId;
}

- (unsigned long) dataId2D { return dataId2D; }
- (void) setDataId2D: (unsigned long) aDataId
{
    dataId2D = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId1D       = [assigner assignDataIds:kLongForm];
    dataId2D       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId1D:[anotherObj dataId1D]];
    [self setDataId2D:[anotherObj dataId2D]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORFilterDecoderFor1D",				@"decoder",
        [NSNumber numberWithLong:dataId1D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:2],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Filter1D"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORFilterDecoderFor2D",				@"decoder",
        [NSNumber numberWithLong:dataId2D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:3],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Filter2D"];
	
    return dataDictionary;
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{		
	[self clearTimeHistogram];
	
	firstTime = YES;
	currentDataPacket = nil;
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFilterModel"];  
	
	[self parseScript];
	
	if(!parsedOK){
		NSLog(@"Filter script parse error prevented run start\n");
		[NSException raise:@"Parse Error" format:@"Filter Script parse failed."];
	}
	else {

		NSMutableDictionary* theHeader = [aDataPacket fileHeader];
		NSMutableDictionary* runControlSection = [theHeader objectForKey:@"Run Control"];
		if(runControlSection)[aDataPacket setRunNumber:[[runControlSection objectForKey:@"RunNumber"] longValue]];
		else {
			NSMutableDictionary* objectSection = [theHeader objectForKey:@"ObjectInfo"];	
			NSMutableArray* dataChainArray = [objectSection objectForKey:@"DataChain"];
			id item;
			NSEnumerator* e = [dataChainArray objectEnumerator];
			while(item = [e nextObject]){
				id runNum = [item objectForKey:@"RunNumber"];
				if(runNum){
					[aDataPacket setRunNumber:[runNum longValue]];
					break;
				}
			}
		}
		id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
		[theNextObject runTaskStarted:aDataPacket userInfo:userInfo];

		[aDataPacket setFilePrefix:@"FilteredRun"];
		theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
		[theNextObject runTaskStarted:aDataPacket userInfo:userInfo];
		
		runTimer = [[ORTimer alloc] init];
		[runTimer start];
		lastRunTimeValue = 0;
		
		int i;
		for(i=0;i<kNumFilterStacks;i++) stacks[i] = nil;
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
	[theNextObject runTaskStopped:aDataPacket userInfo:userInfo];

	theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
	[theNextObject runTaskStopped:aDataPacket userInfo:userInfo];
	
	[transferDataPacket release];
	transferDataPacket = nil;

	int i;
	for(i=0;i<kNumFilterStacks;i++){
		[stacks[i] release];
	}
	
	finishFilterScript(self);
	[self freeNodes];

	[runTimer release];
	runTimer = nil;

	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterUpdateTiming object:self];

}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
	[theNextObject closeOutRun:aDataPacket userInfo:userInfo];

	theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
	[theNextObject closeOutRun:aDataPacket userInfo:userInfo];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterScriptChanged object:self];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterNameChanged object:self];
}

- (id) arg:(int)index
{
	if(index>=0 && index<[args count])return [args objectAtIndex:index];
	else return nil;
}

- (void) setArg:(int)index withValue:(id)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setArg:index withValue:[self arg:index]];
	[args replaceObjectAtIndex:index withObject:aValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterArgsChanged object:self];
}


#pragma mark ***Script Methods

- (BOOL) parsedOK
{
	return parsedOK;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!running){
		[self parse:script];
		parsedOK = parsedSuccessfully;
		if(parsedOK && ([[NSApp currentEvent] modifierFlags] & 0x80000)>0){
			//option key is down
			graphNumber = 0;		
			int i;
			for(i=0;i<startFilterNodeCount;i++)	 filterGraph(startFilterNodes[i]);
			for(i=0;i<filterNodeCount;i++)		 filterGraph(filterNodes[i]);
			for(i=0;i<finishFilterNodeCount;i++) filterGraph(finishFilterNodes[i]);
		}
	}
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
	[self setScript:[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    args = [[decoder decodeObjectForKey:@"args"] retain];

	if(!args){
		args = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<kNumScriptArgs;i++){
			[args addObject:[NSDecimalNumber zero]];
		}
	}
	
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:args forKey:@"args"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
}

#pragma mark •••Parsers

- (void) parseFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath]];
	[self parse:contents];
}

-(void) parse:(NSString* )theString 
{  
	// yacc has a number of global variables so it is NOT thread safe
	// Acquire the lock to ensure one parse processing at a time
	@synchronized([NSApp delegate]){
		parsedOK = NO;
		NS_DURING {
			
			resetFilterState();
			FilterScriptrestart(NULL);
			
			theFilterRunner = self;
			[self setString:theString];
			parsedSuccessfully  = NO;
			numFilterLines = 0;
			// Call the parser that was generated by yacc
			FilterScriptparse();
			if(parsedSuccessfully) {
				NSLog(@"%d Lines Parsed Successfully\n",numFilterLines);
				parsedOK = YES;
			}
			else  {
				NSLog(@"line %d: %@\n",numFilterLines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:numFilterLines]);
			}

		}
		NS_HANDLER {
			NSLog(@"line %d: %@\n",numFilterLines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:numFilterLines]);
			NSLog(@"Caught %@: %@\n",[localException name],[localException reason]);
			//[functionList release];
			//functionList = nil;
		}
		NS_ENDHANDLER
		theFilterRunner = nil;
	}
}


#pragma mark •••Yacc Input
- (void)setString:(NSString* )theString 
{
	NSData* theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
	[theData retain];
	[expressionAsData release];
	expressionAsData = theData;
	yaccInputPosition = 0;
}

-(int)yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize 
{
	int theNumberOfBytesRemaining = ([expressionAsData length] - yaccInputPosition);
	int theCopySize = maxSize < theNumberOfBytesRemaining ? maxSize : theNumberOfBytesRemaining;
	[expressionAsData getBytes:theBuffer range:NSMakeRange(yaccInputPosition,theCopySize)];  
	yaccInputPosition = yaccInputPosition + theCopySize;
	return theCopySize;
}

#pragma mark ***Plugin Interface
- (long) extractRecordID:(long)aValue
{
	return ExtractDataId(aValue);
}

- (long) extractRecordLen:(long)aValue
{
	return ExtractLength(aValue);
}

- (void) shipRecord:(long*)p length:(long)length
{
	if(ExtractDataId(p[0]) != 0){
		[transferDataPacket addLongsToFrameBuffer:(unsigned long*)p length:length];
		[transferDataPacket addFrameBuffer:YES];
		//pass it on
		id theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
		[theNextObject processData:transferDataPacket userInfo:nil];
		[transferDataPacket clearData];
	}
}

- (void) pushOntoStack:(int)i record:(long*)p
{
	if(!stacks[i])stacks[i] = [[ORQueue alloc] init]; 
	
	NSData* data = [NSData dataWithBytes:p length:ExtractLength(*p)*sizeof(long)];
	[stacks[i] enqueue:data];
}

- (long*) popFromStack:(int)i
{
	NSData* data = [stacks[i] dequeue];
	return (long*)[data bytes];
}

- (void) shipStack:(int)i
{
	while(![stacks[i] isEmpty]){
		[transferDataPacket addData:[stacks[i] dequeueFromBottom]];
	}
	[transferDataPacket addFrameBuffer:YES];
	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
	[theNextObject processData:transferDataPacket userInfo:nil];
	[transferDataPacket clearData];
	
	[self dumpStack:i];
}

- (long) stackCount:(int)i
{
	return [stacks[i] count];
}

- (void) dumpStack:(int)i
{
	[stacks[i] release];
	stacks[i] = nil;
}

- (void) histo1D:(int)i value:(long)aValue
{
	long p[2];
	p[0] = dataId1D | 2;
	p[1] = (i & 0xff) << 16 | (aValue & 0xfff);
	[transferDataPacket addLongsToFrameBuffer:(unsigned long*)p length:2];
	[transferDataPacket addFrameBuffer:YES];
	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
	[theNextObject processData:transferDataPacket userInfo:nil];
	[transferDataPacket clearData];
}

- (void) histo2D:(int)i x:(long)x y:(long)y
{
	long p[2];
	p[0] = dataId2D | 3;
	p[1] = (i & 0xff) << 16 | (x & 0xff);
	p[2] = (y & 0xff);
	[transferDataPacket addLongsToFrameBuffer:(unsigned long*)p length:3];
	[transferDataPacket addFrameBuffer:YES];
	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterFilteredConnector];
	[theNextObject processData:transferDataPacket userInfo:nil];
	[transferDataPacket clearData];
}

- (id) displayValue:(int)index
{
	if(index>=0 && index<[displayValues count])return [displayValues objectAtIndex:index];
	else return [NSNumber numberWithUnsignedLong:0];		
}

- (void) setDisplay:(int)index withValue:(long)aValue
{
	if(!displayValues){
		displayValues = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<kNumDisplayValues;i++){
			[displayValues addObject:[NSNumber numberWithUnsignedLong:0]];
		}
	}

	[displayValues replaceObjectAtIndex:index withObject:[NSNumber numberWithLong:aValue]];

	//we'll reduce updates to 1/sec
	if(!updateScheduled){
		updateScheduled = YES;	
		[self performSelector:@selector(scheduledUpdate) withObject:nil afterDelay:.2];
	}
}

- (void) resetDisplays
{
	int i;
	for(i=0;i<kNumDisplayValues;i++){
		[self setDisplay:i withValue:0];
	}
}


- (void) scheduledUpdate
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterDisplayValuesChanged object:self];
	updateScheduled = NO;	
}

@end

@implementation ORFilterModel (private)
- (void) loadDataIDsIntoSymbolTable:(ORDataPacket*)aDataPacket
{	
	NSMutableDictionary* descriptionDict = [[aDataPacket fileHeader] objectForKey:@"dataDescription"];
	NSString* objKey;
	NSEnumerator*  descriptionDictEnum = [descriptionDict keyEnumerator];
	
	//we are a special case and might not be in the data stream if the data is coming from 
	//the data replay object so we'll check and if needed will define data ids for ourselves.
	NSDictionary* objDictionary = [descriptionDict objectForKey:@"ORFilterDecoderFor1D"];
	long anID = [[objDictionary objectForKey:@"dataId"] longValue];
	if(anID == 0){
		unsigned long maxLongID = 0;
		//loop over all objects in the descript and log the highest id
		while(objKey = [descriptionDictEnum nextObject]){
			NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
			NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
			NSString* dataObjKey;
			while(dataObjKey = [dataObjEnum nextObject]){
				NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
				unsigned long anID = [[lowestLevel objectForKey:@"dataId"] longValue];
				if(IsLongForm(anID)){
					anID >>= 18;
					if(anID>maxLongID)maxLongID = anID;
				}
			} 
		}
		if(maxLongID>0){
			maxLongID++;
			[self setDataId1D:maxLongID<<18];
			maxLongID++;
			[self setDataId2D:maxLongID<<18];
			[descriptionDict setObject:[self dataRecordDescription] forKey:@"ORFilterModel"];
			[aDataPacket generateObjectLookup];

		}
	}

	descriptionDictEnum = [descriptionDict keyEnumerator];
	while(objKey = [descriptionDictEnum nextObject]){
		NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
		NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
		NSString* dataObjKey;
		while(dataObjKey = [dataObjEnum nextObject]){
			NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
			NSString* decoderName = [lowestLevel objectForKey:@"decoder"];
			filterData theDataType;
			theDataType.val.lValue = [[lowestLevel objectForKey:@"dataId"] longValue];
			theDataType.type  = kFilterLongType;
			[symbolTable setData:theDataType forKey:[decoderName cStringUsingEncoding:NSASCIIStringEncoding]];
		} 
	}
	
	descriptionDict = [[aDataPacket fileHeader] objectForKey:@"dataDescription"];

	NSEnumerator* e = [args objectEnumerator];
	id val;
	int i=0;
	filterData tempData;
	while(val = [e nextObject]){
		tempData.type		= kFilterLongType;
		tempData.val.lValue = [val longValue];
		NSString* s = [NSString stringWithFormat:@"$%d",i];
		[symbolTable setData:tempData forKey:[s cStringUsingEncoding:NSASCIIStringEncoding]];
		i++;
	}

}

@end

@implementation ORFilterDecoderFor1D

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 2;

    unsigned short index  = (ptr[1]&0x0fff0000)>>16;
    unsigned long  value = ptr[1]&0x00000fff;

    [aDataSet histogram:value numBins:4096  sender:self  withKeys:@"Filter",
		[NSString stringWithFormat:@"%d",index],
        nil];
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Filter Record (1D)\n\n";
    
    NSString* value  = [NSString stringWithFormat:@"Value = %d\n",ptr[1]&0x00000fff];    
    NSString* index  = [NSString stringWithFormat: @"Index  = %d\n",(ptr[1]&0x0fff0000)>>16];    

    return [NSString stringWithFormat:@"%@%@%@",title,value,index];               
}


@end

@implementation ORFilterDecoderFor2D
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 3;

    [aDataSet histogram2DX:ptr[1]&0x00000fff y:ptr[2]&0x00000fff size:256  sender:self  
		withKeys:@"Filter2D",[NSString stringWithFormat:@"%d",(ptr[1]&0x0fff0000)>>16],
        nil];


    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Filter Record (2D)\n\n";
    
    NSString* index  = [NSString stringWithFormat: @"Index  = %d\n",(ptr[1]&0x0fff0000)>>16];    
    NSString* valueX  = [NSString stringWithFormat:@"ValueX = %d\n",ptr[1]&0x00000fff];    
    NSString* valueY  = [NSString stringWithFormat:@"ValueY = %d\n",ptr[2]&0x00000fff];    

    return [NSString stringWithFormat:@"%@%@%@%@",title,valueX,valueY,index];               
}
@end

