//--------------------------------------------------------
// ORcPCIcpuModel
// Created by Mark  A. Howe on Tue Feb 07 2006
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ���Imported Files

#import "ORcPCIcpuModel.h"
#import "ORReadOutList.h"
#import "SBC_Link.h"


#pragma mark ���External Strings
NSString* ORcPCIcpuLock							= @"ORcPCIcpuLock";

@implementation ORcPCIcpuModel
- (id) init
{
	self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
	[self setReadOutGroup:readList];
	[readList release];
	sbcLink = [[SBC_Link alloc] initWithDelegate:self];
	return self;
}

- (void) dealloc
{
	[sbcLink release];
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"cPCIcpu"]];
}

- (void) makeMainController
{
	[self linkToController:@"SBC_LinkController"];
}

- (BOOL) showBasicOps
{
	return NO;
}


- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		if(!sbcLink){
			sbcLink = [[SBC_Link alloc] initWithDelegate:self];
		}
		[sbcLink connect];
	NS_HANDLER
	NS_ENDHANDLER
}

- (void) wakeUp 
{
	[super wakeUp];
	[sbcLink wakeUp];
}

- (void) sleep 
{
	[super sleep];
	[sbcLink sleep];
}	


#pragma mark ���Accessors

- (SBC_Link*)sbcLink
{
	return sbcLink;
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}
- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}


- (NSMutableArray*) children {
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (id) adapter
{
	return sbcLink;
}


#pragma mark ���SBC_Linking protocol

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"cPCI CPU (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return ORcPCIcpuLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/CompactPCI/cPCIcpu/cPCI_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark ���Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setReadOutGroup:  [decoder decodeObjectForKey:@"ReadoutGroup"]];

	sbcLink = [[decoder decodeObjectForKey:@"SBC_Link"] retain];
	if(!sbcLink){
		sbcLink = [[SBC_Link alloc] initWithDelegate:self];
	}
	else [sbcLink setDelegate:self];
	
	//needed only during testing because the readoutgroup was added when the object was already in the config
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
	[encoder encodeObject:sbcLink		forKey:@"SBC_Link"];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	dataTakers = [[readOutGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    //load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[sbcLink runTaskStarted:aDataPacket userInfo:userInfo];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[sbcLink takeData:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[sbcLink runTaskStopped:aDataPacket userInfo:userInfo];
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}

- (void) reset
{
}

- (void) load_HW_Config
{
	NSEnumerator* e = [dataTakers objectEnumerator];
	id obj;
	int index = 0;
	SBC_crate_config configStruct;
	
	configStruct.total_cards = 0;

	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			index = [obj load_HW_Config_Structure:&configStruct index:index];
		}
	}
	
	[sbcLink load_HW_Config:&configStruct];
	
}
@end

