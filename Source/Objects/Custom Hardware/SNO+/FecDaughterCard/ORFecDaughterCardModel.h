//
//  ORFecDaughterCardModel.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORCard.h"

@interface ORFecDaughterCardModel :  ORCard 
{
	@private
		unsigned char rp1[2];	//RMPUP --ramp voltage up 	(0V to +3.3V)
		unsigned char rp2[2];	//RMP --ramp voltage down 	(-3.3V to 0V)
		unsigned char vli[2];	//VLI					   	(-1V to 1V)
		unsigned char vsi[2];	//VSI						(-2V to 0V)
		unsigned char vt[8];	//VTH--voltage threshold	(-1V to 1V) channel related
		unsigned char vb[16];	//VBAL --balance voltage	(-2V to 4V)
		
		//channel related
		unsigned char ns100width[8];
		unsigned char ns20width[8];
		unsigned char ns20delay[8];
		unsigned char tac0trim[8];
		unsigned char tac1trim[8];
}

#pragma mark •••Initialization

#pragma mark •••Accessors
- (unsigned char) rp1:(short)anIndex;
- (void) setRp1:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) rp2:(short)anIndex;
- (void) setRp2:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vli:(short)anIndex;
- (void) setVli:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vsi:(short)anIndex;
- (void) setVsi:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vt:(short)anIndex;
- (void) setVt:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) vb:(short)anIndex;
- (void) setVb:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns100width:(short)anIndex;
- (void) setNs100width:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns20width:(short)anIndex;
- (void) setNs20width:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) ns20delay:(short)anIndex;
- (void) setNs20delay:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) tac0trim:(short)anIndex;
- (void) setTac0trim:(short)anIndex withValue:(unsigned char)aValue;
- (unsigned char) tac1trim:(short)anIndex;
- (void) setTac1trim:(short)anIndex withValue:(unsigned char)aValue;

#pragma mark •••Hardware Access


@end

#pragma mark •••External String Definitions
extern NSString* ORFec32ModelRp1Changed;
extern NSString* ORFec32ModelRp2Changed;
extern NSString* ORFec32ModelVliChanged;
extern NSString* ORFec32ModelVsiChanged;
extern NSString* ORFec32ModelVtChanged;
extern NSString* ORFec32ModelVbChanged;
extern NSString* ORFec32ModelNs100widthChanged;
extern NSString* ORFec32ModelNs20widthChanged;
extern NSString* ORFec32ModelNs20delayChanged;
extern NSString* ORFec32ModelTac0trimChanged;
extern NSString* ORFec32ModelTac1trimChanged;

