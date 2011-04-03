//
//  ORDataFileModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataFileModel.h"
#import "ORSmartFolder.h"
#import "ORAlarm.h"
#import "ORDecoder.h"
#import "ORStatusController.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORDataFileModelUseDatedFileNamesChanged	= @"ORDataFileModelUseDatedFileNamesChanged";
NSString* ORDataFileModelUseFolderStructureChanged	= @"ORDataFileModelUseFolderStructureChanged";
NSString* ORDataFileModelFilePrefixChanged			= @"ORDataFileModelFilePrefixChanged";
NSString* ORDataFileModelFileSegmentChanged			= @"ORDataFileModelFileSegmentChanged";
NSString* ORDataFileModelMaxFileSizeChanged			= @"ORDataFileModelMaxFileSizeChanged";
NSString* ORDataFileModelLimitSizeChanged			= @"ORDataFileModelLimitSizeChanged";
NSString* ORDataFileChangedNotification             = @"The DataFile File Has Changed";
NSString* ORDataFileStatusChangedNotification 		= @"The DataFile Status Has Changed";
NSString* ORDataFileSizeChangedNotification 		= @"The DataFile Size Has Changed";
NSString* ORDataSaveConfigurationChangedNotification    = @"ORDataSaveConfigurationChangedNotification";
NSString* ORDataFileModelSizeLimitReachedActionChanged	= @"ORDataFileModelSizeLimitReachedActionChanged";

NSString* ORDataFileLock					= @"ORDataFileLock";

#pragma mark ¥¥¥Definitions
static NSString *ORDataFileConnection 		= @"Data File Input Connector";

@interface ORDataFileModel (private)
- (NSString*) formRunName:(id)userInfo;
@end

@implementation ORDataFileModel

#pragma mark ¥¥¥Initialization

static const int currentVersion = 1;           // Current version

- (void) initialize
{
    if ([self class] == [ORDataFileModel class]) {
        [[self class] setVersion: currentVersion];
    }    
}

- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    ignoreMode = YES;
    [self setDataFolder:[[[ORSmartFolder alloc]init]autorelease]];
    [self setStatusFolder:[[[ORSmartFolder alloc]init]autorelease]];
    [self setConfigFolder:[[[ORSmartFolder alloc]init]autorelease]];
    
    [[self undoManager] enableUndoRegistration];
	
	[self registerNotificationObservers];

    return self;
}


- (void) dealloc
{
    [filePrefix release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[diskFullAlarm clearAlarm];
    [diskFullAlarm release];
    [filePointer release];
    [fileName release];
    [statusFileName release];
    [dataFolder release];
    [statusFolder release];
    [configFolder release];
    
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x],[self y]+15) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataFileConnection];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
}


- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"DataFile"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if([[ORGlobal sharedGlobal] runMode] == kOfflineRun && !ignoreMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage compositeToPoint:NSMakePoint([i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height/2) operation:NSCompositeSourceOver];
    }
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataFileController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Data_Storage.html";
}

- (void)setTitles
{
    [dataFolder setTitle:@"Data Files"];
    [statusFolder setTitle:@"Status Logs"];
    [configFolder setTitle:@"Config Files"];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(statusLogFlushed:)
                         name : ORStatusFlushedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
}

- (void) runAboutToStart:(NSNotification*)aNotification
{
	if([[self document] isDocumentEdited])[[self document] saveDocument:nil];
    if(saveConfiguration){
		[configFolder ensureExists:[configFolder finalDirectoryName]]; 
		if([[ORGlobal sharedGlobal] documentWasEdited] || !savedFirstTime){
			unsigned long runNumber = [[[aNotification userInfo] objectForKey:@"kRunNumber"] longValue];
			[[self document] copyDocumentTo:[[configFolder finalDirectoryName]stringByExpandingTildeInPath] append:[NSString stringWithFormat:@"%d",runNumber]];
			savedFirstTime = YES;
		}
	}
}


- (void) setRunMode:(int)aMode
{
	runMode = aMode;
    [self setUpImage];
}

- (void) statusLogFlushed:(NSNotification*)aNotification
{
    statusStart -= [[[aNotification userInfo] objectForKey:ORStatusFlushSize] intValue];
    if(statusStart<0)statusStart = 0;
}


#pragma mark ¥¥¥Accessors

- (BOOL) useDatedFileNames
{
    return useDatedFileNames;
}

- (void) setUseDatedFileNames:(BOOL)aUseDatedFileNames
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseDatedFileNames:useDatedFileNames];
    
    useDatedFileNames = aUseDatedFileNames;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelUseDatedFileNamesChanged object:self];
}

- (BOOL) useFolderStructure
{
    return useFolderStructure;
}

- (void) setUseFolderStructure:(BOOL)aUseFolderStructure
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseFolderStructure:useFolderStructure];
    
    useFolderStructure = aUseFolderStructure;
	[dataFolder setUseFolderStructure:aUseFolderStructure];
	[configFolder setUseFolderStructure:aUseFolderStructure];
	[statusFolder setUseFolderStructure:aUseFolderStructure];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelUseFolderStructureChanged object:self];
}

- (NSString*) filePrefix
{
    if(filePrefix == nil)return @"Run";
    else return filePrefix;
}

- (void) setFilePrefix:(NSString*)aFilePrefix
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFilePrefix:filePrefix];
    if(aFilePrefix == nil)aFilePrefix = @"Run";
    [filePrefix autorelease];
    filePrefix = [aFilePrefix copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelFilePrefixChanged object:self];
}

- (int) fileSegment
{
    return fileSegment;
}

- (void) setFileSegment:(int)aFileSegment
{
    fileSegment = aFileSegment;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelFileSegmentChanged object:self];
}

- (float) maxFileSize
{
    return maxFileSize;
}

- (void) setMaxFileSize:(float)aMaxFileSize
{
	if(aMaxFileSize<10)aMaxFileSize=10;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxFileSize:maxFileSize];
    
    maxFileSize = aMaxFileSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelMaxFileSizeChanged object:self];
}

- (BOOL) limitSize
{
    return limitSize;
}

- (void) setLimitSize:(BOOL)aLimitSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLimitSize:limitSize];
    
    limitSize = aLimitSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelLimitSizeChanged object:self];
}

- (int)sizeLimitReachedAction
{
    return sizeLimitReachedAction;
}

- (void) setSizeLimitReachedAction:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSizeLimitReachedAction:sizeLimitReachedAction];
    
    sizeLimitReachedAction = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileModelSizeLimitReachedActionChanged object:self];
}


- (ORSmartFolder *)dataFolder 
{
    return dataFolder; 
}

- (void)setDataFolder:(ORSmartFolder *)aDataFolder 
{
    [aDataFolder retain];
    [dataFolder release];
    dataFolder = aDataFolder;
	[dataFolder setDefaultLastPathComponent:@"Data"];
}

- (ORSmartFolder *)statusFolder 
{
    return statusFolder; 
}

- (void)setStatusFolder:(ORSmartFolder *)aStatusFolder 
{
    [aStatusFolder retain];
    [statusFolder release];
    statusFolder = aStatusFolder;
	[statusFolder setDefaultLastPathComponent:@"Logs"];
}

- (ORSmartFolder *)configFolder 
{
    return configFolder; 
}

- (void)setConfigFolder:(ORSmartFolder *)aConfigFolder 
{
    [aConfigFolder retain];
    [configFolder release];
    configFolder = aConfigFolder;
	[configFolder setDefaultLastPathComponent:@"Configurations"];
}

- (void) setFileName:(NSString*)aFileName
{
    
    [fileName autorelease];
    fileName = [aFileName copy];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataFileChangedNotification
	 object:self];
}

- (NSString*)fileName
{
	if(!fileName)return @"";
    else return fileName;
}


- (NSFileHandle *)filePointer
{
    return filePointer; 
}
- (void)setFilePointer:(NSFileHandle *)aFilePointer
{
    [aFilePointer retain];
    [filePointer release];
    filePointer = aFilePointer;
}

- (NSString*) tempDir
{
    return [dataFolder ensureSubFolder:@"openFiles" inFolder:[dataFolder finalDirectoryName]];
}

- (BOOL)saveConfiguration
{
    return saveConfiguration;
}

- (void)setSaveConfiguration:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSaveConfiguration:saveConfiguration];
    saveConfiguration = flag;
	if(saveConfiguration)savedFirstTime = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataSaveConfigurationChangedNotification object: self];
}

- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
{
    if(filePointer && runMode == kNormalRun){
		NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate];
		if(fabs(lastFileCheckTime - thisTime) > 3){
			lastFileCheckTime = thisTime;
			[self performSelectorOnMainThread:@selector(getDataFileSize) withObject:nil waitUntilDone:NO];
		}
        for(id dataItem in dataArray){
            [dataBuffer appendData:dataItem];
        }
        if(([dataBuffer length] > 15*1024) || ([NSDate timeIntervalSinceReferenceDate]-lastTime > 15)){
            [filePointer writeData:dataBuffer];
            [dataBuffer setLength:0];
            lastTime = [NSDate timeIntervalSinceReferenceDate];
        }
		
		if(fileLimitExceeded){
			NSString* reason = [NSString stringWithFormat:@"File size exceeded %.1f MB",maxFileSize];
			
			if(sizeLimitReachedAction == kStopOnLimit){
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:ORRequestRunHalt
				 object:self
				 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
				
			}
			else {
				[[NSNotificationCenter defaultCenter] 
				 postNotificationName:ORRequestRunRestart
				 object:self
				 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
			}
				fileLimitExceeded = NO;
		}
    }
}


- (void) runTaskStarted:(id)userInfo
{
	if(diskFullAlarm){
		[diskFullAlarm clearAlarm];
		[diskFullAlarm release];
		diskFullAlarm = nil;
	}
	
    if(!dataBuffer)dataBuffer = [[NSMutableData dataWithCapacity:20*1024] retain];
    lastTime	 = [NSDate timeIntervalSinceReferenceDate];
    fileSegment = 1;
	fileLimitExceeded = NO;
	
    if(processedRunStart) return;
    else {
        processedRunStart = YES;
        processedCloseRun = NO;
    }
    runMode = [[userInfo objectForKey:kRunMode] intValue];
    if(runMode == kNormalRun){
        //open file and write headers

        [self setFileName:[self formRunName:userInfo]];
		
        if(fileName){
			NSString* fullFileName = [[self tempDir] stringByAppendingPathComponent:[self fileName]];
			[openFilePath autorelease];
			openFilePath = [fullFileName copy];    
			
			NSLog(@"Opening dataFile: %@\n",[fullFileName stringByAbbreviatingWithTildeInPath]);
			NSFileManager* fm = [NSFileManager defaultManager];
			[fm createFileAtPath:fullFileName contents:nil attributes:nil];
			NSFileHandle* fp = [NSFileHandle fileHandleForWritingAtPath:fullFileName];
			[fp seekToEndOfFile];
            [self setFilePointer:fp];
        }
        
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORDataFileStatusChangedNotification
		 object: self];
        
        
        [self getDataFileSize];
        
    }
}

- (void) subRunTaskStarted:(id)userInfo
{
	//we don't care
}

- (void) runTaskStopped:(id)userInfo
{
	//we don't care
}


- (void) closeOutRun:(id)userInfo
{	
    if(processedCloseRun)return;
    else {
        processedCloseRun = YES;
        processedRunStart = NO;
    }
	
    if(filePointer && (runMode == kNormalRun)){
        [self getDataFileSize];
        
        //write out the last of the data if any
        [filePointer writeData:dataBuffer];
        
        [filePointer release];
        filePointer = nil;
        
        [dataBuffer release];
        dataBuffer = nil;
        
        NSString* tmpFileName = openFilePath;
        NSLog(@"Closing dataFile: %@\n",[tmpFileName stringByAbbreviatingWithTildeInPath]);
        NSString* fullFileName = [[[dataFolder finalDirectoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:[self fileName]];
		BOOL copiedOK = [[NSFileManager defaultManager] moveItemAtPath:tmpFileName toPath:fullFileName error:nil];
        if(copiedOK){
            NSLog(@"Moving dataFile to : %@\n",[fullFileName stringByAbbreviatingWithTildeInPath]);
        }
        else {
            NSFileManager* fm = [NSFileManager defaultManager];
            int subRun = 1;
            do {
                NSString* subRunFileName = [NSString stringWithFormat:@"%@_%d",fullFileName,subRun];
                if(![fm fileExistsAtPath:subRunFileName]){
                    copiedOK = [[NSFileManager defaultManager] moveItemAtPath:tmpFileName toPath:subRunFileName error:nil];
                    if(copiedOK){
                        NSLog(@"Moving subRun dataFile to : %@\n",[subRunFileName stringByAbbreviatingWithTildeInPath]);
                    }
                    else {
                        NSLogColor([NSColor redColor],@"Unable to move dataFile: %@ to %@\n",tmpFileName,[subRunFileName stringByAbbreviatingWithTildeInPath]);
                        NSLogColor([NSColor redColor],@"You will have to do it manually.");
                    }
                    break;
                }
				subRun++;
            }while(1);
        }
        
        
        if([dataFolder copyEnabled]){		
            //start a copy of the Data File
            [dataFolder queueFileForSending:fullFileName];
        }
    }
    
    int statusEnd = [[ORStatusController sharedStatusController] statusTextlength];
    if(runMode == kNormalRun){
	    //start a copy of the Status File
	    statusFileName = [[NSString stringWithFormat:@"%@.log",[self formRunName:userInfo]] retain];
        
        [statusFolder ensureExists:[statusFolder finalDirectoryName]];
        NSString* fullStatusFileName = [[[statusFolder finalDirectoryName]stringByExpandingTildeInPath] stringByAppendingPathComponent:statusFileName];
	    NSFileManager* fm = [NSFileManager defaultManager];
	    [fm createFileAtPath:fullStatusFileName contents:nil attributes:nil];
	    NSFileHandle* statusFilePointer = [NSFileHandle fileHandleForWritingAtPath:fullStatusFileName];
	    
	    NSLog(@"Copied Status to: %@\n",[fullStatusFileName stringByAbbreviatingWithTildeInPath]);
	    statusEnd = [[ORStatusController sharedStatusController] statusTextlength];
	    
	    @try {
            NSString* text = [[ORStatusController sharedStatusController] substringWithRange:NSMakeRange(statusStart, statusEnd - statusStart)];
            [statusFilePointer writeData:[text dataUsingEncoding:NSASCIIStringEncoding]];
		}
		@catch(NSException* localException) {
		}
		
		@try {
			[statusFilePointer writeData:[@"\n\n----------------------------------------------------\n" dataUsingEncoding:NSASCIIStringEncoding]];
			[statusFilePointer writeData:[@"------------------Error Summary---------------------\n" dataUsingEncoding:NSASCIIStringEncoding]];
			[statusFilePointer writeData:[@"----------------------------------------------------\n" dataUsingEncoding:NSASCIIStringEncoding]];
			NSString* errorSummary = [[ORStatusController sharedStatusController] errorSummary];
			if([errorSummary length] == 0){
				[statusFilePointer writeData:[@"No Errors in Error Log.\n" dataUsingEncoding:NSASCIIStringEncoding]];
			}
			else [statusFilePointer writeData:[errorSummary dataUsingEncoding:NSASCIIStringEncoding]];
		}
		@catch(NSException* localException) {
		}
		
		[statusFilePointer closeFile];
		
		if([statusFolder copyEnabled]){	
			[statusFolder queueFileForSending:fullStatusFileName];
		}
	}
	statusStart = statusEnd; 
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataFileStatusChangedNotification
	 object: self];
	
	[openFilePath release];
	openFilePath = nil;
}

- (void) runTaskBoundary
{
}

- (unsigned long)dataFileSize
{
    return dataFileSize;
}

- (void) setDataFileSize:(unsigned long)aNumber
{
    dataFileSize = aNumber;
    
	if(limitSize && (dataFileSize >= maxFileSize*1000000)){
		fileLimitExceeded = YES;
	}
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORDataFileSizeChangedNotification
		object: self];
}

- (void) getDataFileSize
{
    NSNumber* fsize;
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* fullFileName = openFilePath;
    NSDictionary *fattrs = [fm attributesOfItemAtPath:fullFileName error:nil];
    if ((fsize = [fattrs objectForKey:NSFileSize])){
        [self setDataFileSize:[fsize intValue]];
    }
	checkCount++;
	if(!(checkCount%20)) {
		[self checkDiskStatus];
	}
}

- (void) checkDiskStatus
{
	NSError* diskError = nil;
	NSDictionary* diskInfo = [[[[NSFileManager alloc] init] autorelease] attributesOfFileSystemForPath:openFilePath error:&diskError];
	if (!diskError) {
		if(diskInfo){
			long long freeSpace = [[diskInfo objectForKey:NSFileSystemFreeSize] longLongValue];	
			if(freeSpace < kMinDiskSpace * 1024 * 1024){
				if(!diskFullAlarm){
					diskFullAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Disk Is Full"] severity:kHardwareAlarm];
					[diskFullAlarm setSticky:YES];
					[diskFullAlarm setHelpString:[NSString stringWithFormat:@"The data disk is dangerously full. Less than %d MB Left. Runs will not be possible until space is available.", kMinDiskSpace]];
				}
					
				[diskFullAlarm setAcknowledged:NO];
				[diskFullAlarm postAlarm];
					
				NSString* reason = [NSString stringWithFormat:@"Disk Space size less than %d MB",kMinDiskSpace];
				[[NSNotificationCenter defaultCenter]
					 postNotificationName:ORRequestRunHalt
									object:self
									userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
			}
			
		}
		else {
			NSLogColor([NSColor redColor],@"failed to get file system free space\nerror: %@\n", [diskError localizedDescription]);
		}
	}

}

#pragma mark ¥¥¥Archival
//-------------------------------------------------------------------------------
//version 0 stuff
static NSString* ORDataDirName              = @"Data file dir name";
static NSString* ORDataCopyEnabled          = @"ORData CopyEnabled";
static NSString* ORDataDeleteWhenCopied     = @"ORData DeleteWhenCopied";
static NSString* ORDataCopyStatusEnabled    = @"ORData CopyStatusEnabled";
static NSString* ORDataDeleteStatusWhenCopied= @"ORData DeleteStatusWhenCopied";
static NSString* ORDataRemotePath           = @"ORData Remote Path";
static NSString* ORDataRemoteHost           = @"ORData Remote Host";
static NSString* ORDataRemoteUserName       = @"ORData Remote UserName";
static NSString* ORDataPassWord             = @"ORData PassWord";
static NSString* ORDataVerbose              = @"ORData Verbose";
//-------------------------------------------------------------------------------
static NSString* ORDataDataFolderName       = @"ORDataDataFolderName";
static NSString* ORDataStatusFolderName     = @"ORDataStatusFolderName";
static NSString* ORDataConfigFolderName     = @"ORDataConfigFolderName";
static NSString* ORDataVersion		    = @"ORDataVersion";

static NSString* ORDataSaveConfiguration    = @"ORDataSaveConfiguration";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setUseDatedFileNames:	[decoder decodeBoolForKey:@"ORDataFileModelUseDatedFileNames"]];
    [self setMaxFileSize:		[decoder decodeFloatForKey:@"ORDataFileModelMaxFileSize"]];
    [self setLimitSize:			[decoder decodeBoolForKey:@"ORDataFileModelLimitSize"]];
    [self setSizeLimitReachedAction:[decoder decodeIntForKey:@"sizeLimitReachedAction"]];
	
    int  version =				[decoder decodeIntForKey:ORDataVersion];
    
    //-------------------------------------------------------------------------------
    //version 0 stuff
    if (version < currentVersion){
        [self setDataFolder:[[[ORSmartFolder alloc]init] autorelease]];
        [self setStatusFolder:[[[ORSmartFolder alloc]init] autorelease]];
        [self setConfigFolder:[[[ORSmartFolder alloc]init] autorelease]];
        [dataFolder setDirectoryName:[decoder decodeObjectForKey:ORDataDirName]];
        [dataFolder setCopyEnabled:[decoder decodeBoolForKey:ORDataCopyEnabled]];
        [dataFolder setDeleteWhenCopied:[decoder decodeBoolForKey:ORDataDeleteWhenCopied]];
        [dataFolder setRemotePath:[decoder decodeObjectForKey:ORDataRemotePath]];
        [dataFolder setRemoteHost:[decoder decodeObjectForKey:ORDataRemoteHost]];
        [dataFolder setPassWord:[decoder decodeObjectForKey:ORDataPassWord]];
        [dataFolder setRemoteUserName:[decoder decodeObjectForKey:ORDataRemoteUserName]];
        [dataFolder setVerbose:[decoder decodeBoolForKey:ORDataVerbose]];
        
        [statusFolder setDirectoryName:[decoder decodeObjectForKey:ORDataDirName]];
        [statusFolder setCopyEnabled:[decoder decodeBoolForKey:ORDataCopyStatusEnabled]];
        [statusFolder setDeleteWhenCopied:[decoder decodeBoolForKey:ORDataDeleteStatusWhenCopied]];
        [statusFolder setRemotePath:[decoder decodeObjectForKey:ORDataRemotePath]];
        [statusFolder setRemoteHost:[decoder decodeObjectForKey:ORDataRemoteHost]];
        [statusFolder setPassWord:[decoder decodeObjectForKey:ORDataPassWord]];
        [statusFolder setRemoteUserName:[decoder decodeObjectForKey:ORDataRemoteUserName]];
        [statusFolder setVerbose:[decoder decodeBoolForKey:ORDataVerbose]];
    }
    //-------------------------------------------------------------------------------
    else {
        [self setDataFolder:[decoder decodeObjectForKey:ORDataDataFolderName]];
        [self setStatusFolder:[decoder decodeObjectForKey:ORDataStatusFolderName]];
        [self setConfigFolder:[decoder decodeObjectForKey:ORDataConfigFolderName]];
    }
    
	[self setFilePrefix:[decoder decodeObjectForKey:@"ORDataFileModelFilePrefix"]];
	[self setUseFolderStructure:[decoder decodeBoolForKey:@"ORDataFileModelUseFolderStructure"]];
    [self setSaveConfiguration:[decoder decodeBoolForKey:ORDataSaveConfiguration]];
    
    [[self undoManager] enableUndoRegistration];
    
    ignoreMode = NO;
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:useDatedFileNames	forKey:@"ORDataFileModelUseDatedFileNames"];
    [encoder encodeBool:useFolderStructure	forKey:@"ORDataFileModelUseFolderStructure"];
    [encoder encodeObject:filePrefix		forKey:@"ORDataFileModelFilePrefix"];
    [encoder encodeFloat:maxFileSize		forKey:@"ORDataFileModelMaxFileSize"];
    [encoder encodeBool:limitSize			forKey:@"ORDataFileModelLimitSize"];
    [encoder encodeInt:currentVersion		forKey:ORDataVersion];
    [encoder encodeObject:dataFolder		forKey:ORDataDataFolderName];
    [encoder encodeObject:statusFolder		forKey:ORDataStatusFolderName];
    [encoder encodeObject:configFolder		forKey:ORDataConfigFolderName];
    [encoder encodeBool:saveConfiguration	forKey:ORDataSaveConfiguration];
    [encoder encodeInt:sizeLimitReachedAction forKey:@"sizeLimitReachedAction"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:[dataFolder addParametersToDictionary:[NSMutableDictionary dictionary]] forKey:@"DataFolder"];
    [objDictionary setObject:[statusFolder addParametersToDictionary:[NSMutableDictionary dictionary]] forKey:@"StatusFolder"];
    [objDictionary setObject:[configFolder addParametersToDictionary:[NSMutableDictionary dictionary]] forKey:@"ConfigFolder"];
    [objDictionary setObject:[NSNumber numberWithInt:saveConfiguration] forKey:@"SaveConfiguration"];
	
    [dictionary setObject:objDictionary forKey:@"Data File"];
	
    return objDictionary;
}

@end

@implementation ORDataFileModel (private)

- (NSString*) formRunName:(id)userInfo
{
	NSString* s;
	int runNumber		 = [[userInfo objectForKey:kRunNumber]intValue];
	int subRunNumber	 = [[userInfo objectForKey:kSubRunNumber] intValue];
	NSString* fileSuffix = [userInfo objectForKey:kFileSuffix];
	if(!fileSuffix)fileSuffix = @"";
	if(filePrefix!=nil){
		if([filePrefix rangeOfString:@"Run"].location != NSNotFound){
			s = [NSString stringWithFormat:@"%@%@%d",filePrefix,fileSuffix,runNumber];
		}
		else s = [NSString stringWithFormat:@"%@%@Run%@%d",filePrefix,[filePrefix length]?@"_":@"",fileSuffix,runNumber];
	}
	else s = [NSString stringWithFormat:@"Run%@%d",fileSuffix,runNumber];
	if(subRunNumber!=0)s = [s stringByAppendingFormat:@".%d",subRunNumber];
	if(useDatedFileNames){
		NSCalendarDate* theDate = [NSCalendarDate date];
		s = [NSString stringWithFormat:@"%d-%d-%d-%@",[theDate yearOfCommonEra], [theDate monthOfYear], [theDate dayOfMonth],s];
	}
	return s;
}
@end

