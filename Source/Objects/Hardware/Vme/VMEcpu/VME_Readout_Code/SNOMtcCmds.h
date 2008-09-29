//-----------------------------------------------------------
//  SNOMtcCmds.h
//  Orca
//  Created by Mark Howe on 9/29/08
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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

#ifndef _H_SNOMTCCMDS_
#define _H_SNOMTCCMDS_

#include <sys/types.h>
#include <stdint.h>
#include "SBC_Cmds.h"

#define kSNOMtcLoadXilinx  0x01

typedef 
	struct {
		int32_t baseAddress;
		int32_t addressModifier;
		int32_t programRegOffset;
        uint32_t errorCode;		/*filled on return*/
		int32_t fileSize;		/*zero on return*/
		//raw file data will follow
	}
SNOMtc_XilinxLoadStruct;

#endif
