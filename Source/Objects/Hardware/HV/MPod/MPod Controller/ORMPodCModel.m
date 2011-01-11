//
//  ORMPodCModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORMPodCModel.h"
#import "ORMPodCrate.h"
#import "ORTaskSequence.h"

NSString* ORMPodCModelLock		= @"ORMPodCModelLock";
NSString* ORMPodCPingTask		= @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged	= @"MPodCIPNumberChanged";

@implementation ORMPodCModel

- (void) dealloc
{
	[connectionHistory release];
    [IPNumber release];
	[super dealloc];
}

#pragma mark ¥¥¥Initialization
- (void) makeMainController
{
    [self linkToController:@"ORMPodCController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MPodC"]];
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];
	
    [super setGuardian:aGuardian];
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}
#pragma mark ***Accessors
- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}


- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory && index>=0 && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (unsigned) ipNumberIndex
{
	return ipNumberIndex;
}
- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:MPodCIPNumberChanged object:self];
	}
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}

- (void) openSession
{
	init_snmp("APC Check");
	u_char* community = (u_char*)"guru";
	struct snmp_session session; 
	snmp_sess_init( &session );
	session.version			= SNMP_VERSION_1;
	session.community		= community;
	session.community_len	= strlen((const char *)session.community);
	session.peername		= (char*)[IPNumber cStringUsingEncoding:NSASCIIStringEncoding];
	sessionHandle = snmp_open(&session);

	//add_mibdir("."); 
	//struct tree* mib_tree = read_mib("/usr/share/snmp/mibs/WIENER-CRATE-MIB.txt"); 
	[self testGet];
}

- (void) testGet
{
	struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_GET);
	
	size_t id_len = MAX_OID_LEN;
	oid id_oid[MAX_OID_LEN];
	NSLog(@"Test Read: Temp Chan 0 and Serial Number\n");
	read_objid("WIENER-CRATE-MIB::outputMeasurementTemperature.u0", id_oid, &id_len);
	snmp_add_null_var(pdu, id_oid, id_len);
	
	size_t serial_len = MAX_OID_LEN;
	oid serial_oid[MAX_OID_LEN];
	read_objid("WIENER-CRATE-MIB::psSerialNumber.0", serial_oid, &serial_len);
	snmp_add_null_var(pdu, serial_oid, serial_len);
	
	struct snmp_pdu* response;
	int status = snmp_synch_response(sessionHandle, pdu, &response);
	NSLog(@"%d\n",status);
	struct variable_list* vars;            
	for(vars = response->variables; vars; vars = vars->next_variable){
		char buffer[64];
		snprint_value(buffer,64,vars->name, vars->name_length, vars);
		NSLog(@"%s\n",buffer);
	}
	[self writeParam:@"outputVoltage" slot:1 channel:1 floatValue:-1];
	
	[self closeSession];
}

- (void) writeParam:(NSString*)aParam slot:(int)aSlot channel:(int)aChannel floatValue:(float)aValue
{
	if (sessionHandle){
		struct snmp_pdu *response;
		
		oid anOID[MAX_OID_LEN];
		size_t anOID_len = MAX_OID_LEN;
								
		char type = 'f';
		struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_SET);
		
		// create set request and add object names and values 
		char val[64];
		sprintf(val,"%f",aValue);
		NSString* s = [NSString stringWithFormat:@"WIENER-CRATE-MIB::%@.u%d%02d",aParam,aSlot,aChannel];
		const char* intoid = [s cStringUsingEncoding:NSASCIIStringEncoding];
		if (snmp_parse_oid(intoid, anOID, &anOID_len) == NULL){
			snmp_perror(intoid);
			//exit(EXIT_SNMP_SET_ERROR);
		}
		if (snmp_add_var(pdu, anOID, anOID_len, type, val)){
			snmp_perror(intoid);
			//exit(EXIT_SNMP_SET_ERROR);
		}
		
		int status = snmp_synch_response(sessionHandle, pdu, &response);
		
		if (status == STAT_SUCCESS){
			if (response->errstat != SNMP_ERR_NOERROR){
				NSLog(@"Error in packet.\nReason: %s\n",snmp_errstring(response->errstat));
				//exit(EXIT_SNMP_SET_ERROR);
			}
		}
		else if (status == STAT_TIMEOUT){
			NSLog(@"SNMP SetTimeout: No Response from %s\n",sessionHandle->peername);
			//exit(EXIT_SNMP_SET_ERROR);
		}
		else { /* status == STAT_ERROR */
			snmp_sess_perror("snmpset", sessionHandle);
			//exit(EXIT_SNMP_SET_ERROR);
		}
	}
}


- (void) closeSession
{
	if(sessionHandle) {
		snmp_close(sessionHandle);
		sessionHandle = nil;
	}
}

#pragma mark ¥¥¥Tasks
- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == pingTask){
		[pingTask release];
		pingTask = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
}

- (void) ping
{
	if(!pingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		pingTask = [[NSTask alloc] init];
		
		[pingTask setLaunchPath:@"/sbin/ping"];
		[pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"5",@"-t",@"10",@"-q",IPNumber,nil]];
		
		[aSequence addTaskObj:pingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
	else {
		[pingTask terminate];
	}
}

- (BOOL) pingTaskRunning
{
	return pingTask != nil;
}


- (void) taskData:(NSString*)text
{
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	
	[self setIPNumber:		[decoder decodeObjectForKey:@"IPNumber"]];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
}

@end
