//
//  ORProcessElementModel.h
//  Orca
//
//  Created by Mark Howe on 11/19/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import <OrcaObject.h>

@interface ORProcessElementModel : OrcaObject {
    @protected
        BOOL        alreadyEvaluated;
		int			evaluatedState;
    @private
        int         state;
        NSLock*     processLock;
        NSString*   comment;
		BOOL		partOfRun;
}

#pragma mark ¥¥¥Inialization
- (id) init;
- (void) dealloc;
- (void) setUpNubs;
- (void) awakeAfterDocumentLoaded;

#pragma mark ¥¥¥Accessors
- (NSString*) description:(NSString*)prefix;
- (NSString*) elementName;
- (NSString*)comment;
- (NSString*) shortName;
- (void) setComment:(NSString*)aComment;
- (id) stateValue;
- (void) setState:(int)value;
- (int) state;
- (void) setEvaluatedState:(int)value;
- (int) evaluatedState;
- (Class) guardianClass ;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (BOOL) canImageChangeWithState;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;
- (BOOL) partOfRun;

#pragma mark ¥¥¥Thread Related
- (void) clearAlreadyEvaluatedFlag;
- (BOOL) alreadyEvaluated;
- (void) postStateChange;
- (void) processIsStarting;
- (void) processIsStopping;
- (int) eval;

#pragma mark ¥¥¥Archiving
- (id)initWithCoder:(NSCoder*)decoder;

@end

extern NSString* ORProcessElementStateChangedNotification;
extern NSString* ORProcessCommentChangedNotification;
