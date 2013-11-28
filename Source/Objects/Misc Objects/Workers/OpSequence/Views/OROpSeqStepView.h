//
//  ScriptStepView.h
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

#import <Cocoa/Cocoa.h>

typedef enum
{
	kSeqStepPending,
	kSeqStepActive,
	kSeqStepSuccess,
	kSeqStepCancelled,
	kSeqStepSuccessWithWarnings,
	kSeqStepFailed
} enumScriptStepState;

@interface OROpSeqStepView : NSView
{
	BOOL            selected;
	enumScriptStepState state;
	IBOutlet NSProgressIndicator*   progressIndicator;
	IBOutlet NSImageView*           imageView;
	IBOutlet NSTextField*           errorsWarningsLabel;
}

@property (nonatomic,readwrite) enumScriptStepState state;
@property (nonatomic,readwrite) BOOL                selected;

- (void)setErrorsWarningsString:(NSString *)string;

@end
