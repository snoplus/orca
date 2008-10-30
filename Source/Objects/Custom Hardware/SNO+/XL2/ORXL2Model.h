//
//  ORXL2Model.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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
#import "ORSNOCard.h"


@interface ORXL2Model :  ORSNOCard 
{
	@protected
        NSString*		inputConnectorName;
        ORConnector*	inputConnector;		//we won't draw this connector.
        NSString*		outputConnectorName;
        ORConnector*	outputConnector;	//we won't draw this connector.
}

#pragma mark •••Connection Stuff
- (ORConnector*) inputConnector;
- (void)         setInputConnector:(ORConnector*)aConnector;
- (NSString*)    inputConnectorName;
- (void)         setInputConnectorName:(NSString*)aName;
- (ORConnector*) outputConnector;
- (void)         setOutputConnector:(ORConnector*)aConnector;
- (NSString*)    outputConnectorName;
- (void)         setOutputConnectorName:(NSString*)aName;
- (void)         guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void)         guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void)         guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void)		 setCrateNumber:(int)crateNumber;
- (id)			 getXL1;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;


@end


