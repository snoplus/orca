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


@interface ResistorDBModel :  OrcaObject<ResistorDbDelegate>{
    NSMutableDictionary *_currentQueryResults;
    NSDictionary* _resistorDocument;
}
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;

@property (nonatomic,copy) NSMutableDictionary *currentQueryResults;
@property (copy) NSDictionary *resistorDocument;

- (void) queryResistorDb:(int)aCrate withCard:(int)aCard withChannel:(int)aChannel;
- (void) updateResistorDb:(NSMutableDictionary*)aResistorDocDic;

@end

extern NSString* resistorDBQueryLoaded;
