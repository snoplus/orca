//
//  ORMJDSegmentGroup
//  Orca
//
//  Created by Mark Howe on 11/11/06.
//  Copyright 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORMJDSegmentGroup.h"
#import "ORDetectorSegment.h"

@implementation ORMJDSegmentGroup

#pragma mark •••Map Methods
- (void) readMap:(NSString*)aPath
{
 	[self setMapFile:aPath];
    NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
    
	for(ORDetectorSegment* aSegment in segments){
		[aSegment setHwPresent:NO];
		[aSegment setParams:nil];
	}
    //each line is for one detector, but we break it into two segments. A lo gain and a hi gain segment.
    int detectorIndex = -1;
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			
			if(![aLine hasPrefix:@"--"]){
                detectorIndex = [aLine intValue];
                NSArray* parts = [aLine componentsSeparatedByString:@","];

                if(detectorIndex>=0 && detectorIndex < [segments count]){
                    NSString* loGainLine =   [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                                              [parts objectAtIndex:0],  //segment
                                              [parts objectAtIndex:1],  //VME
                                              [parts objectAtIndex:2],  //Card
                                              [parts objectAtIndex:3],  //Lo Chan
                                              [parts objectAtIndex:5],  //Preamp Chan
                                              [parts objectAtIndex:6],  //HV Crate
                                              [parts objectAtIndex:7],  //HV Card
                                              [parts objectAtIndex:8],  //HV Chan
                                              [parts objectAtIndex:9],  //Det Max Voltage
                                              [parts objectAtIndex:10],  //Det Name
                                              [parts objectAtIndex:11]  //Det Type
                                             ];
                    ORDetectorSegment* aSegment = [segments objectAtIndex:detectorIndex*2];
                    [aSegment decodeLine:loGainLine];
                    [aSegment setObject:[NSNumber numberWithInt:detectorIndex*2] forKey:@"kSegmentNumber"];
                    [aSegment setObject:[NSNumber numberWithInt:detectorIndex] forKey:@"kDetector"];
                    [aSegment setObject:[NSNumber numberWithInt:0] forKey:@"kGainType"];
                }
                if(detectorIndex>=0 && detectorIndex+1 < [segments count]){
                    NSString* hiGainLine =   [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                                              [parts objectAtIndex:0], //segment
                                              [parts objectAtIndex:1], //VME
                                              [parts objectAtIndex:2], //Card
                                              [parts objectAtIndex:4], //Hi Chan
                                              [parts objectAtIndex:5], //Hi Preamp
                                              [parts objectAtIndex:6], //HV Crate
                                              [parts objectAtIndex:7], //HV Card
                                              [parts objectAtIndex:8], //HV Chan
                                              [parts objectAtIndex:9], //Det Name
                                              [parts objectAtIndex:10], //Det Max Voltage
                                              [parts objectAtIndex:11] //Det Type

                                              ];
                    ORDetectorSegment* aSegment = [segments objectAtIndex:detectorIndex*2+1];
                    [aSegment decodeLine:hiGainLine];
                    [aSegment setObject:[NSNumber numberWithInt:detectorIndex*2+1] forKey:@"kSegmentNumber"];
                    [aSegment setObject:[NSNumber numberWithInt:detectorIndex] forKey:@"kDetector"];
                    [aSegment setObject:[NSNumber numberWithInt:1] forKey:@"kGainType"];
               }
            }
        }
    }
	[self configurationChanged:nil];   
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSegmentGroupMapReadNotification
                      object:self];
}

- (void) saveMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    int numSegs = [segments count];
    int i;
    for(i=0;i<numSegs;i+=2){
        ORDetectorSegment* loGainSeg = [segments objectAtIndex:i];
        ORDetectorSegment* hiGainSeg = [segments objectAtIndex:i+1];
        NSString* loGainLine = [loGainSeg paramsAsString];
        NSString* hiGainLine = [hiGainSeg paramsAsString];
        NSArray* loGainPart = [loGainLine componentsSeparatedByString:@","];
        NSArray* hiGainPart = [hiGainLine componentsSeparatedByString:@","];
        int segNum = [[loGainPart objectAtIndex:0] intValue]/2;
        NSString* aLine =   [NSString stringWithFormat:@"%d,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                             segNum,
                             [loGainPart objectAtIndex:1],  //VME
                             [loGainPart objectAtIndex:2],  //Card
                             [loGainPart objectAtIndex:3],  //Lo Chan
                             [hiGainPart objectAtIndex:3],  //fold in the hi gain channel
                             [loGainPart objectAtIndex:4],  //Preamp Chan
                             [loGainPart objectAtIndex:5],  //HV Crate
                             [loGainPart objectAtIndex:6],  //HV Card
                             [loGainPart objectAtIndex:7],  //HV Chan
                             [loGainPart objectAtIndex:8],  //Detector Name
                             [loGainPart objectAtIndex:9],  //Detector max Voltage
                             [loGainPart objectAtIndex:10]   //Detector type
                   ];
        [theContents appendData:[aLine dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeItemAtPath:newFileName error:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
	[self setMapFile:newFileName];
    
}

- (NSString*) paramsAsString
{
    NSMutableString* theContents = [NSMutableString string];
    int numSegs = [segments count];
    int i;
    BOOL headerDone = NO;
    for(i=0;i<numSegs;i+=2){
        ORDetectorSegment* loGainSeg = [segments objectAtIndex:i];
        ORDetectorSegment* hiGainSeg = [segments objectAtIndex:i+1];

        if(!headerDone){
            NSString* paramHeader = [loGainSeg paramHeader];
            paramHeader = [paramHeader stringByReplacingOccurrencesOfString:@"kChannel" withString:@"kChanLo,kChanHi"];
            paramHeader = [paramHeader stringByReplacingOccurrencesOfString:@"kPreAmpChan" withString:@"kPreAmpLo,kPreAmpHi"];
            
            [theContents appendString:paramHeader];
            headerDone = YES;
        }
        NSString* loGainLine = [loGainSeg paramsAsString];
        NSString* hiGainLine = [hiGainSeg paramsAsString];
        NSArray* loGainPart = [loGainLine componentsSeparatedByString:@","];
        NSArray* hiGainPart = [hiGainLine componentsSeparatedByString:@","];
        int segNum = i/2;
        NSString* aLine =   [NSString stringWithFormat:@"%d,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                             segNum,
                             [loGainPart objectAtIndex:1],  //VME
                             [loGainPart objectAtIndex:2],  //Card
                             [loGainPart objectAtIndex:3],  //Lo Chan
                             [hiGainPart objectAtIndex:3],  //fold in the hi gain channel
                             [loGainPart objectAtIndex:4],  //Preamp Chan
                             [loGainPart objectAtIndex:5],  //HV Crate
                             [loGainPart objectAtIndex:6],  //HV Card
                             [loGainPart objectAtIndex:7],  //HV Chan
                             [loGainPart objectAtIndex:8],  //Detector Name
                             [loGainPart objectAtIndex:9],  //Detector Max Voltage
                             [loGainPart objectAtIndex:10]   //Detector Type
                             ];

        [theContents appendString:aLine];
        if(i != numSegs-2)[theContents appendString:@"\n"];
    }
    return theContents;
}


@end
