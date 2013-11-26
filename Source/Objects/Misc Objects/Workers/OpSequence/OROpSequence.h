//
//  OrcaScriptModel.h
//  CocoaScript
//
//  Created by Mark Howe on 11/24/13.
//
//

#import <Foundation/Foundation.h>
@class OROpSequenceQueue;

typedef enum
{
	kOpSeqQueueNeverRun,
	kOpSeqQueueRunning,
	kOpSeqQueueFinished,
	kOpSeqQueueFailed,
	kOpSeqQueueCancelled
} enumOpSeqQueueState;

@interface OROpSequence : NSObject
{
    id                  delegate;
    enumOpSeqQueueState state;
	OROpSequenceQueue*  scriptQueue;
	NSArray*            steps;
}
- (id)   initWithDelegate:(id)aDelegate;
- (void) start;
- (void)cancel:(id)parameter;
- (NSArray*) operations;

@property (nonatomic, assign) enumOpSeqQueueState  state;
@property (nonatomic, retain) NSArray*             steps;
@property (assign)            id                   delegate;
@property (nonatomic, retain, readonly) OROpSequenceQueue* scriptQueue;

@end

extern NSString* OROpSeqStepsChanged;

@interface NSObject (OROpSequence)
-(NSArray*) scriptSteps;
@end;