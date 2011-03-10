//
//  ORXLGPSModel.h
//  Orca
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
@class NetSocket;

@interface ORXLGPSModel : OrcaObject
{
	NSMutableArray*		connectionHistory;
	NSUInteger		IPNumberIndex;
	NSString*		IPNumber;
	NSString*		userName;
	NSString*		password;
	NSUInteger		timeOut;
	NSTask*			pingTask;
	NetSocket*		socket;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) wakeUp;
- (void) sleep;
- (void) initConnectionHistory;

#pragma mark •••Accessors
@property (copy)	NSString*	IPNumber;
@property (assign)	NSUInteger	IPNumberIndex;
@property (copy)	NSString*	userName;
@property (copy)	NSString*	password;
@property (assign)	NSUInteger	timeOut;

- (void) clearConnectionHistory;
- (unsigned) connectionHistoryCount;
- (id) connectionHistoryItem:(unsigned)index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
//connect
//disconnect
//disconnectDate

#pragma mark •••Basic Ops
#pragma mark •••Composite


@end

extern NSString* ORXLGPSModelLock;
extern NSString* ORXLGPSIPNumberChanged;
extern NSString* ORXLGPSModelUserNameChanged;
extern NSString* ORXLGPSModelPasswordChanged;
extern NSString* ORXLGPSModelTimeOutChanged;
