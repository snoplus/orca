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

// indices for SnoPlusCard valid flags
// (all except hvDisabled must have the same numbers as the column numbers when reading the detector db)
enum {
    kCardExists,        // set to 1 if card exists in current detector state
    kHvDisabled,
    kNhit100enabled,
    kNhit100delay,
    kNhit20enabled,
    kNhit20width,
    kNhit20delay,
    kVbal0,
    kVbal1,
    kTac0trim,
    kTac1trim,
    kVthr,
    kPedEnabled,
    kSeqDisabled,
    kNumCardDbColumns
};

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
    int32_t         valid[kNumCardDbColumns];   // bitmasks for settings loaded from hardware (see enum above)
} SnoPlusCard;

@class ORPQConnection;
@class ORPQModel;

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
 @brief Get SNO+ card database
 @param anObject Callback object
 @param aSelector Callback object selector (called with an NSMutableData object
 containing an array of SnoPlusCard structures in detector crate/card order, or nil on error)
 */
- (void) cardDbQuery:(id)anObject selector:(SEL)aSelector;

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
    kPQCommandType_GetCardDB,
};

@interface ORPQQueryOp : ORPQOperation
{
    NSString *command;
    int commandType;
}
- (void) setCommand:(NSString*)aCommand;
- (void) setCommandType:(int)aCommandType;
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

