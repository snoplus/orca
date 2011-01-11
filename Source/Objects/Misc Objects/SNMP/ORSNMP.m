//
//  ORSNMP.m
//  Orca
//
//  Created by Mark Howe on Tues Jan 11,2011
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

#import "ORSNMP.h"

@implementation ORSNMP

- (void) dealloc
{
	[self closeSession];
	[super dealloc];
}

- (void) openGuruSession:(NSString*)ip  
{
	[self openSession:ip community:@"Guru"];
}

- (void) openPublicSession:(NSString*)ip  
{
	[self openSession:ip community:@"Public"];
}

- (void) openSession:(NSString*)ip community:(NSString*)aCommunity
{
	if(!sessionHandle){
		init_snmp("APC Check");
		struct snmp_session session; 
		snmp_sess_init(&session);
		session.version			= SNMP_VERSION_1;
		session.community		= (unsigned char*)[aCommunity cStringUsingEncoding:NSASCIIStringEncoding];
		session.community_len	= strlen((const char *)session.community);
		session.peername		= (char*)[ip cStringUsingEncoding:NSASCIIStringEncoding];
		sessionHandle			= snmp_open(&session);
	}
}

- (NSArray*) readValue:(NSString*)anObjId
{
	return [self readValues:[NSArray arrayWithObject:anObjId]];
}

- (NSArray*) readValues:(NSArray*)someObjIds
{
	if(sessionHandle){
		struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_GET);

		size_t id_len = MAX_OID_LEN;
		oid id_oid[MAX_OID_LEN];
		
		for(id anObjID in someObjIds){
			const char* obj_id = [anObjID cStringUsingEncoding:NSASCIIStringEncoding];
			read_objid(obj_id, id_oid, &id_len);
			snmp_add_null_var(pdu, id_oid, id_len);
		}
		
		struct snmp_pdu* response;
		if(!snmp_synch_response(sessionHandle, pdu, &response)){
			NSMutableArray* resultArray = [NSMutableArray array];
			struct variable_list* vars;            
			for(vars = response->variables; vars; vars = vars->next_variable){
				NSMutableDictionary* dict = [NSMutableDictionary dictionary];
				[dict setObject:[NSString stringWithCharacters:(const unichar *)vars->name length:vars->name_length] forKey:@"Name"];

				char buffer[64];
				snprint_value(buffer,64,vars->name, vars->name_length, vars);
				//decode into an int or float...
				
				//[dict setObject:theValue forKey:@"Value"];
				
				[resultArray addObject:dict];
			}
			return resultArray;
		}
		else return nil;
	}
	return nil;
}

- (void) setValue:(NSString*)anObjId floatValue:(float)aValue
{
	if (sessionHandle){
		struct snmp_pdu *response;
				
		struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_SET);
		
		// create set request and add object names and values 
		char val[64];
		sprintf(val,"%f",aValue);
		
		oid    anOID[MAX_OID_LEN];
		size_t anOID_len = MAX_OID_LEN;
		const char* intoid = [anObjId cStringUsingEncoding:NSASCIIStringEncoding];
		if (snmp_parse_oid(intoid, anOID, &anOID_len) == NULL){
			snmp_perror(intoid);
			return;
		}
		if (snmp_add_var(pdu, anOID, anOID_len, 'f', val)){
			snmp_perror(intoid);
			return;
		}
		
		int status = snmp_synch_response(sessionHandle, pdu, &response);
		
		if (status == STAT_SUCCESS){
			if (response->errstat != SNMP_ERR_NOERROR){
				NSLog(@"Error in packet.\nReason: %s\n",snmp_errstring(response->errstat));
				return;
			}
		}
		else if (status == STAT_TIMEOUT){
			NSLog(@"SNMP SetTimeout: No Response from %s\n",sessionHandle->peername);
			return;
		}
		else { /* status == STAT_ERROR */
			snmp_sess_perror("snmpset", sessionHandle);
			return;
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
@end
