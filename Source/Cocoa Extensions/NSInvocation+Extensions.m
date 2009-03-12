//
//  NSInvocation+Extensions.m
//  Orca
//
//  Created by Mark Howe on Thu Feb 12 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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



@implementation NSInvocation (OrcaExtensions)
+ (SEL) makeSelectorFromArray:(NSArray*)cmdItems
{
    int n = [cmdItems count];
    int i=0;
    NSMutableString* theSelectorString = [NSMutableString string];
    if(n>1)for(i=0;i<n;i+=2){
        [theSelectorString appendFormat:@"%@:",[cmdItems objectAtIndex:i]];
    }
        else [theSelectorString appendFormat:@"%@",[cmdItems objectAtIndex:i]];
    
    return NSSelectorFromString(theSelectorString);
}

- (BOOL) setArgument:(int)argIndex to:(id)aVal
{
    argIndex += 2; 
    const char *theArg = [[self methodSignature] getArgumentTypeAtIndex:argIndex];
    if(*theArg == 'c'){
        char c = (char)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'i'){
        int c = [aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 's'){
        short c = (short)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'l'){
        long c = (long)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'C'){
        unsigned char c = (unsigned char)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'I'){
        unsigned int c = [aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'S'){
        unsigned short c = (unsigned short)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'L'){
        unsigned long c = [aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'f'){
        float c = [aVal floatValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'd'){
        double c = [aVal doubleValue];
        [self setArgument:&c atIndex:argIndex];
    }
	else if(*theArg == 'B'){
		BOOL c;
		if([aVal class] == [NSString class]){
			if(!strncmp([aVal cStringUsingEncoding:NSASCIIStringEncoding],"YES",3))c = 1;
			else if(!strncmp([aVal cStringUsingEncoding:NSASCIIStringEncoding],"NO",2))c = 0;
		}
		else c = (bool)[aVal intValue];
		[self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == '@'){
        [self setArgument:&aVal atIndex:argIndex];
    }
	else if(!strncmp(theArg,"{_NSP",5)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSPoint thePoint = NSMakePoint([[xy objectAtIndex:0] floatValue], [[xy objectAtIndex:1] floatValue]);
		[self setArgument:&thePoint atIndex:argIndex];
	}
	else if(!strncmp(theArg,"{_NSR",5)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSRect theRect = NSMakeRect([[xy objectAtIndex:0] floatValue], 
									[[xy objectAtIndex:1] floatValue],
									[[xy objectAtIndex:2] floatValue],
									[[xy objectAtIndex:3] floatValue]);
		[self setArgument:&theRect atIndex:argIndex];
	}
	
    else return NO;
    
    return YES;
    
}

- (id) returnValue
{

    NSString* returnValueAsString = @"0";

    const char *theArg = [[self methodSignature] methodReturnType];

    if(*theArg == 'c'){
	char buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithChar:buffer] stringValue];
    }
    else if(*theArg == 'i'){
	int buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithInt:buffer] stringValue];
    }
    else if(*theArg == 's'){
	short buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithShort:buffer] stringValue];
    }
    else if(*theArg == 'l'){
	long buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithLong:buffer] stringValue];
    }
    else if(*theArg == 'C'){
	unsigned char buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithUnsignedChar:buffer] stringValue];
    }
    else if(*theArg == 'I'){
	unsigned int buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithUnsignedInt:buffer] stringValue];
    }
    else if(*theArg == 'S'){
 	unsigned short buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithUnsignedShort:buffer] stringValue];
    }
    else if(*theArg == 'L'){
 	unsigned long buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithUnsignedLong:buffer] stringValue];
    }
    else if(*theArg == 'f'){
 	float buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithFloat:buffer] stringValue];
    }
    else if(*theArg == 'd'){
 	double buffer;
        [self getReturnValue:&buffer]; 
	returnValueAsString = [[NSNumber numberWithDouble:buffer] stringValue];
    }
    else if(*theArg == 'B'){
 	BOOL buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithBool:buffer] stringValue];
    }
    else if(*theArg == '@'){
		id obj;
        [self getReturnValue:&obj]; 
		return obj;
    }
	else if(!strncmp(theArg,"{_NSP",5)){
		NSPoint thePoint;
        [self getReturnValue:&thePoint]; 
		return [NSString stringWithFormat:@"@(%f,%f)",thePoint.x,thePoint.y];
	}
	else if(!strncmp(theArg,"{_NSR",5)){
		NSRect theRect;
        [self getReturnValue:&theRect]; 
		return [NSString stringWithFormat:@"@(%f,%f,%f,%f)",theRect.origin.x,theRect.origin.y,theRect.size.width,theRect.size.height];
	}

    if(returnValueAsString)return [NSDecimalNumber decimalNumberWithString:returnValueAsString];
    else return [NSDecimalNumber decimalNumberWithString:@"0"];
}

+ (id) invoke:(NSString*)args withTarget:(id)aTarget
{
	id result = nil;
	//args is string of "name:value name:value etc..."
	NSArray* pairList = [args componentsSeparatedByString:@"#"];
	NSMutableArray* orderedList = [NSMutableArray array];
	NSString* pairString;
	int n = [pairList count];
	int i;
	for(i=0;i<n;i++){
		pairString = [pairList objectAtIndex:i];
		NSRange rangeOfFirstColon = [pairString rangeOfString:@":"];
		NSString* part1 = nil;
		NSString* part2 = nil;
		if(rangeOfFirstColon.location!=NSNotFound){
			part1 = [pairString substringToIndex:rangeOfFirstColon.location];
			part2 = [pairString substringFromIndex:rangeOfFirstColon.location+1];
		}
		else part1 = pairString;
		if(part1)[orderedList addObject:part1];
		if(part2)[orderedList addObject:part2];
	}

	SEL theSelector = [NSInvocation makeSelectorFromArray:orderedList];
	int returnLength = 0;
	if([aTarget respondsToSelector:theSelector]){
		NSMethodSignature* theSignature = [aTarget methodSignatureForSelector:theSelector];
		returnLength = [theSignature methodReturnLength];
		NSInvocation* theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
		[theInvocation setSelector:theSelector];
		int n = [theSignature numberOfArguments]-2; //first two are hidden
		int i;
		int argI;
		BOOL ok = YES;
		for(i=1,argI=0 ; i<=n*2 ; i+=2,argI++){
			id theVar = [orderedList objectAtIndex:i];
			if(![theInvocation setArgument:argI to:theVar]){
				ok = NO;
				break;
				
			}
		}
		if(ok){
			[theInvocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:aTarget waitUntilDone:YES];
			//[theInvocation invokeWithTarget:aTarget];
			if(returnLength!=0)result =  [theInvocation returnValue];
		}
	}
	else {
		NSLog(@"Command not recognized: <%@>.\n",NSStringFromSelector(theSelector));
		result = [NSDecimalNumber zero];
	}
	return result;
}

@end
