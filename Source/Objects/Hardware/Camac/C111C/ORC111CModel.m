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


NSString* ORC111CSettingsLock			= @"ORC111CSettingsLock";
NSString* ORC111CConnectionChanged		= @"ORC111CConnectionChanged";
NSString* ORC111CTimeConnectedChanged	= @"ORC111CTimeConnectedChanged";
NSString* ORC111CIpAddressChanged		= @"ORC111CIpAddressChanged";

#define kC111CBinaryPort 2001

#define kSTX				0x02
#define kETX				0x04
#define kResponseRequired	0x01 //actually ANYTHING other than 0xa0
#define kNOResponseRequired	0xa0
#define kBin_CFSA_Cmd		0x20
#define kBin_CSSA_Cmd		0x21
#define kBin_CCCZ_Cmd		0x22
#define kBin_CCCC_Cmd		0x23
#define kBin_CCCI_Cmd		0x24
#define kBin_CTCI_Cmd		0x25
#define kBin_CTLM_Cmd		0x26
#define kBin_CLWT_Cmd		0x27
#define kBin_LACK_Cmd		0x28
#define kBin_CTSTAT_Cmd		0x29
#define kBin_CLMR_Cmd		0x2A
#define kBin_CSCAN_Cmd		0x2B
#define kBin_NIMSetOuts_Cmd 0x30

@interface ORC111CModel (private)
- (int) readBuffer:(unsigned char*)aBuffer maxLength:(int)len;
- (int) writeBuffer:(unsigned char*)aBuffer length:(int)len;
- (int) adjustFrame:(unsigned char*)buff length:(int) length;
- (BOOL) canWrite;
- (BOOL) canRead;
@end

@implementation ORC111CModel

// destructor
-(void) dealloc
{
    [ipAddress release];
	[self disconnect];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		//[self connect];
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
	if(!socketfd && ([ipAddress length]!=0)){
		NS_DURING
			struct sockaddr_in target_address;
			
			struct hostent* he=gethostbyname([ipAddress cStringUsingEncoding:NSASCIIStringEncoding]);
			if(he){
				target_address.sin_family = AF_INET;
				target_address.sin_addr	  =	*((struct in_addr *)he->h_addr);
				target_address.sin_port	  = htons(kC111CBinaryPort);
				memset(&(target_address.sin_zero), '\0', 8);		// zero the rest of the struct 

				if ((socketfd = socket(AF_INET, SOCK_STREAM, 0)) != 0) {
					int oflag = fcntl(socketfd, F_GETFL);
					fcntl(socketfd, F_SETFL, oflag | O_NONBLOCK);
					//time_t now = time(NULL);
					int r = connect(socketfd, (struct sockaddr *) &target_address, sizeof(target_address));
					if (r == -1) {
							[NSException raise:@"Socket Failed" format:@"Couldn't couldn't get socket for %@ Port %d",ipAddress,kC111CBinaryPort];
					}
					
					NSLog(@"Connected to %@ <%@> port: %d\n",[self crateName],ipAddress,kC111CBinaryPort);
					[self setIsConnected:YES];
					[self setTimeConnected:[NSCalendarDate date]];
					fcntl(socketfd, F_SETFL, oflag);
				}
				else [NSException raise:@"Socket Failed" format:@"Couldn't couldn't get socket for %@ Port %d",ipAddress,kC111CBinaryPort];
			}
			else [NSException raise:@"HostByName Failed" format:@"Couldn't couldn't get hostname for %@",ipAddress];

		NS_HANDLER
			if(socketfd){
				close(socketfd);
				socketfd = 0;
				[self setIsConnected: NO];
				[self setTimeConnected:nil];
			}
			[localException raise];
		NS_ENDHANDLER
	}
}

- (void) disconnect
{
	if(socketfd){
		close(socketfd);
		socketfd = 0;
		[self setIsConnected: NO];
		[self setTimeConnected:nil];
		NSLog(@"Disconnected from %@ <%@> port: %d\n",[self crateName],ipAddress,kC111CBinaryPort);
	}	
}

- (NSString*) shortName
{
	return @"C111C";
}

- (unsigned short)  executeCCycle
{
	@synchronized(self){
		unsigned char data[4] = {	kSTX,
									kBin_CCCC_Cmd,
									kResponseRequired,
									kETX };
		[self writeBuffer:data length:4];
		[self readBuffer:data maxLength:3];
	}
	return 0;
}

- (unsigned short)  executeZCycle
{
	@synchronized(self){
		unsigned char data[4] = {	kSTX,
									kBin_CCCZ_Cmd,
									kResponseRequired,
									kETX };
		[self writeBuffer:data length:4];
		[self readBuffer:data maxLength:3];
	}
	return 0;
}

- (unsigned long) setLAMMask:(unsigned long) mask
{
	lamMask = mask;
    return 1;
}

- (unsigned short)  readLAMMask:(unsigned long *)mask
{
	*mask = lamMask & 0xffffff;
	return 1;
} 

- (unsigned short)  resetLAMFF
{
	unsigned short result;
	@synchronized (self) {
		unsigned char bin_cmd[4];
		bin_cmd[0] = kSTX;
		bin_cmd[1] = kBin_LACK_Cmd;
		bin_cmd[2] = kNOResponseRequired;
		bin_cmd[3] = kETX;

		result = [self writeBuffer:bin_cmd length:4];
	}
	return result;
}


- (unsigned short)  readLAMStations:(unsigned long *)stations
{
	unsigned short result = 1;
	@synchronized(self){
		unsigned char bin_cmd[5];
		unsigned char bin_rcv[4] = {0, 0, 0, 0};
		short msgsize;

		bin_cmd[0] = kSTX;
		bin_cmd[1] = kBin_CTLM_Cmd;
		bin_cmd[2] = 0xFF;
		msgsize = 2;
		msgsize += [self adjustFrame:&bin_cmd[msgsize] length:1];
		bin_cmd[msgsize++] = kETX;

		[self writeBuffer:bin_cmd length:msgsize];

		msgsize = [self readBuffer:bin_rcv maxLength:7];

		if ((bin_rcv[1] != kBin_CTLM_Cmd) || (msgsize != 4)) result =  -1;

		if(result>0)*stations = bin_rcv[2];
		else *stations = 0;
	}
	return result;
}

- (unsigned short)  setCrateInhibit:(BOOL)state
{   
	unsigned short result = 1;
 	@synchronized(self){
		unsigned char bin_cmd[5];
		short msgsize;

		bin_cmd[0] = kSTX;
		bin_cmd[1] = kBin_CCCI_Cmd;
		bin_cmd[2] = state;
		bin_cmd[3] = kNOResponseRequired;
		bin_cmd[4] = kETX;

		result = [self writeBuffer:bin_cmd length:msgsize];
	}
	return result;
}

- (unsigned short)  readCrateInhibit:(unsigned short*)state
{   
 	unsigned short result = 1;
 	@synchronized(self){
		unsigned char bin_cmd[3];
		unsigned char bin_rcv[4] = {0, 0, 0, 0};
		short msgsize;

		bin_cmd[0] = kSTX;
		bin_cmd[1] = kBin_CTCI_Cmd;
		bin_cmd[2] = kETX;

		if ([self writeBuffer:bin_cmd length:msgsize] <= 0) result =  -1;
		if(result==1){
			msgsize = [self readBuffer:bin_rcv maxLength:4];
		
			if ((bin_rcv[1] != kBin_CTCI_Cmd) || (msgsize != 4)) result =  -1;
		
			if(result==1) *state = bin_cmd[2];
			else *state = 0;
		}
	}
	return result;
}



- (unsigned short)  readLAMFFStatus:(unsigned short*)value
{
    unsigned char bin_cmd[3];
    unsigned char bin_rcv[7] = {0, 0, 0, 0, 0, 0, 0};
	short msgsize;

	unsigned short result = 1;
	@synchronized(self){

		bin_cmd[0] = kSTX;
		bin_cmd[1] = kBin_CLMR_Cmd;
		bin_cmd[2] = kETX;

		[self writeBuffer:bin_cmd length:3];

		msgsize = [self readBuffer:bin_rcv maxLength:7];
	
		if ((bin_rcv[1] != kBin_CLMR_Cmd) || (msgsize != 7)) result = -1;
		
		if(result == 1) *value = bin_cmd[2] | (bin_cmd[3] << 8) | (bin_cmd[4] << 16) | (bin_cmd[5] << 24);
		else *value = 0;
	}
	return result;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
	unsigned short result = 1;
	@synchronized(self){
		unsigned char buffer[15];
		unsigned char bin_rcv[7] = {0, 0, 0, 0, 0, 0, 0};
		int msgsize = 0;
		buffer[0] = kSTX;
		buffer[1] = kBin_CSSA_Cmd;
		buffer[2] = f;
		buffer[3] = n;
		buffer[4] = a;
		buffer[5] = (*data & 0xFF);
		buffer[6] = ((*data >> 8) & 0xFF);
		buffer[7] = kResponseRequired;

		msgsize = 2;
		msgsize += [self adjustFrame:&buffer[msgsize] length:(int) 6];
		buffer[msgsize++] = kETX;

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		[self writeBuffer:buffer length:msgsize];
		
		//get the response
		msgsize = [self readBuffer:buffer maxLength:7];
		
		NSLog(@"%d delta time: %f mS\n",msgsize,1000*([NSDate timeIntervalSinceReferenceDate] - now));
		
		if ((bin_rcv[1] != kBin_CSSA_Cmd) || (msgsize != 7)) result =  -1;
		if(result==1){
			cmdResponse		= bin_rcv[2];
			cmdAccepted		= bin_rcv[3];
			*data			= bin_rcv[4] | (bin_rcv[5] << 8);
		}
		else {
			cmdResponse		= 0;
			cmdAccepted		= 0;
			*data			= 0;
		}
	}
	return 1;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
{
	@synchronized(self){
		unsigned char buffer[15];
		int msgsize = 0;
		buffer[0] = kSTX;
		buffer[1] = kBin_CSSA_Cmd;
		buffer[2] = f;
		buffer[3] = n;
		buffer[4] = a;
		buffer[5] = 0;
		buffer[6] = 0;
		buffer[7] = kResponseRequired;

		msgsize = 2;
		msgsize += [self adjustFrame:&buffer[msgsize] length:(int) 6];
		buffer[msgsize++] = kETX;

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		[self writeBuffer:buffer length:msgsize];
		NSLog(@"%d delta time: %f mS\n",msgsize,1000*([NSDate timeIntervalSinceReferenceDate] - now));
				
		cmdResponse		= 0;
		cmdAccepted		= 0;
	}
	return 1;
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data
{
	unsigned short result = 1;
	@synchronized(self){
		unsigned char buffer[16];
		unsigned char bin_rcv[8] = {0, 0, 0, 0, 0, 0, 0, 0};
		int msgsize = 0;
		buffer[0] = kSTX;
		buffer[1] = kBin_CFSA_Cmd;
		buffer[2] = f;
		buffer[3] = n;
		buffer[4] = a;
		buffer[5] = (*data & 0xFF);
		buffer[6] = ((*data >> 8) & 0xFF);
		buffer[7] = ((*data >> 16) & 0xFF);
		buffer[8] = kResponseRequired;

		msgsize = 2;
		msgsize += [self adjustFrame:&buffer[msgsize] length:(int) 8];
		buffer[msgsize++] = kETX;

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		[self writeBuffer:buffer length:msgsize];
		
		//get the response
		msgsize = [self readBuffer:buffer maxLength:8];
		NSLog(@"%d delta time: %f mS\n",msgsize,1000*([NSDate timeIntervalSinceReferenceDate] - now));
			
		if ((bin_rcv[1] != kBin_CFSA_Cmd) || (msgsize != 8)) result =  -1;
		if(result==1){		
			cmdResponse		= bin_rcv[2];
			cmdAccepted		= bin_rcv[3];
			*data			= bin_rcv[4] | (bin_rcv[5] << 8);
		}
		else {
			cmdResponse		= 0;
			cmdAccepted		= 0;
			*data			= 0;
		}

	}
	return 1;
}


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long)    numWords
{
	//not implemented yet
	return 0;
}



- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress:[decoder decodeObjectForKey:@"IpAddress"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress forKey:@"IpAddress"];
}

@end

@implementation ORC111CModel (private)
- (BOOL) canWrite
{
	fd_set wfds;

	FD_ZERO(&wfds);
	FD_SET(socketfd, &wfds);

	struct timeval tv;
	tv.tv_sec = 1;
	tv.tv_usec = 0;

	if (select(socketfd + 1, NULL, &wfds, NULL, &tv) > 0) {
		if (FD_ISSET(socketfd, &wfds)) return YES;
	}
	return NO;
}

- (BOOL) canRead
{
	fd_set rfds;
	FD_ZERO(&rfds);
	FD_SET(socketfd, &rfds);

	struct timeval tv;
	tv.tv_sec = 1;
	tv.tv_usec = 0;

	if (select(socketfd + 1, &rfds, NULL, NULL, &tv) > 0) {
		if (FD_ISSET(socketfd, &rfds)) return YES;
	}
	return NO;
}

- (int) readBuffer:(unsigned char*)buffer maxLength:(int)maxLen
{
	int pos = 0;
	BOOL escapeSeq = NO;
	BOOL etx_found = NO;
	unsigned char buf;

	if ([self canRead]) {
		while (!etx_found) {
			int rp = recv(socketfd, &buf, 1, 0);
			if (rp > 0) {
				if (buf == kSTX) {
					pos = 0;
					escapeSeq = NO;
					buffer[pos++] = buf;
				}
				else if (pos) {
					if (buf == 0x10) escapeSeq = YES;
					else if (buf == kETX) {
						buffer[pos++] = buf;
						etx_found = YES;
					}
					else {
						if (pos < maxLen) {
							if (escapeSeq)	buffer[pos++] = buf - 0x80;
							else			buffer[pos++] = buf;
						}
						escapeSeq = NO;
					}
				}
			}
			else return 0;
		}
	}
	return pos;
}


- (int) adjustFrame:(unsigned char*)buff length:(int) length
{
    unsigned char dataFrame[32];
	BOOL changed = NO;
	int  pos = 0;
    
    int i;
	for (i = 0; i < length; i++) {
		if (buff[i] == kSTX) {
			dataFrame[pos] = 0x10;
			pos++;
			dataFrame[pos] = (unsigned char)(0x80 | kSTX);
			changed = YES;
		}
		else if (buff[i] == kETX) {
			dataFrame[pos] = 0x10;
			pos++;
			dataFrame[pos] = (unsigned char)(0x80 | kETX);	    
			changed = YES;
		}
		else if (buff[i] == 0x10) {
			dataFrame[pos] = 0x10;
			pos++;
			dataFrame[pos] = (unsigned char)(0x80 | 0x10);	    
			changed = YES;
		}
		else dataFrame[pos] = buff[i];
		pos++;
    }

    if (changed) {
		for (i = 0; i < pos; i++) {
			buff[i] = dataFrame[i];
		}
    }

    return pos;
}


- (int) writeBuffer:(unsigned char*)aBuffer length:(int)len
{
	return send(socketfd, (char *)aBuffer, len, 0);	
}


@end
