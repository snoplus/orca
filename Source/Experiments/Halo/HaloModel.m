//
//  HaloModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "HaloModel.h"
#import "HaloController.h"
#import "ORSegmentGroup.h"

NSString* ORHaloModelViewTypeChanged	= @"ORHaloModelViewTypeChanged";
static NSString* HaloDbConnector		= @"HaloDbConnector";

@implementation HaloModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Halo"]];
}

- (void) makeMainController
{
    [self linkToController:@"HaloController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:HaloDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

//- (NSString*) helpURL
//{
//	return @"Halo/Index.html";
//}

/*- (NSMutableArray*) initMapEntries:(int) index
{
	//default set -- subsclasses can override
	NSMutableArray* mapEntries = [NSMutableArray array];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kBore",          @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kClock",         @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kNCD",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvCrate",       @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvChan",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmp",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserCard",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserChan",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
	return mapEntries;
}
 */

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Halo Tubes" numSegments:kNumTubes mapEntries:[self initMapEntries:0]];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
        NSString* boreName       = [ aGroup segment:index objectForKey:@"kBore"         ];
        NSString* clockName      = [ aGroup segment:index objectForKey:@"kClock"        ];
        NSString* NCDName        = [ aGroup segment:index objectForKey:@"kNCD"          ];
		NSString* cardName       = [ aGroup segment:index objectForKey:@"kCardSlot"     ];
		NSString* chanName       = [ aGroup segment:index objectForKey:@"kChannel"      ];
        NSString* hvCrateName    = [ aGroup segment:index objectForKey:@"kHvCrate"      ];
        NSString* hvChanName     = [ aGroup segment:index objectForKey:@"kHvChan"       ];
        NSString* preAmpName     = [ aGroup segment:index objectForKey:@"kPreAmp"       ];
        NSString* pulserCardName = [ aGroup segment:index objectForKey:@"kPulserCard"   ];
        NSString* pulserChanName = [ aGroup segment:index objectForKey:@"kPulserChan"   ];
        
		if(boreName && clockName && NCDName && cardName && chanName && hvCrateName && hvChanName && preAmpName && pulserCardName && pulserChanName && ![boreName hasPrefix:@"-"] && ![clockName hasPrefix:@"-"] && ![NCDName hasPrefix:@"-"] && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"] && ![hvCrateName hasPrefix:@"-"] && ![hvChanName hasPrefix:@"-"] && ![preAmpName hasPrefix:@"-"] && ![pulserCardName hasPrefix:@"-"] && ![pulserChanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"Shaper", @"Crate  0",
                                                            [NSString stringWithFormat:@"ID %2d",[boreName intValue]],
                                                            [NSString stringWithFormat:@"Clock %2d",[clockName intValue]],
                                                            [NSString stringWithFormat:@"NCD %2d",[NCDName intValue]],
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]], 
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
                                                            [NSString stringWithFormat:@"HV Crate %2d",[hvCrateName intValue]],
                                                            [NSString stringWithFormat:@"HV Chan %2d",[hvChanName intValue]],
                                                            [NSString stringWithFormat:@"Preamp %2d",[preAmpName intValue]],
                                                            [NSString stringWithFormat:@"Pulser Card %2d",[pulserCardName intValue]],
                                                            [NSString stringWithFormat:@"Pulser Chan %2d",[pulserChanName intValue]],
															nil]];
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}
- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
    NSString* crateName      = [ theGroup segment:index objectForKey:@"kCrate"       ];
    //NSString* boreName       = [ theGroup segment:index objectForKey:@"kBore"        ];
    //NSString* clockName      = [ theGroup segment:index objectForKey:@"kClock"       ];
    //NSString* NCDName        = [ theGroup segment:index objectForKey:@"kNCD"         ];
	NSString* cardName       = [ theGroup segment:index objectForKey:@"kCardSlot"    ];
	NSString* chanName       = [ theGroup segment:index objectForKey:@"kChannel"     ];
    //NSString* hvCrateName    = [ theGroup segment:index objectForKey:@"kHvCrate"     ];
    //NSString* hvChanName     = [ theGroup segment:index objectForKey:@"kHvChan"      ];
    //NSString* preAmpName     = [ theGroup segment:index objectForKey:@"kPreAmp"      ];
    //NSString* pulserCardName = [ theGroup segment:index objectForKey:@"kPulserCard"  ];
    //NSString* pulserChanName = [ theGroup segment:index objectForKey:@"kPulserChan"  ];
	
	//return [NSString stringWithFormat:@"Shaper,ID %2d,Clock %2d,NCD %2d,Crate %2d,Card %2d,Channel %2d,HV Crate %2d,HV Chan %2d,Preamp %2d,Pulser Card %2d,Pulser Chan %2d",
            //[boreName       intValue],
            //[clockName      intValue],
            //[NCDName        intValue],
            //[crateName      intValue],
            //[cardName       intValue],
            //[chanName       intValue],
            //[hvCrateName    intValue],
            //[hvChanName     intValue],
            //[preAmpName     intValue],
            //[pulserCardName intValue],
            //[pulserChanName intValue]];
    
    return [NSString stringWithFormat:@"FLT,Energy,Crate %2d,Station %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"HaloMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"HaloDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"HaloDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORHaloModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewType forKey:@"viewType"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"                                                          ];
	finalString = [ finalString stringByAppendingString:@"\n-----------------------\n"                                   ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]       ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Bore" parts:parts]          ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" NCD" parts:parts]           ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Clock" parts:parts]         ];
	finalString = [ finalString stringByAppendingString:@"-----------------------\n"                                     ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]      ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]       ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]     ];
	finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]          ];
	finalString = [ finalString stringByAppendingString:@"-----------------------\n"                                     ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" HvCrate" parts:parts]       ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" HvChan" parts:parts]        ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PreAmp" parts:parts]        ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PulserCard" parts:parts]    ];
    finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PulserChan" parts:parts]    ];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

@end

