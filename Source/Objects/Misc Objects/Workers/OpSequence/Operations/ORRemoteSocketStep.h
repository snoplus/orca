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
	NSArray*               commands;
	ORRemoteSocketModel*   socketObject;
}

@property (retain) NSMutableDictionary*   requirements;
@property (retain) ORRemoteSocketModel*   socketObject;
@property (copy) NSArray*                 commands;

+ (ORRemoteSocketStep*)remoteCommands:(NSArray*)cmds remoteSocket:(ORRemoteSocketModel*)aSocketObj;
- (void) require:(NSString*)aKey value:(NSString*)aValue;

@end
