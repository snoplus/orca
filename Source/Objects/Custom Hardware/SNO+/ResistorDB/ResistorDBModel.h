//
//  ResistorDBModel.h
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import <Foundation/Foundation.h>
#import "ResistorDBViewController.h"

@class ORCouchDB;

@protocol ResistorDbDelegate <NSObject>
@required
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
@end

@interface ResistorDBModel :  OrcaObject<ResistorDbDelegate>
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void)dealloc;

- (void)queryResistorDb;

@end
