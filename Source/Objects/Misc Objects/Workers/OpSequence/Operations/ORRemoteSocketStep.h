//
//  TaskStep.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OROpSeqStep.h"
@class ORRemoteSocketModel;

@interface ORRemoteSocketStep : OROpSeqStep
{
	NSMutableDictionary*   requirements;
	NSMutableArray*        commands;
	ORRemoteSocketModel*   socketObject;
    NSNumber*              cmdIndexToExecute;
}

@property (retain) NSMutableDictionary*   requirements;
@property (retain) ORRemoteSocketModel*   socketObject;
@property (retain) NSMutableArray*        commands;
@property (retain) NSNumber*              cmdIndexToExecute;

+ (ORRemoteSocketStep*)remoteSocket:(ORRemoteSocketModel*)aSocketObj commandSelection:(id)anIndex commands:(NSString *)aCmd, ... NS_REQUIRES_NIL_TERMINATION;
- (void) require:(NSString*)aKey value:(NSString*)aValue;
- (void) executeCmd:(NSString*)aCmd;

@end
