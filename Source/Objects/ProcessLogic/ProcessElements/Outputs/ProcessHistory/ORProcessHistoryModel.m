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


@implementation ORProcessHistoryModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
	int i;
	for(i=0;i<4;i++)[inputValue[i] release];
	[lastEval release];
	[super dealloc];
}

-(void)makeConnectors
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
    [self setImage:[NSImage imageNamed:@"ProcessHistory"]];
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


- (void) processIsStarting
{
    [super processIsStarting];
	int i;
	for(i=0;i<4;i++){
		id obj = [self objectConnectedTo:historyConnectors[i]];
		[obj processIsStarting];
		[inputValue[i] release];
		inputValue[i] = [[ORTimeRate alloc] init];
		[inputValue[i] setSampleTime:10];
	}
	[lastEval release];
	lastEval = nil;
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORHistoryElementDataChanged
					  object:self];

	
}


//--------------------------------
//runs in the process logic thread
- (int) eval
{
	NSDate* now = [NSDate date];
	if(lastEval == nil || [now timeIntervalSinceDate:lastEval] >= 1){
		[lastEval release];
		lastEval = [now retain];
		int i;
		for(i=0;i<4;i++){
			[inputValue[i] addDataToTimeAverage:[[self objectConnectedTo:historyConnectors[i]] eval]];
		}	
		[self performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:NO];
	}
	return 0;
}


//--------------------------------

#pragma mark ¥¥¥Plot Data Source
- (int) 	numberOfDataSetsInPlot:(id)aPlotter
{
	return 4;
}
- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return 10;
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [inputValue[set] count];
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	int count = [inputValue[set] count];
	return [inputValue[set] valueAtIndex:count-x-1];
}

@end
