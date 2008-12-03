//
//  NSData+Extensions.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 04 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

@implementation NSData (OR_NSDataWithExtensions)

#pragma mark ¥¥¥Class Methods
+(NSData*)dataWithNSPoint:(NSPoint)aPoint
{
    return [NSData dataWithBytes:&aPoint length:sizeof(NSPoint)];
}

+(NSData*)dataWithNSRect:(NSRect)aRect
{
    return [NSData dataWithBytes:&aRect length:sizeof(NSRect)];
}


#pragma mark ¥¥¥Conversions
-(NSPoint)pointValue
{
    return *((NSPoint*)[self bytes]);
}

-(NSRect)rectValue
{
    return *((NSRect*)[self bytes]);
}

- (NSArray *)rowsAndColumns
{
	NSString *fileContents;
	
	@try {
		fileContents = [[[NSString alloc] initWithData: self encoding: NSASCIIStringEncoding] autorelease];
   	}
	@catch(NSException* localException) {
		fileContents = nil;
		[NSException raise: @"Format Error"
					format: @"There was a problem reading your file.  Please make sure that it is a Tab delimited file.  Additional information:\n\nException: %@\nReason: %@\nDetail: %@", 
		 [localException name], 
		 [localException reason], 
		 [localException userInfo]];
	}
	
	return [[fileContents lines] valueForKey: @"tabSeparatedComponents"];
}

- (NSString *)description
{
	unsigned char *bytes = (unsigned char *)[self bytes];
	NSMutableString *s   = [NSMutableString stringWithFormat:@"NSData (total length: %d bytes):\n", [self length]];
	int maxIndex = 1024;
	int i, j;
	int len = MIN([self length],maxIndex);
	for (i=0 ; i<len ; i+=16 ){
		for (j=0 ; j<16 ; j++) {
			int index = i+j;
			if (index < maxIndex)	[s appendFormat:@"%02X ", bytes[index]];
			else				[s appendFormat:@"   "];
		}
		
		[s appendString:@"| "];   
		for (j=0 ; j<16 ; j++){
			int index = i+j;
			if (index < maxIndex){
				unsigned char c = bytes[index];
				if (c < 32 || c > 127) c = '.';
				[s appendFormat:@"%c", c];
			}
		}
		
		if (i+16 < maxIndex)[s appendString:@"\n"]; //all but last row gets a newline
	}
	
	return s;	
}

@end
