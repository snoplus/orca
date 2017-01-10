//
//  SNOPGlobals.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#ifndef Orca_SNOPGlobals_h
#define Orca_SNOPGlobals_h

/* mutually exclusive run types */
#define MAINTENANCE_RUN         0x1
#define TRANSITION_RUN          0x2
#define PHYSICS_RUN             0x4
#define DEPLOYED_SOURCE_RUN     0x8
#define EXTERNAL_SOURCE_RUN     0x10
#define ECA_RUN                 0x20
#define DIAGNOSTIC_RUN          0x40
#define EXPERIMENTAL_RUN        0x80
#define SUPERNOVA_RUN           0x100
/* calibration */
#define TELLIE_RUN              0x800
#define SMELLIE_RUN             0x1000
#define AMELLIE_RUN             0x2000
#define PCA_RUN                 0x4000
#define ECA_PDST_RUN            0x8000
#define ECA_TSLP_RUN            0x10000
/* detector state */
#define DCR_ACTIVITY_RUN        0x200000
#define COMP_COILS_OFF_RUN      0x400000
#define PMT_OFF_RUN             0x800000
#define BUBBLERS_RUN            0x1000000
#define RECIRCULATION_RUN       0x2000000
#define SLASSAY_RUN             0x4000000
#define UNUSUAL_ACTIVITY_RUN    0x8000000

//Run types
typedef enum kSNOPRunType {
    kDiagnosticRunType = 0x40,
} kSNOPRunType;


#endif
