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
#import "NSString+Extensions.h"

@implementation ORSNMP
- (id) initWithMib:(NSString*)aMibName
{
	self = [super init];
	mibName = [aMibName copy];
	return self;
}

- (void) dealloc
{
	[self closeSession];
	[mibName release];
	[super dealloc];
}

- (void) openGuruSession:(NSString*)ip  
{
	[self openSession:ip community:@"guru"];
}

- (void) openPublicSession:(NSString*)ip  
{
	[self openSession:ip community:@"public"];
}

- (void) openSession:(NSString*)ip community:(NSString*)aCommunity
{
	if(!sessionHandle){
		init_snmp("APC Check");
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
	NSMutableArray* resultArray = [NSMutableArray array];
	if(sessionHandle){

		size_t id_len = MAX_OID_LEN;
		oid id_oid[MAX_OID_LEN];
		
		for(id anObjID in someObjIds){
			anObjID = [mibName stringByAppendingFormat:@"::%@",anObjID];
			struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_GET);
			const char* obj_id = [anObjID cStringUsingEncoding:NSASCIIStringEncoding];
			read_objid(obj_id, id_oid, &id_len);
			snmp_add_null_var(pdu, id_oid, id_len);
			NSMutableDictionary* responseDictionary = [NSMutableDictionary dictionary];
			struct snmp_pdu* response;
			int status = snmp_synch_response(sessionHandle, pdu, &response);
			if(status == STAT_SUCCESS){
				if (response->errstat == SNMP_ERR_NOERROR){
					struct variable_list* vars;   
					for(vars = response->variables; vars; vars = vars->next_variable){
						char buf[1024];
						snprint_variable(buf, sizeof(buf), vars->name, vars->name_length,vars);
						NSString* s = [NSString stringWithUTF8String:buf];
						[self topLevelParse:s intoDictionary:responseDictionary];
					}
				}
				else NSLog(@"Error in packet.\nReason: %s\n",snmp_errstring(response->errstat));
			}
			else if (status == STAT_TIMEOUT) NSLog(@"SNMP SetTimeout: No Response from %s\n",sessionHandle->peername);
			else {
				[responseDictionary setObject:@"SNMP response error" forKey:@"Error"];
			}
			
			[resultArray addObject:responseDictionary];
			
			if (response)snmp_free_pdu(response);				
		}
	}
	return resultArray;
}

- (NSArray*) writeValue:(NSString*)anObjId
{
	return [self readValues:[NSArray arrayWithObject:anObjId]];
}

- (void) writeValues:(NSArray*)someObjIds
{
	//the objID must have the form param.i t val
	//example: outputSwitch.u7 i 1
	if (sessionHandle){
		struct snmp_pdu *response;
				
		oid    anOID[MAX_OID_LEN];
		size_t anOID_len = MAX_OID_LEN;
		
		for(id anObjID in someObjIds){
			anObjID = [mibName stringByAppendingFormat:@"::%@",anObjID];
			struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_SET);
			NSArray* parts = [anObjID tokensSeparatedByCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]];
			if([parts count] == 3){
				const char* intoid = [[parts objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding];
				const char type    = [[parts objectAtIndex:1] characterAtIndex:0];
				const char* val    = [[parts objectAtIndex:2] cStringUsingEncoding:NSASCIIStringEncoding];

				if (snmp_parse_oid(intoid, anOID, &anOID_len) == NULL){
					snmp_perror(intoid);
					break;
				}
				if (snmp_add_var(pdu, anOID, anOID_len, type, val)){
					snmp_perror(intoid);
					break;
				}
				
				int status = snmp_synch_response(sessionHandle, pdu, &response);
				
				if (status == STAT_SUCCESS){
					if (response->errstat != SNMP_ERR_NOERROR){
						NSLog(@"Error in packet.\nReason: %s\n",snmp_errstring(response->errstat));
						break;
					}
				}
				else if (status == STAT_TIMEOUT){
					NSLog(@"SNMP SetTimeout: No Response from %s\n",sessionHandle->peername);
					break;
				}
				else { /* status == STAT_ERROR */
					snmp_sess_perror("snmpset", sessionHandle);
					break;
				}
			}
		}
	}
		/*	
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
		else { 
			snmp_sess_perror("snmpset", sessionHandle);
			return;
		}
	}
*/
}	

- (void) closeSession
{
	if(sessionHandle) {
		snmp_close(sessionHandle);
		sessionHandle = nil;
	}	
}

- (void) topLevelParse:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//split out the name from the value part
	NSArray* parts = [s componentsSeparatedByString:@"="];
	if([parts count] == 2){
		[self parseParmAndMibName:[parts objectAtIndex:0] intoDictionary:aDictionary];
		NSString* valuePart = [[parts objectAtIndex:1] stringByReplacingOccurrencesOfString:@"Opaque:" withString:@""];
		[self parseParamTypeAndValue:valuePart intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}

- (void) parseParmAndMibName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSArray* parts = [s componentsSeparatedByString:@"::"];
	if([parts count] == 2) {
		[aDictionary setObject:  [[parts objectAtIndex:0] trimSpacesFromEnds] forKey:@"Mib"];
		[self parseParameterName: [parts objectAtIndex:1] intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}

- (void) parseParameterName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//Example: "outputCurrentRiseRate.u0"
	NSArray* parts = [s componentsSeparatedByString:@"."];
	if([parts count] == 2) {
		[aDictionary setObject:[[parts objectAtIndex:0] trimSpacesFromEnds]  forKey:@"Name"];
		NSString* partAfterDot = [[parts objectAtIndex:1] trimSpacesFromEnds];
		if([partAfterDot hasPrefix:@"u"]){
			int value     = [[partAfterDot substringFromIndex:1] intValue];
			[aDictionary setObject:[NSNumber numberWithInt:(value / 100)+1]  forKey:@"Slot"];
			[aDictionary setObject:[NSNumber numberWithInt:value % 100]      forKey:@"Channel"];
		}
		else {
			int value     = [[partAfterDot substringFromIndex:1] intValue];
			[aDictionary setObject:[NSNumber numberWithInt:value]  forKey:@"SystemIndex"];
		}
	}
	else [aDictionary removeAllObjects];

}
- (void) parseParamTypeAndValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSArray* parts = [s componentsSeparatedByString:@":"];
	if([parts count] == 2) {
		[aDictionary setObject:[[parts objectAtIndex:0] trimSpacesFromEnds] forKey:@"Type"];
		[self parseParamValue:[parts objectAtIndex:1] intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}
- (void) parseParamValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSString* type = [aDictionary objectForKey:@"Type"];
	s = [s trimSpacesFromEnds];
	if([type isEqualToString:@"STRING"]) {
		NSString* result = [s stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		if([result length])[aDictionary setObject:result forKey:@"Value"];
	}
	else if([type isEqualToString:@"BITS"]){
		//Example: "BITS: 80 04 outputOn(0) outputEnableKill(13)"
		//NOTE: *****the order is from left to right, i.e. bit 0 is the left most bit in the string
		NSArray* parts = [s componentsSeparatedByString:@" "];
		NSString* theValue = @"";
		NSMutableArray* onBitNames = [NSMutableArray array];
		for(id aPart in parts){
			if([aPart rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == 0){
				theValue = [theValue stringByAppendingString:aPart];
			}
			else {
				NSRange rangeOfParen = [aPart rangeOfString:@"("];
				if(rangeOfParen.location != NSNotFound) [onBitNames addObject:[aPart substringToIndex:rangeOfParen.location]];
				else [onBitNames addObject:aPart];
			}
		}
		if([theValue length]){
			NSScanner* scanner = [NSScanner scannerWithString:theValue];
			unsigned x;
			[scanner scanHexInt:&x];
			[aDictionary setObject:[NSNumber numberWithUnsignedLong:x] forKey:@"Value"];
			if([onBitNames count])[aDictionary setObject:onBitNames forKey:@"OnBits"];
		}
	}
	else if([type isEqualToString:@"INTEGER"]){
		[self parseNumberWithUnits:s intoDictionary:aDictionary];
	}
	else if([type isEqualToString:@"Float"]){
		[self parseNumberWithUnits:s intoDictionary:aDictionary];
	}
	else if([type isEqualToString:@"Hex-STRING"]){
		[aDictionary setObject:s forKey:@"Value"];
	}
	else if([type isEqualToString:@"IpAddress"]){
		[aDictionary setObject:s forKey:@"Value"];
	}
	
	else [aDictionary removeAllObjects];
}

- (void) parseNumberWithUnits:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//Example: "1600 RPM"     --has units
	//Example: "64"  --no units
	NSArray* parts = [s componentsSeparatedByString:@" "];
	if([parts count] == 2){
		[aDictionary setObject:[NSNumber numberWithFloat:[s floatValue]] forKey:@"Value"];
		[aDictionary setObject:[parts objectAtIndex:1] forKey:@"Units"];
	}
	else {
		if([s hasPrefix:@"on"])		  [aDictionary setObject:[NSNumber numberWithFloat:1] forKey:@"Value"];
		else if([s hasPrefix:@"off"]) [aDictionary setObject:[NSNumber numberWithFloat:0] forKey:@"Value"];
		else [aDictionary setObject:[NSNumber numberWithFloat:[s floatValue]] forKey:@"Value"];
	}
}
@end
