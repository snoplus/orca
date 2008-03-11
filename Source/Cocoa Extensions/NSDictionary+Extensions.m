//
//  NSDictionary+Extensions.m
//  Orca
//
//  Created by Mark Howe on 10/4/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


@implementation NSDictionary (OrcaExtensions)

- (NSArray*) allKeysStartingWith:(NSString*)aString
{
    NSArray* allKeys = [self allKeys];
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[allKeys count]];
    NSEnumerator* e = [allKeys objectEnumerator];
    id s;
    while(s = [e nextObject]){
        if([s rangeOfString:aString].location == 0){
            [result addObject:s];
        }
    }
    return result;
}

- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	if([anArray count] == 0)return self;
	else {
		id aKey = [anArray objectAtIndex:0];
		[anArray removeObjectAtIndex:0];
		id anObj = [self objectForKey:aKey];
		if([anObj respondsToSelector:@selector(objectForKeyArray:)]){
			return [anObj objectForKeyArray:anArray];
		}
		else {
			if(anObj)return anObj;
			else return self;
		}
    }
}

- (id) nestedObjectForKey:(id)firstKey,...
{
    va_list myArgs;
    va_start(myArgs,firstKey);
    
    NSString* s = firstKey;
	id result = [self objectForKey:s];
	while(s = va_arg(myArgs, NSString *)) {
		result = [result objectForKey:s];
    }
    va_end(myArgs);
	
	return result;
}

- (NSData*) asData
{
    //write request to temp file because we want the form you get from a disk file...the string to property list isn't right.
    char* tmpName = tempnam([[@"~" stringByExpandingTildeInPath]cStringUsingEncoding:NSASCIIStringEncoding] ,"ORCADictionaryXXX");
	NSString* thePath = [NSString stringWithCString:tmpName];
    [self writeToFile:thePath atomically:YES];
    NSData* data = [NSData dataWithContentsOfFile:thePath];
	[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:tmpName] handler:nil];
    free(tmpName);
	return data;
}

+ (id) dictionaryWithPList:(id)plist
{
	//write request to temp file because we want the form you get from a disk file...the string to property list isn't right.
	char* tmpName = tempnam([[@"~" stringByExpandingTildeInPath]cStringUsingEncoding:NSASCIIStringEncoding] ,"ORCADictionaryXXX");
	NSString* thePath = [NSString stringWithCString:tmpName];
	[plist writeToFile:thePath atomically:YES];
	NSDictionary* theResponse = [NSDictionary dictionaryWithContentsOfFile:thePath];
	[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:tmpName] handler:nil];
	free(tmpName);
	return theResponse;
}
@end
