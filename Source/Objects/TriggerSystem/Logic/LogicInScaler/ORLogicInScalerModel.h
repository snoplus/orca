//
//  ORLogicInScalerModel.h
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright  � 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORTriggerProtocols.h"

@interface ORLogicInScalerModel :  OrcaObject <TriggerBitReading>
{
	unsigned short channel;
	unsigned long lastScalerValue;
	BOOL firstTime;
}
- (unsigned short) channel;
- (void) setChannel:(unsigned short)aChannel;
- (BOOL) evalWithDelegate:(id)anObj;
@end

extern NSString* ORLogicInScalerChanged;

@interface NSObject (ORLogicInScalerModel)
- (int) inputValue:(short)index;
@end

