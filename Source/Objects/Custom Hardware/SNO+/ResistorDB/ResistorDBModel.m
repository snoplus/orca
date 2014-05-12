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

NSString* resistorDBQueryLoaded     = @"resistorDBQueryLoaded";

@implementation ResistorDBModel
@synthesize
currentQueryResults = _currentQueryResults;

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"resistor"]];
}

- (void) queryResistorDb:(int)aCrate withCard:(int)aCard withChannel:(int)aChannel
 {
     //view to query (make the request within this string)
     NSString *requestString = [NSString stringWithFormat:@"_design/resistorQuery/_view/pullCrate?key=[%i,%i,%i]",aCrate,aCard,aChannel];
 
     //[[self orcaDbRefWithEntryDB:@"resistor"] getDocumentId:requestString tag:@"kResistorDbHeaderRetrieved"];
     [[self orcaDbRefWithEntryDB:self withDB:@"resistor"] getDocumentId:requestString tag:kResistorDbHeaderRetrieved];
     
     //[self setSmellieDBReadInProgress:YES];
     //[self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
 
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
            //Look through all of the possible tags for ellie couchDB results
            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kResistorDbHeaderRetrieved])
            {
                NSLog(@"here\n");
                //NSLog(@"Object: %@\n",aResult);
                //NSLog(@"result: %@\n",[aResult objectForKey:@"SnoPmt"]);
                [self parseResistorDbResult:aResult];
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
    //look at the crate, card, channel values in here
    //unsigned int i,cnt = [[aResult objectForKey:@"rows"] count];
    
    self.currentQueryResults = [[NSMutableDictionary alloc] init];
    self.currentQueryResults = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"value"];
    
    //NSLog(@"entry: %@",self.currentQueryResults);
    
    /*for(i=0;i<cnt;i++){
        NSLog(@"entry: %@",[[aResult objectForKey:@"rows"] objectAtIndex:i]);
        //value is the value which is returned by the request string
        NSString* resistorDbIterator = [NSString stringWithFormat:@"%@",[[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"]];
        if([resistorDbIterator isEqualToString:snoPmtTest]){
            NSLog(@"entry: %@",[[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"]);
        }
        //NSString *key = [NSString stringWithFormat:@"%u",i];
        //[tmp setObject:resistorDbIterator forKey:key];
    }*/
    
    //make notification here
    [[NSNotificationCenter defaultCenter] postNotificationName:resistorDBQueryLoaded object:self];
    //[self.viewloadingFromDbWheel startAnimation];
    
    //[self setSmellieRunHeaderDocList:tmp];
    //[tmp release];
}



- (void) makeMainController
{
    [self linkToController:@"ResistorDBViewController"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
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