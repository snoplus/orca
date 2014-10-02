//
//  SNOP_Run_Constants.h
//  Orca
//
//  Created by Chris Jones on 01/08/2014.
//
//

/*typedef struct  {
	int   runValue;
	NSString*	runString;
} runType;*/

//These constants define the numerical values of different run types in SNO+
//runType kRunUndefined = {0, [NSString stringWithFormat:@"Undefined"]};
#define kRunUndefined                               0
#define kRunMaintainence                            1
#define kRunStandardPhysicsRun                      2
#define kRunStandardPhysicsRunWithoutTellie         3
#define kRunTellie                                  4
#define kRunSmellie                                 5
#define kRunAmellie                                 6
#define kRunEca                                     7
#define kRunPca                                     8

