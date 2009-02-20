//
//  ORIpeSlowControlDefs.h
//
//  Created by Till Bergmann on 01/16/2009.
//  Copyright 2009  KIT, IPE. All rights reserved.
//-----------------------------------------------------------


/** IpeSlowControl event structure. 
  *
  *  
  */
typedef struct {
	long dataRound;
	long dataDecimalPlaces;
	long timestampSec;
	long timestampSubSec;
} ipeSlowControlChannelDataStruct;
