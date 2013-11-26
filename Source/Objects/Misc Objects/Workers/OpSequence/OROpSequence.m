//
//  OrcaScriptModel.m
//  OROpSeq
//
//  Created by Mark Howe on 11/24/13.
//
//

#import "OROpSequence.h"
#import "OROpSequenceQueue.h"
#import "OROpSeqStep.h"
NSArray *ScriptSteps();

NSString* OROpSeqStepsChanged = @"OROpSeqStepsChanged";

@implementation OROpSequence

@synthesize steps;
@synthesize state;
@synthesize scriptQueue;
@synthesize delegate;

- (id) initWithDelegate:(id)aDelegate
{
 	self = [super init];
	if (self) {
        delegate = aDelegate;
		scriptQueue = [[OROpSequenceQueue alloc] init];
        state = kOpSeqQueueNeverRun;
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cancel:)
                                                     name:ScriptQueueCancelledNotification
                                                   object:scriptQueue];

        [scriptQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
	}
	return self;
}

- (void) dealloc
{
    [self cancel:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ScriptQueueCancelledNotification
                                                  object:scriptQueue];
    
    [scriptQueue removeObserver:self forKeyPath:@"operationCount"];
    
	[scriptQueue cancelAllOperations];
	[scriptQueue release];
	scriptQueue = nil;
        
	[steps release];
	steps = nil;
    
	[super dealloc];
}

- (void) setSteps:(NSArray *)anArray
{
    [anArray retain];
    [steps release];
    steps = anArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OROpSeqStepsChanged object:self];
}

- (void) start
{	
    if([scriptQueue operationCount]>0){
        [self cancel:nil];
    }
    else {
        if([delegate respondsToSelector:@selector(scriptSteps)]){
            self.steps = [delegate scriptSteps];
            for (OROpSeqStep *step in steps){
                [scriptQueue addOperation:step];
            }
            state = kOpSeqQueueRunning;
        }
    }
}

- (void) cancel:(id)parameter
{
   	if ([[scriptQueue operations] count] > 0) {
		if ([parameter isKindOfClass:[NSNotification class]]) {
			state = kOpSeqQueueFailed;
		}
		else {
			state = kOpSeqQueueCancelled;
		}
        
		[[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ScriptQueueCancelledNotification
                                                      object:scriptQueue];
		[scriptQueue cancelAllOperations];
		while ([[scriptQueue operations] count] > 0) {
			[[NSRunLoop currentRunLoop]
             runMode:NSDefaultRunLoopMode
             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
		[scriptQueue clearState];
	}
	else if ([parameter isKindOfClass:[NSButton class]]){
		[self start];
	}
	else {
		state = kOpSeqQueueFailed;
	} 
}

- (NSArray*) operations
{
    return [scriptQueue operations];
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"operationCount"]) {
        if([[scriptQueue operations] count]==0){
            [self report];
        }
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change
                          context:context];
}

- (void) report
{
    for (OROpSeqStep* step in steps){
        
    }
}

@end
