//
//  AcqirisDC440.h
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#include <sys/types.h>
#include "AcqirisDC440Cmds.h"
#include "SBC_Config.h"
#include "SBC_Cmds.h"

void ClearAcqirisInitFlag(void);
char FindAcqirisDC440s(void);
void ReleaseAcqirisDC440s(void);
void processAcquirisDC440Command(SBC_Packet* aPacket);

long configVerical(unsigned long identifier,long channel, double fullScale, double offset, long coupling, long bandwidth);

long Start_AqirisDC440(long index,SBC_crate_config* crate_config );
long Stop_AqirisDC440(long index,SBC_crate_config* crate_config );
void Readout_DC440(long boardID,long numberSamples,long enableMask,long dataID,long location,char restart,char useCB);
