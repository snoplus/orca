//-------------------------------------------------------------------------
//  ORPQModel.h
//
//  Created by Mark A. Howe on Wednesday 10/18/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#define kSnoCrates          20
#define kSnoCardsPerCrate   16
#define kSnoChannelsPerCard 32
#define kSnoCardsTotal      (kSnoCrates * kSnoCardsPerCrate)
#define kSnoChannels        (kSnoCardsTotal * kSnoChannelsPerCard)

// indices for PQ_FEC valid flags
// (all except hvDisabled must have the same numbers as the column numbers when reading the detector db)
enum {
    kFEC_exists,    // set to 1 if card exists in current detector state (if 0, all elements except hvDisabled will be invalid)
    kFEC_hvDisabled,
    kFEC_nhit100enabled,
    kFEC_nhit100delay,
    kFEC_nhit20enabled,
    kFEC_nhit20width,
    kFEC_nhit20delay,
    kFEC_vbal0,
    kFEC_vbal1,
    kFEC_tac0trim,  // (tcmos_tacshift in the database)
    kFEC_tac1trim,  // (scmos in the database)
    kFEC_vthr,
    kFEC_pedEnabled,
    kFEC_seqDisabled,
    kFEC_tdiscRp1,  // (tdisc_rmpup in the database)
    kFEC_tdiscRp2,  // (tdisc_rmp in the database)
    kFEC_tdiscVsi,
    kFEC_tdiscVli,
    kFEC_tcmosVmax,
    kFEC_tcmosTacref,
    kFEC_tcmosIsetm,
    kFEC_tcmosIseta,
    kFEC_vres,      // (vint in the database)
    kFEC_hvref,
    kFEC_numDbColumns
};

#define kNumFecTdisc    8
#define kNumFecIset     2

typedef struct {
    int32_t         hvDisabled;   // resistor pulled or no cable
    int32_t         nhit100enabled;
    unsigned char   nhit100delay[kSnoChannelsPerCard];
    int32_t         nhit20enabled;
    unsigned char   nhit20width[kSnoChannelsPerCard];
    unsigned char   nhit20delay[kSnoChannelsPerCard];
    unsigned char   vbal0[kSnoChannelsPerCard];
    unsigned char   vbal1[kSnoChannelsPerCard];
    unsigned char   tac0trim[kSnoChannelsPerCard];
    unsigned char   tac1trim[kSnoChannelsPerCard];
    unsigned char   vthr[kSnoChannelsPerCard];
    int32_t         pedEnabled;
    int32_t         seqDisabled;
    unsigned char   tdiscRp1[kNumFecTdisc];
    unsigned char   tdiscRp2[kNumFecTdisc];
    unsigned char   tdiscVsi[kNumFecTdisc];
    unsigned char   tdiscVli[kNumFecTdisc];
    int32_t         tcmosVmax;
    int32_t         tcmosTacref;
    int32_t         tcmosIsetm[kNumFecIset];
    int32_t         tcmosIseta[kNumFecIset];
    int32_t         vres;
    int32_t         hvref;
    int32_t         valid[kFEC_numDbColumns];   // bitmasks for settings loaded from hardware (see enum above)
} PQ_FEC;

enum {
    kMTC_controlReg,
    kMTC_mtcaDacs,
    kMTC_pedWidth,
    kMTC_coarseDelay,
    kMTC_fineDelay,
    kMTC_pedMask,
    kMTC_prescale,
    kMTC_lockoutWidth,
    kMTC_gtMask,
    kMTC_gtCrateMask,
    kMTC_mtcaRelays,
    kMTC_numDbColumns,
};

#define kNumMtcDacs     14
#define kNumMtcRelays   7

typedef struct {
    int32_t     controlReg;
    int32_t     mtcaDacs[kNumMtcDacs];
    int32_t     pedWidth;
    int32_t     coarseDelay;
    int32_t     fineDelay;
    int32_t     pedMask;
    int32_t     prescale;
    int32_t     lockoutWidth;
    int32_t     gtMask;
    int32_t     gtCrateMask;
    int32_t     mtcaRelays[kNumMtcRelays];
    int32_t     valid[kMTC_numDbColumns];
} PQ_MTC;

enum {
    kCrate_exists,
    kCrate_ctcDelay,
    kCrate_hvRelayMask1,
    kCrate_hvRelayMask2,
    kCrate_hvAOn,
    kCrate_hvBOn,
    kCrate_hvDacA,
    kCrate_hvDacB,
    kCrate_xl3ReadoutMask,
    kCrate_xl3Mode,
    kCrate_numDbColumns,
};

typedef struct {
    int32_t     exists;
    int32_t     ctcDelay;
    int32_t     hvRelayMask1;
    int32_t     hvRelayMask2;
    int32_t     hvAOn;
    int32_t     hvBOn;
    int32_t     hvDacA;
    int32_t     hvDacB;
    int32_t     xl3ReadoutMask;
    int32_t     xl3Mode;
    int32_t     valid[kCrate_numDbColumns];
} PQ_Crate;

enum {
    kCAEN_channelConfiguration,
    kCAEN_bufferOrganization,
    kCAEN_customSize,
    kCAEN_acquisitionControl,
    kCAEN_triggerMask,
    kCAEN_triggerOutMask,
    kCAEN_postTrigger,
    kCAEN_frontPanelIoControl,
    kCAEN_channelMask,
    kCAEN_channelDacs,
    kCAEN_numDbColumns,
};

#define kNumCaenChannelDacs 8

typedef struct {
    int32_t     channelConfiguration;
    int32_t     bufferOrganization;
    int32_t     customSize;
    int32_t     acquisitionControl;
    int32_t     triggerMask;
    int32_t     triggerOutMask;
    int32_t     postTrigger;
    int32_t     frontPanelIoControl;
    int32_t     channelMask;
    int32_t     channelDacs[kNumCaenChannelDacs];
    int32_t     valid[kCAEN_numDbColumns];
} PQ_CAEN;

//----------------------------------------------------------------------------------------------------
@interface ORPQDetectorDB : NSMutableData
{
@private
    NSMutableData * data;
@public
    bool        pmthvLoaded;
    bool        fecLoaded;
    bool        crateLoaded;
    bool        mtcLoaded;
    bool        caenLoaded;
}

- (id)          init;
- (void)        dealloc;
- (PQ_FEC *)    getFEC:(int)aCard crate:(int)aCrate;
- (PQ_Crate *)  getCrate:(int)aCrate;
- (PQ_MTC *)    getMTC;
- (PQ_CAEN *)   getCAEN;

@end
//----------------------------------------------------------------------------------------------------

@class ORPQConnection;
@class ORPQModel;
@class ORPQResult;
@class NSMutableData;

@interface ORPQModel : OrcaObject
{
@private
	ORPQConnection* pqConnection;
	NSString*	hostName;
    NSString*	userName;
    NSString*	password;
    NSString*	dataBaseName;
    BOOL		stealthMode;
}

+ (ORPQModel *)getCurrent;

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;

#pragma mark ***Accessors

/**
 @brief Arbitrary detector db query
 @param aCommand PostgreSQL command string
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQResult object, or nil on error)
 @param aTimeoutSecs Timeout time in seconds (0 for no timeout)
 */
- (void) dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector timeout:(float)aTimeoutSecs;

/**
 @brief Arbitrary detector db query with no timeout
 @param aCommand PostgreSQL command string
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQResult object, or nil on error)
 */
- (void) dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector;

/**
 @brief Arbitrary detector db query with no callback or timeout
 @param aCommand PostgreSQL command string
 */
- (void) dbQuery:(NSString*)aCommand;

/**
 @brief Get SNO+ detector database
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQDetectorDB object, or nil on error)
 */
- (void) detectorDbQuery:(id)anObject selector:(SEL)aSelector;

- (void) cancelDbQueries;
- (BOOL) stealthMode;
- (void) setStealthMode:(BOOL)aStealthMode;
- (NSString*) dataBaseName;
- (void) setDataBaseName:(NSString*)aDataBaseName;
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) hostName;
- (void) setHostName:(NSString*)aHostName;
- (void) logQueryException:(NSException*)e;
- (id) nextObject;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***SQL Access
- (BOOL) testConnection;
- (BOOL) connected;
- (void) disconnectSql;

@end

extern NSString* ORPQModelStealthModeChanged;
extern NSString* ORPQDataBaseNameChanged;
extern NSString* ORPQPasswordChanged;
extern NSString* ORPQUserNameChanged;
extern NSString* ORPQHostNameChanged;
extern NSString* ORPQConnectionValidChanged;
extern NSString* ORPQDetectorStateChanged;
extern NSString* ORPQLock;


@interface ORPQOperation : NSOperation
{
    id delegate;
    id object;      // object for callback
    SEL selector;   // selector for main thread callback when done (no callback if nil)
}

- (id)	 initWithDelegate:(id)aDelegate;
- (id)	 initWithDelegate:(id)aDelegate object:(id)anObject selector:(SEL)aSelector;
- (void) dealloc;
@end

@interface ORRunState : NSObject
{
    @public int run;
    @public int state;
}
@end

enum ePQCommandType {
    kPQCommandType_General,
    kPQCommandType_GetDetectorDB,
};

@interface ORPQQueryOp : ORPQOperation
{
    NSString *command;
    int commandType;
}
- (void) setCommand:(NSString*)aCommand;
- (void) setCommandType:(int)aCommandType;
- (ORPQDetectorDB *) loadDetectorDB:(ORPQConnection*)pqConnection;
- (void) _detectorDbCallback:(NSMutableData*)data;
- (void) cancel;
- (void) main;
@end

#define kClear 0
#define kPost  1
@interface ORPQPostAlarmOp : ORPQOperation
{
	BOOL opType;
	id alarm;
}
- (void) dealloc;
- (void) postAlarm:(id)anAlarm;
- (void) clearAlarm:(id)anAlarm;
- (void) main;
@end

