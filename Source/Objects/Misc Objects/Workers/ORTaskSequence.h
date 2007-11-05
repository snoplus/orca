//
//  ORTaskSequence.h
//  Orca
//
//  Created by Mark Howe on 2/24/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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





@interface ORTaskSequence : NSObject {
	NSMutableArray* tasks;
	id delegate;
	BOOL verbose;
	BOOL textToDelegate;
}
+ (id) taskSequenceWithDelegate:(id)aDelegate;
- (id) initWithDelegate:(id)aDelegate;
- (void) dealloc;

- (void) addTask:(NSString*)aTask arguments:(NSArray*)theParams;
- (void) addTaskObj:(id)aTask;
- (void) launch;
- (void) setVerbose:(BOOL)flag;
- (void) setTextToDelegate:(BOOL)flag;
- (void) taskCompleted: (NSNotification*)aNote;
- (void) taskDataAvailable:(NSNotification*)aNotification;

@end

@interface NSObject (ORTaskSequence)
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSString*)text;
@end