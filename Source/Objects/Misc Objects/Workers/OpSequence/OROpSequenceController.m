//
//  OROpSequenceController
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

#import "OROpSequenceController.h"
#import "OROpSequenceQueue.h"
#import "OROpSequence.h"
#import "OROpSeqStep.h"

@implementation OROpSequenceController

- (void)dealloc
{
	[[[owner model] scriptModel:idIndex] cancel:nil];
    
	[stepsController removeObserver:self forKeyPath:@"selectionIndex"];
    [[[[owner model] scriptModel:idIndex]scriptQueue] removeObserver:self forKeyPath:@"operationCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}
- (void) setIdIndex:(int)aValue;
{
    idIndex = aValue;
}
- (int) idIndex { return idIndex;}

- (void)awakeFromNib
{
    if(!portControlsContent){
		if ([NSBundle loadNibNamed:@"OpSequence" owner:self]){
			[portControlsView setContentView:portControlsContent];
		}
		else NSLog(@"Failed to load SerialPortControls.nib");
	}

 	[self updateProgressDisplay];
    
	[stepsController addObserver:self forKeyPath:@"selectionIndex" options:0 context:NULL];
	
    [[[[owner model] scriptModel:idIndex]scriptQueue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];

    [self registerNotificationObservers];
    
	[collectionView setMinItemSize:NSMakeSize(150, 40)];
	[collectionView setMaxItemSize:NSMakeSize(CGFLOAT_MAX, 40)];
    [collectionView setBackgroundColors:[NSArray arrayWithObject:[NSColor clearColor]]];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter addObserver : self
                     selector : @selector(stepsChanged:)
                         name : OROpSeqStepsChanged
                       object : nil];

}

- (void) stepsChanged:(NSNotification*)aNote
{
    [stepsController setContent:[self steps]];
}

//
// start
//
// Calls the ScriptSteps function to get the array of script steps and then
// adds them all to the queue.
//
- (IBAction)start:(id)sender
{
    [[[owner model] scriptModel:idIndex] start];
}

- (NSArray*)steps
{
    return [[[owner model] scriptModel:idIndex] steps];
}

//
// updateProgressDisplay
//
// Update the progress text and progress indicator. Possibly update the
// cancel/restart button if we've reached the end of the queue
//
- (void)updateProgressDisplay
{
    NSArray*  steps      = [[[owner model] scriptModel:idIndex] steps];
	NSInteger total      = [steps count];
	NSArray*  operations = [[[owner model] scriptModel:idIndex] operations];
	NSInteger remaining  = [operations count];
	
	//
	// Try to get the remaining count as it corresponds to the "steps" array as
	// the actual scriptQueue may have changed due to cancelled steps or other
	// dynamic changes.
	//
	if (remaining > 0){
		NSInteger stepsIndex = [steps indexOfObject:[operations objectAtIndex:0]];
		if (stepsIndex != NSNotFound){
			remaining = total - stepsIndex;
		}
	}
	
	if (remaining == 0) {
		switch ([(OROpSequence*)[[owner model] scriptModel:idIndex]state]){
			case kOpSeqQueueRunning:
			case kOpSeqQueueFinished:
                {
                    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S" allowNaturalLanguage:NO];
                    NSString* dateString           = [dateFormatter stringFromDate:[NSDate date]];
                    [dateFormatter release];
                    [progressLabel setStringValue:[NSString stringWithFormat:@"Done @ %@",dateString]];
                }
				break;
			case kOpSeqQueueFailed:
				[progressLabel setStringValue:@"Failed with error."];
				break;
			case kOpSeqQueueCancelled:
				[progressLabel setStringValue:@"Cancelled."];
				break;
            case kOpSeqQueueNeverRun:
				[progressLabel setStringValue:@"Has Never Run"];
				break;
		}
		[progressIndicator setDoubleValue:0];
		[cancelButton setTitle:@"Run"];
	}
	else {
		[cancelButton setTitle:@"Cancel"];
		[progressLabel setStringValue: [NSString stringWithFormat:
                                            @"Finished %d/%ld",
                                            total - remaining,
                                            (long)total]];
		[progressIndicator setMaxValue:   (double) total];
		[progressIndicator setDoubleValue:(double) (total - remaining)];
	}
	
	//
	// If the step that just finished was selected, advance the selection to the
	// next running step
	//
	if ([stepsController selectionIndex] == lastKnownStepIndex &&
		remaining != 0) {
		[stepsController setSelectionIndex:total - remaining];
	}
	lastKnownStepIndex = total - remaining;
}

//
// cancel:
//
// Cancels the queue (if operations count is > 0) and waits for all operations
// to be cleared correctly.
// If operations count == 0, restarts the queue.
//
// Parameters:
//    parameter - this method may be invoked in 3 situations (distinguished by
//		this parameter)
//		1) Notification from the ScriptQueue that cancelAllOperations was invoked
//			(generally due to error)
//		2) NSButton (user action). This may restart the queue.
//		3) nil (when the window controller is being deleted)
//
- (IBAction)cancel:(id)parameter
{
    [[[owner model] scriptModel:idIndex] cancel:parameter];
    [self updateProgressDisplay];
}

//
// observeValueForKeyPath:ofObject:change:context:
//
// Reponds to changes in the ScriptQueue steps or the selected step
//
// Parameters:
//    keyPath - the property
//    object - the object
//    change - the change
//    context - the context
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"operationCount"]) {
		[self performSelectorOnMainThread:@selector(updateProgressDisplay)
			withObject:nil waitUntilDone:NO];
		return;
	}
	else if ([keyPath isEqual:@"selectionIndex"])
	{
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change
		context:context];
}

@end
