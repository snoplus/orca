//
//  ORProcessHistoryModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORProcessHistoryModel.h"
#import "ORProcessInConnector.h"
#import "ORTimeRate.h"

NSString* ORProcessHistoryModelShowInAltViewChanged = @"ORProcessHistoryModelShowInAltViewChanged";
NSString* ORProcessHistoryModelHistoryLabelChanged = @"ORProcessHistoryModelHistoryLabelChanged";
NSString* ORHistoryElementIn1Connection   = @"ORHistoryElementInConnection1";
NSString* ORHistoryElementIn2Connection   = @"ORHistoryElementInConnection2";
NSString* ORHistoryElementIn3Connection   = @"ORHistoryElementInConnection3";
NSString* ORHistoryElementIn4Connection   = @"ORHistoryElementInConnection4";
NSString* ORHistoryElementDataChanged = @"ORHistoryElementDataChanged";

NSString* historyConnectors[4] = {
	@"ORHistoryElementIn1Connection",
	@"ORHistoryElementIn2Connection",
	@"ORHistoryElementIn3Connection",
	@"ORHistoryElementIn4Connection"
};

@interface ORProcessHistoryModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
@end

@implementation ORProcessHistoryModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
	int i;
	for(i=0;i<4;i++)[inputValue[i] release];
	[lastEval release];
	[super dealloc];
}

#pragma mark ***Accessors

- (BOOL) showInAltView
{
    return showInAltView;
}

- (void) setShowInAltView:(BOOL)aShowInAltView
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowInAltView:showInAltView];
    showInAltView = aShowInAltView;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessHistoryModelShowInAltViewChanged object:self];

	[self postStateChange];
}


- (void) makeConnectors
{
	ORProcessInConnector* inConnector;
	
	float yoffset = 0;
	int i;
	for(i=0;i<4;i++){
		inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,yoffset) withGuardian:self withObjectLink:self];
		[[self connectors] setObject:inConnector forKey:historyConnectors[i]];
		[inConnector setConnectorType: 'LP1 ' ];
		[inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
		[inConnector release];
		yoffset += kConnectorSize;
	}
}


- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeMainController
{
    [self linkToController:@"ORProcessHistoryController"];
}

- (NSString*) elementName
{
	return @"History";
}

- (void) postUpdate
{
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORHistoryElementDataChanged
					  object:self];
}

- (BOOL) canBeInAltView
{
	return showInAltView;
}

- (void) processIsStarting
{
    [super processIsStarting];
	int i;
	for(i=0;i<4;i++){
		id obj = [self objectConnectedTo:historyConnectors[i]];
		[obj processIsStarting];
		[inputValue[i] release];
		inputValue[i] = [[ORTimeRate alloc] init];
		[inputValue[i] setSampleTime:1];
	}
	[lastEval release];
	lastEval = nil;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoryElementDataChanged object:self];
}

- (void) processIsStopping
{
    [super processIsStopping];
	int i;
	for(i=0;i<4;i++){
		id obj = [self objectConnectedTo:historyConnectors[i]];
		[obj processIsStopping];
	}
	[lastEval release];
	lastEval = nil;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHistoryElementDataChanged object:self];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	NSDate* now = [NSDate date];
	if(lastEval == nil || [now timeIntervalSinceDate:lastEval] >= 1){
		[lastEval release];
		lastEval = [now retain];
		int i;
		for(i=0;i<4;i++){
			id obj = [self objectConnectedTo:historyConnectors[i]];
			ORProcessResult* theResult = [obj eval];
			float valueToPlot = [theResult analogValue];
			[inputValue[i] addDataToTimeAverage:valueToPlot];
		}	
		[self performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:NO];
	}
	return nil;
}


//--------------------------------

#pragma mark ¥¥¥Plot Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	int set = [aPlotter tag];
	return [inputValue[set] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	int count = [inputValue[set] count];
	int index = count-i-1;
	*yValue =  [inputValue[set] valueAtIndex:index];
	*xValue =  [inputValue[set] timeSampledAtIndex:index];
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setShowInAltView:[decoder decodeBoolForKey:@"showInAltView"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showInAltView forKey:@"showInAltView"];
}

@end

@implementation ORProcessHistoryModel (private)

- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	
	NSFont* theFont = [NSFont messageFontOfSize:9];
	NSAttributedString* iconLabel =  [[[NSAttributedString alloc] 
											initWithString:[NSString stringWithFormat:@"%d",[self processID]] 
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	NSSize textSize = [iconLabel size];
	NSImage* anImage = [NSImage imageNamed:@"ProcessHistory"];
	
	NSSize theIconSize	= [anImage size];
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	
	[iconLabel drawInRect:NSMakeRect(theIconSize.width - textSize.width - 2,theIconSize.height-textSize.height-3,textSize.width,textSize.height)];
	
    [finalImage unlockFocus];
	return [finalImage autorelease];	
}

- (NSImage*) composeHighLevelIcon
{
	NSFont* theFont = [NSFont messageFontOfSize:10];
	NSAttributedString* iconLabel;
	if([[self customLabel] length]){
		iconLabel =  [[[NSAttributedString alloc] 
				 initWithString:[NSString stringWithFormat:@"%@",[self customLabel]]
				 attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	}
	else {
		iconLabel =  [[[NSAttributedString alloc] 
					   initWithString:[NSString stringWithFormat:@"History %d",[self processID]] 
					   attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
	}
	NSSize textSize = [iconLabel size];
	NSImage* anImage = [NSImage imageNamed:@"ProcessHistoryHL"];
	
	NSSize theIconSize	= [anImage size];
	float textStart		= 60;
		
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	
	[iconLabel drawInRect:NSMakeRect(textStart, 3 , MIN(textSize.width,theIconSize.width-textStart),textSize.height)];
	
    [finalImage unlockFocus];
	return [finalImage autorelease];	
}

@end