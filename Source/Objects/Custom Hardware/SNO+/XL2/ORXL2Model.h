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

// SNTR XL2 register indices, Changed 4/13/97 for new XL2, JB
#define XL2_SELECT_REG							0
#define XL2_DATA_AVAILABLE_REG					1
#define XL2_CONTROL_STATUS_REG					2
#define XL2_MASK_REG							3
#define XL2_CLOCK_CS_REG						4
#define XL2_HV_RELAY_CONTROL					5
#define XL2_XILINX_USER_CONTROL					6
#define XL2_GEN_RW_DISPLAY_TEST					7
#define XL2_HV_CS_REG							8
#define XL2_HV_SETPOINTS_REG					9
#define XL2_HV_VOLTAGE_READ_REG					10
#define XL2_HV_CURRENT_READ_REG					11

@interface ORXL2Model :  ORSNOCard 
{
	@protected
        ORConnector*	inputConnector;		//we won't draw this connector.
        ORConnector*	outputConnector;	//we won't draw this connector.
}

#pragma mark •••Connection Stuff
- (ORConnector*) inputConnector;
- (void)         setInputConnector:(ORConnector*)aConnector;
- (ORConnector*) outputConnector;
- (void)         setOutputConnector:(ORConnector*)aConnector;
- (void)         guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void)         guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void)         guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void)		 setCrateNumber:(int)crateNumber;
- (id)			 getXL1;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (unsigned long) xl2RegAddress:(unsigned long)aRegOffset;
- (void) selectCards:(unsigned long) selectBits;
- (void) deselectCards;
- (void) select:(ORSNOCard*) aCard;
- (void) writeToXL2Register:(unsigned long) aRegister value:(unsigned long) aValue;
- (unsigned long) readFromXL2Register:(unsigned long) aRegister;
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;

@end

@interface NSObject (ORXL2Model)
- (int) stationNumber;
@end
