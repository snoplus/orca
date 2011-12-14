//
//  KatrinModel.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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


#pragma mark ¥¥¥Imported Files
#import "ORExperimentModel.h"

#define kUsePixelView 0
#define kUseCrateView 1
#define kUsePreampView 2

#define FLTORBSNFILE(aPath)		[NSString stringWithFormat:@"%@_FltOrbSN",	aPath]
#define PREAMPSNFILE(aPath)		[NSString stringWithFormat:@"%@_PreampSN",	aPath]
#define OSBSNFILE(aPath)		[NSString stringWithFormat:@"%@_OsbSN",		aPath]
#define SLTWAFERSNFILE(aPath)	[NSString stringWithFormat:@"%@_SltWaferSN",aPath]

@interface KatrinModel :  ORExperimentModel
{
	NSString* slowControlName;
	int	      slowControlIsConnected;
	int		  viewType;
	NSMutableArray*		 fltSNs;
	NSMutableArray*		 preAmpSNs;
	NSMutableArray*		 osbSNs;
	NSMutableDictionary* otherSNs;
}
#pragma mark ¥¥¥Accessors
- (NSString*) slowControlName;
- (void) setSlowControlName:(NSString*)aName;
- (BOOL) slowControlIsConnected;
- (void) setSlowControlIsConnected:(BOOL)aState;
- (void) setViewType:(int)aViewType;
- (int) viewType;

#pragma mark ¥¥¥Slow Control Connection Monitoring
- (void) slowControlConnectionChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;

#pragma mark ¥¥¥SN Access Methods
- (id) fltSN:(int)i objectForKey:(id)aKey;
- (void) fltSN:(int)i setObject:(id)anObject forKey:(id)aKey;
- (id) preAmpSN:(int)i objectForKey:(id)aKey;
- (void) preAmpSN:(int)i setObject:(id)anObject forKey:(id)aKey;
- (id) osbSN:(int)i objectForKey:(id)aKey;
- (void) osbSN:(int)i setObject:(id)anObject forKey:(id)aKey;
- (id) otherSNForKey:(id)aKey;
- (void) setOtherSNObject:(id)anObject forKey:(id)aKey;
- (void) readAuxFiles:(NSString*)aPath;
- (void) saveAuxFiles:(NSString*)aPath;
- (NSArray*) linesInFile:(NSString*)aPath;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;
@end

extern NSString* KatrinModelSlowControlIsConnectedChanged;
extern NSString* KatrinModelSlowControlNameChanged;
extern NSString* ORKatrinModelViewTypeChanged;
extern NSString* ORKatrinModelSNTablesChanged;

