
#ifndef _H_SBC_CONFIG_
#define _H_SBC_CONFIG_
#include <sys/types.h>
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

// ---------------------------------------------------------------------------- 
//	Generic hardware configuration structure used by both Mac and eCPU code.
#define MAX_CARDS			20

typedef struct {
	unsigned long header;
    unsigned long total_cards;					// total sum of all cards
    struct {									// structure required for card
        unsigned long	hw_type_id;				// unique hardware identifier code
        unsigned long	hw_mask[10];			// hardware identifier mask to OR into data word
		unsigned long	slot;					// slot identifier
		unsigned long	crate;					// crate identifier
		unsigned long	base_add;				// base addresses for each card
		unsigned long   add_mod;				// address modifier (if needed)
		unsigned long	deviceSpecificData[5];	// a card can use this block as needed.
		unsigned long	next_Card_Index;		// next card_info index to be read after this one.		
		unsigned long 	num_Trigger_Indexes;	// number of triggers for this card
		unsigned long	next_Trigger_Index[3];	//card_info index for device specific trigger
	} card_info[MAX_CARDS];
} SBC_crate_config;

#define kSBC_CrateConfigSizeLongs sizeof(SBC_crate_config)/sizeof(unsigned long)
#define kSBC_CrateConfigSizeBytes sizeof(SBC_crate_config)

typedef struct {
	unsigned long statusBits;
	unsigned long readCycles;
	unsigned long bufferSize;
	unsigned long readIndex;
	unsigned long writeIndex;
	unsigned long lostByteCount;
	unsigned long amountInBuffer;
	unsigned long recordsTransfered;
	unsigned long wrapArounds;
} SBC_info_struct;

#define kSBC_ConfigLoadedMask	(0x1 << 0)
#define kSBC_RunningMask		(0x1 << 1)

#define kSBC_InfoStructSizeLongs sizeof(SBC_info_struct)/sizeof(unsigned long)
#define kSBC_InfoStructSizeBytes sizeof(SBC_info_struct)

#endif
