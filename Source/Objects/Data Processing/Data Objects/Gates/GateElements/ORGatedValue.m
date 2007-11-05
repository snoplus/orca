//
//  ORGatedValue.m
//  Orca
//
//  Created by Mark Howe on 1/24/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORGatedValue.h"
#import "ORGateGroup.h"
#import "ORDataSet.h"

@implementation ORGatedValue

+ (id) gatedValue
{
    ORGatedValue* aGatedValue = [[[ORGatedValue alloc] initWithCrate:0 
                                                             card:0 
                                                          channel:0] autorelease];
    return aGatedValue;
}



- (void) processData:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet
{
    gateData* theGateData = (gateData*)[someData bytes];
    gateData* end = (gateData*)([someData bytes] + [someData length]);
    while(theGateData<end) {
        if( (theGateData->crate == crateNumber) && (theGateData->card == card) && (theGateData->channel == channel)){
            [gate valueAccepted:theGateData->value gate:self dataSet:(ORDataSet*)aDataSet];
            break;
        }
        theGateData++;
    }
    return;
}


- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* gateDictionary = [NSMutableDictionary dictionary];
    gateDictionary = [super captureCurrentState:gateDictionary];
    
    [dictionary setObject:gateDictionary forKey:@"GatedValue"];

    return dictionary;
}
@end
