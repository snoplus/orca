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

@interface ResistorDBModel :  OrcaObject
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void)dealloc;

@end
