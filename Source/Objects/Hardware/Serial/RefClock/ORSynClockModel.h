//--------------------------------------------------------
// ORSynClockModel
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, November 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

@class ORRefClockModel;


#define nLastMsgs 10

@interface ORSynClockModel : NSObject
{
    @private
        ORRefClockModel*    refClock;
        int                 trackMode;
        int                 syncMode;
        unsigned int       alarmWindow;
        // int reTxCount;  // in case of errors or timeout retransmit; if retransmit
        // // is required, put last command to cmdQueue and dequeueFromBottom
        //
        BOOL                statusPoll;
        NSMutableArray*     previousStatusMessages;
        NSString*           clockID;
}

#pragma mark ***Initialization
- (void) dealloc;
- (void) setRefClock:(ORRefClockModel*)aRefClock;

#pragma mark ***Accessors
- (void) reset;
- (void) requestID;
- (void) requestStatus;
- (BOOL) statusPoll;
- (void) setStatusPoll:(BOOL)aStatusPoll;
- (NSString*) statusMessages;  // returns the statusses of nLastMsgs previeous requests for display
- (NSString*) clockID;
- (BOOL) portIsOpen;
- (int) trackMode;
- (void) setTrackMode:(int)aMode;
- (int) syncMode;
- (void) setSyncMode:(int)aMode;
- (unsigned long) alarmWindow;
- (void) setAlarmWindow:(unsigned int)aValue;

#pragma mark ***Commands
- (void) writeData:(NSDictionary*)aDictionary;
- (void) processResponse:(NSData*)someData forRequest:(NSDictionary*)lastRequest;
- (NSDictionary*) resetCommand;
- (NSDictionary*) errMessgOffCommand;
- (NSDictionary*) alarmWindowCommand:(unsigned int)nanoseconds;
- (NSDictionary*) statusCommand;
- (NSDictionary*) iDCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORSynClockModelTrackModeChanged;
extern NSString* ORSynClockModelSyncChanged;
extern NSString* ORSynClockModelAlarmWindowChanged;
extern NSString* ORSynClockModelStatusChanged;
extern NSString* ORSynClockModelStatusPollChanged;
extern NSString* ORSynClockModelStatusOutputChanged;
extern NSString* ORSynClockStatusUpdated;
extern NSString* ORSynClockIDChanged;

