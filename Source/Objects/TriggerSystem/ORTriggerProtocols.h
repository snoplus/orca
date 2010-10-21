//
//  ORTriggerProtocols.h
//  Orca
//
//  Created by Mark Howe on 10/13/10.
//  Copyright  � 20010 University of North Carolina. All rights reserved.
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

//these protocols are used to control which trigger 
//logic window the devices can be placed into.

@protocol TriggerLogicIn
@end

@protocol TriggerLogicOut
@end

@protocol TriggerBitReading
@end

@protocol TriggerBitSetting
@end

@protocol TriggerPatternReading
@end

@protocol TriggerChildReadingEndNode
@end

@protocol TriggerControllingIO
- (id) triggerChild:(int)anIndex;
- (unsigned long) getInputWithMask:(unsigned long) aChannelMask;
- (void) setOutputWithMask:(unsigned long) aChannelMask value:(unsigned long) aMaskValue;
@end

@protocol TriggerControllingScaler
- (id) triggerChild:(int)anIndex;
- (unsigned long) counts:(int)aChannel;
@end

