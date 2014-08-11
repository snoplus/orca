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
#import "ORFec32Model.h"

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
    
    [self loadPmtOnlineMaskToFe32FromCouchDb];
}

-(void) loadPmtOnlineMaskToFe32FromCouchDb
{
    
    //Fetch a view from the PMT resistor Database
    
    /////http:localhost:5984/resistor/_design/resistorQuery/_view/getPmtOnlineMask
    //NSURL *url = [NSURL URLWithString:@"http:localhost:5984/resistor/_design/resistorQuery/_view/getPmtOnlineMask"];
    //NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //NSLog(@"%@",connection);
    //Fetch a view from the PMT Database (different to the PMT Resistor Database)
    
    NSHTTPURLResponse *response = nil;
	NSError *connectionError;
	
	NSString *urlName=[[NSString alloc] initWithFormat:
                       @"http:localhost:5984/resistor/_design/resistorQuery/_view/getPmtOnlineMask"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:urlName] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:1];
	NSData *responseData = [[NSData alloc] initWithData:
                            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
    
    //this jsonObject contains all the responses from a view 
    NSDictionary *couchDbQueryResponse=[NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingMutableLeaves
                              error:nil];
    
    
    //Loop over all the FEC cards
    NSArray * fec32ControllerObjs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    
    //Count all Fec32 Cards on the DAQ
    int numberFec32Cards = [fec32ControllerObjs count];
            
    //extract the channel status from the json file for a given crate,card,channel
    //loop through the couchDb response to see pick out the crate and slot for this channel
    //BAD CODE: this assumes these arrive in groups of 32 ordered sets 
    int counter = 0;
    unsigned long aPmtMask = 0;
    for(id key in [couchDbQueryResponse objectForKey:@"rows"]){
        
        //NSMutableDictionary *printString = [key mutableCopy];
        NSArray* keyString = [key objectForKey:@"key"]; //this key contains [crate,card,channel]
        NSArray* valueString = [key objectForKey:@"value"]; //this value contains [resistor pulled, cable pulled, pmt removed]
        NSNumber * crateFromDb = [NSNumber numberWithInt:[[keyString objectAtIndex:0] intValue]];
        NSNumber * cardFromDb = [NSNumber numberWithInt:[[keyString objectAtIndex:1] intValue]];
        NSNumber * channelFromDb = [NSNumber numberWithInt:[[keyString objectAtIndex:2] intValue]];
        
        NSNumber * resistorPulled = [NSNumber numberWithInt:[[valueString objectAtIndex:0] intValue]];
        
        if([resistorPulled intValue] == 0){
            //add a bitwise value to the channel
            aPmtMask |= (1 << [channelFromDb intValue]);
        }
        
        counter++;
        if(counter == 32){
            //post the pmtMask for a specific card
            NSLog(@"%lu\n",aPmtMask);
            
            //loop through all the Fec32 and pick the card for this crate/card
            int iFec32card;
            for(iFec32card=0;iFec32card<numberFec32Cards;iFec32card++){
                
                ORFec32Model *aFec32Model = [fec32ControllerObjs objectAtIndex:iFec32card];
                
                //check to see if the Fec32 is in the current crate and card combination
                if(([crateFromDb intValue] == [aFec32Model crateNumber]) && ([cardFromDb intValue] && [aFec32Model slot])){
                    //now assign the mask for the crate and card/slot of interest
                    [aFec32Model setOnlineMask:aPmtMask];
                    
                }
                
            }
            
            //reset the mask
            aPmtMask = 0;
            counter = 0;
        }
        
        //if this is the correct crate,card and channel for this current pmt
        /*if(([crateFromDb intValue] == crateNumber) && ([cardFromDb intValue] == slotNumber) && ([channelFromDb intValue] == iChannel)){
            
            if([resistorPulled intValue] == 1){
                //add a bitwise
                aPmtMask |= 1UL<<iChannel;
            }
            
            //fill in the particular pmt mask
            
        }*/
        
    }
    
    
        //set the pmtOnlineMask for eachFec32Card
    
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
