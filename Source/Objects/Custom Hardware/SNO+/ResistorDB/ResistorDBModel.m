//
//  ResistorDBModel.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBModel.h"
#import "ORCouchDB.h"
#import "SNOPModel.h"

#define kResistorDbHeaderRetrieved @"kResistorDbHeaderRetrieved"
#define kResistorDbDocumentPosted @"kResistorDbDocumentPosted"

NSString* resistorDBQueryLoaded     = @"resistorDBQueryLoaded";
NSString* resistorDBUpdated = @"resistorDBUpdated";

@implementation ResistorDBModel
@synthesize
currentQueryResults = _currentQueryResults,
resistorDocument = _resistorDocument;

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"resistor"]];
}


-(void) updateResistorDb:(NSMutableDictionary*)aResistorDocDic
{
    [[self orcaDbRefWithEntryDB:self withDB:@"resistor"] updateDocument:aResistorDocDic documentId:[[self currentQueryResults] objectForKey:@"_id"] tag:kResistorDbDocumentPosted];
    [aResistorDocDic release];
}

- (void) queryResistorDb:(int)aCrate withCard:(int)aCard withChannel:(int)aChannel
 {
     //view to query (make the request within this string)
     NSString *requestString = [NSString stringWithFormat:@"_design/resistorQuery/_view/pullCrate?key=[%i,%i,%i]",aCrate,aCard,aChannel];
    [[self orcaDbRefWithEntryDB:self withDB:@"resistor"] getDocumentId:requestString tag:kResistorDbHeaderRetrieved];
 }

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
    //Loop over all the FEC cards
    NSArray * snopControllerArray = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel * snopModel = [snopControllerArray objectAtIndex:0];
    
    
    ORCouchDB* result = [ORCouchDB couchHost:[snopModel orcaDBIPAddress]
                                        port:[snopModel orcaDBPort]
                                    username:[snopModel orcaDBUserName]
                                         pwd:[snopModel orcaDBPassword]
                                    database:entryDB
                                    delegate:self];
    
    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}

-(void)couchDBResult:(id)aResult tag:(NSString *)aTag op:(id)anOp{
    @synchronized(self){
        if([aResult isKindOfClass:[NSDictionary class]]){
            NSString* message = [aResult objectForKey:@"Message"];
            if(message){
                [aResult prettyPrint:@"CouchDB Message:"];
            }
            if ([aTag isEqualToString:kResistorDbHeaderRetrieved])
            {
                [self parseResistorDbResult:aResult];
            }
            else if ([aTag isEqualToString:kResistorDbDocumentPosted])
            {
                //NSMutableDictionary* resistorDoc = [[[self resistorDocument] mutableCopy] autorelease];
                //[resistorDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                //[resistorDoc setObject:[aResult objectForKey:@"rev"] forKey:@"_rev"];
                //NSLog(@"Posted to ResistorDB %@",resistorDoc);
                //self.resistorDocument = resistorDoc;
                
            }
            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }
        else if([aResult isKindOfClass:[NSArray class]]){
            
            [aResult prettyPrint:@"CouchDB"];
            
        }
        else {
            //no docs found 
        }
    }
}

- (void)parseResistorDbResult:(id)aResult
{
    self.currentQueryResults = [[NSMutableDictionary alloc] init];
    self.currentQueryResults = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"value"];

    //make notification here to tell controller that this has changed 
    [[NSNotificationCenter defaultCenter] postNotificationName:resistorDBQueryLoaded object:self];
}



- (void) makeMainController
{
    [self linkToController:@"ResistorDBViewController"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    self.resistorDocument = nil;
}

- (void) sleep
{
	[super sleep];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[super dealloc];
}

@end
