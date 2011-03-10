//
//  ORXLGPSModel.m
//  Orca
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORXLGPSModel.h"
#import "NetSocket.h"

#pragma mark •••Definitions
#define kGPSPort 23

NSString* ORXLGPSModelLock		= @"ORXLGPSModelLock";
NSString* ORXLGPSIPNumberChanged	= @"ORXLGPSIPNumberChanged";
NSString* ORXLGPSModelUserNameChanged	= @"ORXLGPSModelUserNameChanged";
NSString* ORXLGPSModelPasswordChanged	= @"ORXLGPSModelPasswordChanged";
NSString* ORXLGPSModelTimeOutChanged	= @"ORXLGPSModelTimeOutChanged";


@interface ORXLGPSModel (private)
- (void) doBasicOp;
@end

@implementation ORXLGPSModel
@synthesize timeOut, IPNumberIndex;

#pragma mark •••Initialization

- (id) init
{
	self = [super init];
	userName = @"operator";	//default from the public user guide
	password = @"janus";	//default from the public user guide
	IPNumber = @"";
	timeOut = 0;
	return self;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"XLGPSIcon"]];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connectionHistory release];
	[IPNumber release];
	[userName release];
	[password release];
	timeOut = 0;

	[super dealloc];
}

- (void) wakeUp 
{
	[super wakeUp];
}

- (void) sleep 
{
	[super sleep];
}	

- (void) makeMainController
{
	[self linkToController:@"ORXLGPSController"];
}

- (void) initConnectionHistory
{
	IPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark •••Accessors
- (void) clearConnectionHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
	return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		IPNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:IPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSIPNumberChanged object:self];
	}
}

- (NSString*) userName
{
	return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
	
	[userName autorelease];
	userName = [aUserName copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPasswordChanged object:self];
}

- (NSString*) password
{
	return password;
}

- (void) setPassword:(NSString*)aPassword
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
	
	[password autorelease];
	password = [aPassword copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPasswordChanged object:self];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	
	[self setUserName:	[decoder decodeObjectForKey:@"userName"]];
	[self setPassword:	[decoder decodeObjectForKey:@"password"]];
	[self setIPNumber:	[decoder decodeObjectForKey:@"IPNumber"]];
	[self setTimeOut:	[decoder decodeIntForKey:@"timeOut"]];

	[[self undoManager] enableUndoRegistration];
	return self;	
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:userName	forKey:@"userName"];
	[encoder encodeObject:password	forKey:@"password"];
	[encoder encodeObject:IPNumber	forKey:@"IPNumber"];
	[encoder encodeInt:timeOut	forKey:@"timeOut"];	
}

#pragma mark •••Hardware Access
#pragma mark •••Basic Ops
@end


@implementation ORXLGPSModel (private)
- (void) doBasicOp
{
}

@end

