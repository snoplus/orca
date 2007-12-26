/*
 *  ORC111CModel.h
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORC111CModel.h"
#import "ORCmdHistory.h"
#include <sys/time.h> 
#include <sys/wait.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <sys/stat.h> 
#include <netinet/in.h> 
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <fcntl.h> 
#import <netdb.h>
#include <time.h> 

#define kTinyDelay 0.0005

NSString* ORC111CModelTrackTransactionsChanged = @"ORC111CModelTrackTransactionsChanged";
NSString* ORC111CModelStationToTestChanged	= @"ORC111CModelStationToTestChanged";
NSString* ORC111CSettingsLock				= @"ORC111CSettingsLock";
NSString* ORC111CConnectionChanged			= @"ORC111CConnectionChanged";
NSString* ORC111CTimeConnectedChanged		= @"ORC111CTimeConnectedChanged";
NSString* ORC111CIpAddressChanged			= @"ORC111CIpAddressChanged";

@implementation ORC111CModel

-(void) dealloc
{
	[cmdHistory release];
    [ipAddress release];
	[transactionTimer release];
	[self disconnect];
    [super dealloc];
}

#pragma mark ***Accessors
- (ORCmdHistory*) cmdHistory
{
	if(!cmdHistory)cmdHistory = [[ORCmdHistory alloc] init];
	return cmdHistory;
}

- (BOOL) trackTransactions
{
    return trackTransactions;
}

- (void) setTrackTransactions:(BOOL)aTrackTransactions
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackTransactions:trackTransactions];
    
    trackTransactions = aTrackTransactions;
	
	if(aTrackTransactions){
		transactionTimer = [[ORTimer alloc] init];
		[transactionTimer start];
	}
	else {
		[transactionTimer release];
		transactionTimer = nil;
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CModelTrackTransactionsChanged object:self];
}

- (void) histogramTransactions
{
	float seconds = [transactionTimer seconds];
	if(seconds>0){
		int ts = 1./seconds;
		transactionsPerSecondHistogram[ts]++;
	}
}

- (void) clearTransactions
{
	int i;
	for(i=0;i<kMaxNumberC111CTransactionsPerSecond;i++)transactionsPerSecondHistogram[i] = 0;
}

- (float) transactionsPerSecondHistogram:(int)index
{
	if(index>=kMaxNumberC111CTransactionsPerSecond)index = kMaxNumberC111CTransactionsPerSecond-1;
	return transactionsPerSecondHistogram[index];
}

- (char) stationToTest
{
    return stationToTest;
}

- (void) setStationToTest:(char)aStationToTest
{
	if(aStationToTest==0)aStationToTest=1;
	else if(aStationToTest>25)aStationToTest=25;
	else if(aStationToTest< -1)aStationToTest = -1;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setStationToTest:stationToTest];
    
    stationToTest = aStationToTest;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CModelStationToTestChanged object:self];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		if(ipAddress) [self connect];
	NS_HANDLER
	NS_ENDHANDLER
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C111C"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORC111CController"];
}

- (NSString*) settingsLock
{
	return ORC111CSettingsLock;
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
	isConnected = aNewIsConnected;
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORC111CConnectionChanged 
                          object: self];

	[self setTimeConnected:isConnected?[NSCalendarDate date]:nil];

}

- (NSCalendarDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORC111CTimeConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"192.168.0.98";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CIpAddressChanged object:self];
}

- (NSString*) crateName
{
	NSString* crateName = [[self guardian] className];
	if(crateName){
		if([crateName hasPrefix:@"OR"])crateName = [crateName substringFromIndex:2];
		if([crateName hasSuffix:@"Model"])crateName = [crateName substringToIndex:[crateName length]-5];
	}
	else {
		crateName = [[ipAddress copy] autorelease];
	}
	return crateName;
}

- (id) controller
{
    return self;
}
- (unsigned short) camacStatus
{
    return 0;
}

- (void)  checkCratePower
{   
    //[[self controller] checkCratePower];
}


- (void) connect
{
	if(!isConnected){
		crate_id = CROPEN((char*)[ipAddress cStringUsingEncoding:NSASCIIStringEncoding]);
		if (crate_id < 0) { 
			NSLog(@"Error %d opening connection with CAMAC Controller", crate_id); 
		}
		else {
			int res = CRGET(crate_id, &cr_info);
			if(res == CRATE_OK){
				[self setIsConnected: YES];
				cr_info. tout_ticks = 100000; 
				CRSET(crate_id, &cr_info);
			}
		}
	}
}

- (void) disconnect
{
	if(isConnected){
		CRCLOSE(crate_id);		
		[self setIsConnected: NO];
		NSLog(@"Disconnected from %@ <%@>\n",[self crateName],ipAddress);
	}	
}

- (NSString*) shortName
{
	return @"C111C";
}

- (unsigned short)  executeCCycle
{
	short res;
	@synchronized(self){
		res = CCCC(crate_id);
	}
	return res;
}

- (unsigned short)  executeZCycle
{
	short res;
	@synchronized(self){
		res=CCCZ(crate_id);
		if(res==CRATE_CONNECT_ERROR){
			[self setIsConnected:NO];
		}
	}
	return res;	
}

- (unsigned short)  resetContrl
{   
	NSLog(@"C111C doesn't support a controller reset function\n");
    return 1;
}
- (unsigned long) setLAMMask:(unsigned long) mask
{
	NSLog(@"C111C doesn't support a set LAM mask function\n");
    return 1;
}

- (unsigned short)  readLAMMask:(unsigned long *)mask
{
	NSLog(@"C111C doesn't support a read LAM mask function\n");

	*mask = 0;
	return 1;
} 

- (unsigned short)  readLAMFFStatus:(unsigned short*)value
{
	NSLog(@"C111C doesn't support a read LAMFF Status function\n");

	*value = 0;
	return 1;
}

- (unsigned short) testLAMForStation:(char)aStation value:(char*)result
{
	short res;
	@synchronized(self){
		res = CTLM(crate_id,aStation,result);
		if(res==CRATE_CONNECT_ERROR){
			[self setIsConnected:NO];
		}
	}
	return res;
}

- (unsigned short)  resetLAMFF
{
	short res;
	@synchronized (self) {
		res = LACK(crate_id);
		if(res==CRATE_CONNECT_ERROR){
			[self setIsConnected:NO];
		}
	}
	return res;
}


- (unsigned short)  readLAMStations:(unsigned long *)stations
{
	short res;
	unsigned int mask;
	@synchronized (self) {
		res = CLMR(crate_id,&mask);
		if(res==CRATE_CONNECT_ERROR){
			*stations = 0;
			[self setIsConnected:NO];
		}
		else *stations = mask&0x0FFFFFF;
	}
	return res;
}

- (unsigned short)  setCrateInhibit:(BOOL)state
{   
	short res;
 	@synchronized(self){
		res = CCCI(crate_id,state);
		if(res==CRATE_CONNECT_ERROR){
			[self setIsConnected:NO];
		}
	}
	return res;
}

- (unsigned short)  readCrateInhibit:(unsigned short*)state
{   
 	short res;
	char inhibitValue;
 	@synchronized(self){
		res = CTCI(crate_id,&inhibitValue);
		if(res==CRATE_CONNECT_ERROR){
			[self setIsConnected:NO];
		}
		else *state = inhibitValue;
	}
	return res;
}


- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
	short result;
	@synchronized(self){
		CRATE_OP cr_op;
		cr_op.F = f;
		cr_op.N = n;
		cr_op.A = a;
		cr_op.DATA = *data;
		if(trackTransactions)[transactionTimer reset];
		result = CSSA(crate_id,&cr_op);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(result==CRATE_OK){
			if(trackTransactions)[self histogramTransactions];
			cmdResponse		= cr_op.Q;
			cmdAccepted		= cr_op.X;
			*data			= cr_op.DATA;
		}
		else if(result==CRATE_CONNECT_ERROR){
			cmdResponse		= 0;
			cmdAccepted		= 0;
			*data			= 0;
			[self setIsConnected:NO];
		}
	}
	return result;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
{
	short result;
	@synchronized(self){
		CRATE_OP cr_op;
		cr_op.F = f;
		cr_op.N = n;
		cr_op.A = a;
		cr_op.DATA = 0;
		if(trackTransactions)[transactionTimer reset];
		result = CSSA(crate_id,&cr_op);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(trackTransactions)[self histogramTransactions];
		if(result==CRATE_OK){
			cmdResponse		= cr_op.Q;
			cmdAccepted		= cr_op.X;
		}
		else if(result==CRATE_CONNECT_ERROR){
			cmdResponse		= 0;
			cmdAccepted		= 0;
			[self setIsConnected:NO];
		}
	}
	return result;
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data
{
	short result;
	@synchronized(self){
		CRATE_OP cr_op;
		cr_op.F = f;
		cr_op.N = n;
		cr_op.A = a;
		cr_op.DATA = *data;
		if(trackTransactions)[transactionTimer reset];
		result = CFSA(crate_id,&cr_op);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(trackTransactions)[self histogramTransactions];
		if(result==CRATE_OK){
			cmdResponse		= cr_op.Q;
			cmdAccepted		= cr_op.X;
			*data			= cr_op.DATA;
		}
		else if(result==CRATE_CONNECT_ERROR){
			cmdResponse		= 0;
			cmdAccepted		= 0;
			*data			= 0;
			[self setIsConnected:NO];
		}
	}
	return result;
}


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long) numWords
{
	BLK_TRANSF_INFO blk_info;
	blk_info.opcode = OP_BLKSA; 
	blk_info.F = f; 
	blk_info.N = n; 
	blk_info.A = a; 
	blk_info.blksize = 16; //16 bit word size  
	blk_info.totsize = numWords;  	
	blk_info.timeout = 0;
	unsigned int* buffer = (unsigned int*)malloc(numWords*sizeof(int));
	short result;
	if(trackTransactions)[transactionTimer reset];
	int i;
	if(f < 16){
		//CAMAC Read
		result = BLKTRANSF(crate_id, &blk_info, buffer);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(result==CRATE_OK){
			unsigned int* dp = buffer;
			for(i=0;i<numWords;i++)*data++ = *dp++;
		}
	}
	else {
		//CAMAC write
		unsigned int* dp = buffer;
		for(i=0;i<numWords;i++) *dp++ = *data++;
		result = BLKTRANSF(crate_id, &blk_info, buffer);
	}
	if(trackTransactions)[self histogramTransactions];
	
	if(result==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	free(buffer);
  	return result;
}

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned long*) data
                                length:(unsigned long)    numWords
{
	BLK_TRANSF_INFO blk_info;
	blk_info.opcode = OP_BLKSA; 
	blk_info.F = f; 
	blk_info.N = n; 
	blk_info.A = a; 
	blk_info.blksize = 24; //16 bit word size  
	blk_info.totsize = numWords;  	
	blk_info.timeout = 0;
	unsigned int* buffer = (unsigned int*)malloc(numWords*sizeof(long));
	short result;
	if(trackTransactions)[transactionTimer reset];
	int i;
	if(f < 16){
		//CAMAC Read
		result = BLKTRANSF(crate_id, &blk_info, buffer);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(result==CRATE_OK){
			unsigned int* dp = buffer;
			for(i=0;i<numWords;i++)*data++ = *dp++;
		}
	}
	else {
		//CAMAC write
		unsigned int* dp = buffer;
		for(i=0;i<numWords;i++) *dp++ = *data++;
		result = BLKTRANSF(crate_id, &blk_info, buffer);
	}
	if(trackTransactions)[self histogramTransactions];
	
	if(result==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	free(buffer);
  	return result;
}


- (void) sendCmd:(NSString*)aCmd verbose:(BOOL)verbose
{
	int res;
	char response[32];
	@synchronized(self){
		if(![aCmd hasSuffix:@"\r"])aCmd = [aCmd stringByAppendingString:@"\r"];
		res = CMDSR(crate_id,(char*)[aCmd cStringUsingEncoding:NSASCIIStringEncoding], response, 32);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(res==CRATE_OK){
			if(verbose){
				if(response)NSLog(@"C111C Response: %s\n",response);
				else NSLog(@"C111C Response: <nil>\n");
			}
		}
		else {
			[self setIsConnected:NO];
		}
	}
}


- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setStationToTest:[decoder decodeIntForKey:@"ORC111CModelStationToTest"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"IpAddress"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:stationToTest forKey:@"ORC111CModelStationToTest"];
    [encoder encodeObject:ipAddress forKey:@"IpAddress"];
}

@end

