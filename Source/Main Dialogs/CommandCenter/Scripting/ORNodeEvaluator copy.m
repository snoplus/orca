//
//  ORNodeEvaluator.m
//  Orca
//
//  Created by Mark Howe on 12/29/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ORNodeEvaluator.h"
#import "NodeTree.h"
#import "OrcaScript.h"
#import "ORCard.h"
#import "ORCamacCard.h"
#import "NSInvocation+Extensions.h"
#import "y.tab.h"
#import <math.h>
//----------------------------------------------------
// TDB.... rewrite to draw into NSView
/* interface for drawing */
#define lmax 200
#define cmax 200

char graph[lmax][cmax]; /* array for ASCII-Graphic */
int graphNumber = 0;

/* interface for drawing (can be replaced by "real" graphic using GD or other) */
void graphInit (void);
void graphFinish();
void graphBox (char *s, int *w, int *h);
void graphDrawBox (char *s, int c, int l);
void graphDrawArrow (int c1, int l1, int c2, int l2);

/* recursive drawing of the syntax tree */
void exNode (id p, int c, int l, int *ce, int *cm);

#define kColDis		  1
#define kGraphLineDis 3
//----------------------------------------------------

@interface ORNodeEvaluator (private)
- (id)		processStatements:(id) p;
- (id)		doOperation:(id) p;
- (id)		print:(id) p;
- (id)		arrayAssignment:(id)p leftBranch:(id)leftNode withValue:(id)aValue;
- (id)		doFunctionCall:(id)p args:(id)argNode;
- (id)		defineArray:(id) p;
- (id)		defineVariable:(id) p;
- (id)		processLeftArray:(id) p;
- (id)		processIf:(id) p;
- (id)		forLoop:(id) p;
- (id)		waitUntil:(id) p;
- (id)		whileLoop:(id) p;
- (id)		doLoop:(id) p;
- (id)		sleepFunc:(id) p;
- (id)		processObjC:(id) p;
- (id)		processDiv:(id) p;
- (id)		processDIV_ASSIGN:(id) p;
- (id)		doReturn:(id) p;
- (id)		doAssign:(id)p op:(int)opr;
- (id)		c1ArgFunction:(void*)afunc name:(NSString*)functionName  args:(NSArray*)valueArray;
- (id)		c2ArgFunction:(void*)afunc name:(NSString*)functionName  args:(NSArray*)valueArray;
@end

@implementation ORNodeEvaluator

#pragma mark •••Initialization
- (id) initWithFunctionTable:(id)aFunctionTable
{
	self = [super init];
	if(self) {
		functionTable = [aFunctionTable retain];
		_one  = [[NSDecimalNumber one] retain];
		_zero = [[NSDecimalNumber zero] retain];
	}  
	return self;  
}

-(void)dealloc 
{
	[functionTable release];
	[args release];
	[symbolTable release];
	[_one release];
	[_zero release];
	[parsedNodes release];
	[super dealloc];
}

- (NSUndoManager*) undoManager
{
	return [[NSApp delegate] undoManager];
}


#pragma mark •••Accessors
- (void) exitNow
{
	exitNow = YES;
}
- (NSString*) scriptName
{
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
    [scriptName autorelease];
    scriptName = [aString copy];	
}

#pragma mark •••Symbol Table Routines
- (void) setArgs:(NSArray*)someArgs
{

	[someArgs retain];
	[args release];
	args = someArgs;
	
	int i=0;
	id value;
	NSEnumerator* e = [args objectEnumerator];
	while(value = [e nextObject]){
		[self setValue:value forSymbol:[NSString stringWithFormat:@"$%d",i]];
		i++;
	}
}

- (void) setSymbolTable:(NSDictionary*)aSymbolTable
{
	if(!aSymbolTable)return;
	
	if(!symbolTable)symbolTable = [[NSMutableDictionary dictionaryWithDictionary:aSymbolTable] retain];
	else [symbolTable addEntriesFromDictionary:aSymbolTable];
}

- (id) valueForSymbol:(NSString*) aKey
{
	id aValue  = [symbolTable objectForKey:aKey];
	if(!aValue){
		aValue = [NSDecimalNumber zero];
		[self setValue:aValue forSymbol:aKey];
	}
	return aValue;
}

- (id) setValue:(id)aValue forSymbol:(id) aSymbol
{
	if(!aSymbol){
		NSLog(@"Warning: <%@> used before initialized... was set to zero\n",aSymbol);
		aValue = [NSDecimalNumber zero];
	}
	if(!symbolTable){
		symbolTable = [[NSMutableDictionary alloc] init];
	}
	[symbolTable setObject:aValue forKey:aSymbol];
	return aValue;
}

- (NSDictionary*) makeSymbolTableFor:(NSString*)functionName args:(id)argObject
{
	//the argObject could be either an array or an NSDecimalNumber  
	NSString* argumentNameString = [self execute:[functionTable objectForKey:[NSString stringWithFormat:@"%@_ArgNode",functionName]] ];

	NSMutableArray* valArray = [NSMutableArray array];
	if([argObject isKindOfClass:NSClassFromString(@"NSDecimalNumber") ]){
		[valArray addObject:argObject];
	}
	else {
		NSArray* valStringArray = [argObject componentsSeparatedByString:@","];
		int i;
		for(i=0;i<[valStringArray count];i++){
			[valArray addObject:[NSDecimalNumber decimalNumberWithString:[valStringArray objectAtIndex:i]]];
		}
	}
	if([valArray count]){
		NSArray* argKeys = [argumentNameString componentsSeparatedByString:@","];
		if([argKeys count])	return [NSDictionary dictionaryWithObjects:valArray forKeys:argKeys];
		else				return nil;
	}
	else return nil;
}

#pragma mark •••Individual Evaluators
#define NodeValue(aNode) [self execute:[[p nodeData] objectAtIndex:aNode]]
#define VARIABLENAME(aNode)  [[[p nodeData] objectAtIndex:aNode] nodeData]

- (id) execute:(id) p
{
	if(exitNow)return 0;
    if (!p) return 0;
    switch([(Node*)p type]) {
		case typeCon:				return [p nodeData];
		case typeStr:				return [p nodeData];
		case typeOperationSymbol:   return [p nodeData];
		case typeId:				return [self valueForSymbol:[p nodeData]];
		case typeArg:				return [self valueForSymbol:[p nodeData]];
		case typeSelVar:			return [p nodeData];
		case typeOpr:				return [self doOperation:p];
	}
	return nil; //should never actually get here.
}


#pragma mark •••Finders and Helpers
- (id) findObject:(id) p
{
	//needs to return NSDecimalNumber holding the obj pointer.
	Class theClass = NSClassFromString(VARIABLENAME(0));
	NSArray* objects = [[[NSApp delegate]  document] collectObjectsOfClass:theClass];
	if([objects count] == 0)return [NSDecimalNumber zero];
	if([[objects objectAtIndex:0] isKindOfClass:NSClassFromString(@"ORCard")])  return [self findCard:p collection:objects];
	else {
		int numArgs = [[p nodeData] count];
		if(numArgs == 1){
			//use the first obj found
			return [objects objectAtIndex:0];
		}
		else {
			//assume node 1 holds a tag #
			int tag = [NodeValue(1) longValue];
			id anObj;
			NSEnumerator* e = [objects objectEnumerator];
			while(anObj = [e nextObject]){
				if([anObj respondsToSelector:@selector(tag)]){
					if([anObj tag] == tag) {
						return anObj; 
					}
				}
			}
			return [NSDecimalNumber zero];
		}
	}
}

- (id) findCard:(id)p collection:objects
{
	//needs to return NSDecimalNumber holding the obj pointer.
	//CAMAC and AUGER use station numbers instead of slot number (station numbers are +1)
	id anObj;
	NSEnumerator* e = [objects objectEnumerator];
	NSDecimalNumber* dn = NodeValue(1);
	int searchNumber;
	if(dn)searchNumber = [dn intValue];
	else return nil;
	while(anObj = [e nextObject]){
		if([anObj respondsToSelector:@selector(stationNumber)]){
			if([anObj stationNumber] == searchNumber) {
				return anObj; 
			}
		}
		else {
			if([anObj slot] == searchNumber){
				return anObj;
			}
		}
	}
	return [NSDecimalNumber zero];
}


- (void) graphAll:(NSArray*)someNodes
{
	id aNode;
	NSEnumerator* e = [someNodes objectEnumerator];
	while(aNode = [e nextObject]){
		[self graph:aNode];
	}
}


-(id) graph:(id) p 
{
    int rte, rtm;
    graphInit ();
    exNode (p, 0, 0, &rte, &rtm);
    graphFinish();
    return 0;
}

@end

@implementation ORNodeEvaluator (private)
- (id) doOperation:(id) p
{
	NSComparisonResult result;
	id val;
	switch([[p nodeData] operatorTag]) {
						
		case ';':			return [self processStatements:p];
		case kFuncCall:		return [self doFunctionCall:p args:nil];
		case kFuncCallWithArgs:		return [self doFunctionCall:p args:NodeValue(1)];
		case COMMA:			return [[NSString stringWithFormat:@"%@",NodeValue(0)] stringByAppendingString:[@"," stringByAppendingFormat:@"%@",NodeValue(1)]];
		//array stuff
		case kDefineArray:	return [self defineArray:p];
		case kLeftArray:	return [self processLeftArray:p];
		case kArrayAssign:	return [self arrayAssignment:p leftBranch:[[p nodeData] objectAtIndex:0] withValue:NodeValue(1)];

		//loops
		case FOR:			return [self forLoop:p];
		case BREAK:			[NSException raise:@"break" format:nil]; return nil;
		case CONTINUE:		[NSException raise:@"continue" format:nil]; return nil;
		case RETURN:		return [self doReturn:p];
		case WHILE:			return [self whileLoop:p];
		case DO:			return [self doLoop:p];

		//built-in funcs
		case SLEEP:			return [self sleepFunc:p];
		case WAITUNTIL:		return [self waitUntil:p];

		//printing
		case PRINT:			return [self print:p];
		case kAppend:		return [[NSString stringWithFormat:@"%@",NodeValue(0)] stringByAppendingString:[@" " stringByAppendingFormat:@"%@",NodeValue(1)]];
		case HEX:			return [NSString stringWithFormat:@"0x%x",[NodeValue(0) longValue]];

		//obj-C ops
		case '@':			return [self processObjC:p];
		case kObjList:		return [NodeValue(0) stringByAppendingFormat:@"%@",NodeValue(1)];
		case kSelName:		return [NSString stringWithFormat:@"%@:%@ ",NodeValue(0),NodeValue(1)];
		case FIND:			return [self findObject:p];

		//math ops
		case EQ:			return [self setValue: NodeValue(1) forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
		case UMINUS:		return [[NSDecimalNumber decimalNumberWithString:@"-1"] decimalNumberByMultiplyingBy:NodeValue(0)];
		case MOD:			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] % [NodeValue(1) longValue]];
		case PLUS:			return [NodeValue(0) decimalNumberByAdding: NodeValue(1)];
		case MINUS:			return [NodeValue(0) decimalNumberBySubtracting: NodeValue(1)];
		case MULTI:			return [NodeValue(0) decimalNumberByMultiplyingBy: NodeValue(1)];
		case DIV:			return [self processDiv:p];
		case ADD_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberByAdding:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case SUB_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberBySubtracting:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case MUL_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberByMultiplyingBy:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case DIV_ASSIGN:	return [self processDIV_ASSIGN:p];
		case OR_ASSIGN:		return [self doAssign:p op:OR_ASSIGN];
		case LEFT_ASSIGN:	return [self doAssign:p op:LEFT_ASSIGN];
		case RIGHT_ASSIGN:	return [self doAssign:p op:RIGHT_ASSIGN];
		case MOD_ASSIGN:	return [self doAssign:p op:MOD_ASSIGN];
		case XOR_ASSIGN:	return [self doAssign:p op:XOR_ASSIGN];
		case AND_ASSIGN:	return [self doAssign:p op:AND_ASSIGN];
		
		//bit ops
		case AND:			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] & [NodeValue(1) longValue]];
		case OR:			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] | [NodeValue(1) longValue]];
		case LEFT_OP:		return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] << [NodeValue(1) longValue]];
		case RIGHT_OP:		return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] >> [NodeValue(1) longValue]];
		case TILDA:			return [NSDecimalNumber numberWithLong: ~[NodeValue(0) longValue]];
		case XOR:			return [NSDecimalNumber numberWithLong: [NodeValue(0) longValue] ^ [NodeValue(1) longValue]];
		
		//logic
		case IF:			return [self processIf:p];
		case QUES:  return [NodeValue(0) boolValue] ? NodeValue(1) : NodeValue(2);

		case NOT:  
			{
				if(![NodeValue(0) boolValue])return _one;
				else return _zero;
			}
			
		case AND_OP:
			if([NodeValue(0) longValue] && [NodeValue(1) longValue]) return _one;
			else return _zero;

		case OR_OP:
			if([NodeValue(0) longValue] || [NodeValue(1) longValue]) return _one;
			else return _zero;

		case GT:       
			if([NodeValue(0) compare: NodeValue(1)] == NSOrderedDescending) return _one;
			else return _zero;
			
		case LT:       
			if([NodeValue(0) compare: NodeValue(1)]==NSOrderedAscending)return _one;
			else return _zero;
			
		case LE_OP:       
			result = [NodeValue(0) compare: NodeValue(1)];
			if(result==NSOrderedSame || result==NSOrderedAscending)return _one;
			else return _zero;
			
		case GE_OP: 
			result = [NodeValue(0) compare: NodeValue(1)];
			if(result==NSOrderedSame || result==NSOrderedDescending)return _one;
			else return _zero;
			
		case NE_OP:       
			result = [NodeValue(0) compare: NodeValue(1)];
			if(result!=NSOrderedSame)return _one;
			else return _zero;
			
		case EQ_OP:    					
			result = [NodeValue(0) compare: NodeValue(1)];
			if(result==NSOrderedSame)return _one;
			else return _zero;
												
		//inc/dec ops
		case kPreInc: return [self setValue:[NodeValue(0) decimalNumberByAdding: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
		case kPreDec: return [self setValue:[NodeValue(0) decimalNumberBySubtracting: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];

		case kPostInc:
			val = NodeValue(0);
			[self setValue:[val decimalNumberByAdding: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
			return val;
			
		case kPostDec: 
			val = NodeValue(0);
			[self setValue:[val decimalNumberBySubtracting: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
			return val;
	}
    return 0; //should never actually get here.
}

- (id) processDiv:(id) p
{
	id result = nil;
	NS_DURING
		result =  [NodeValue(0) decimalNumberByDividingBy:NodeValue(1)];
	NS_HANDLER
		NSLog(@"divide by zero in %@\n",scriptName);
		result = [NSDecimalNumber notANumber];
	NS_ENDHANDLER
	return result;
}

- (id) processDIV_ASSIGN:(id)p
{
	id result = nil;
	NS_DURING
		result =  [self setValue:[NodeValue(0) decimalNumberByDividingBy:NodeValue(1)] forSymbol:VARIABLENAME(0)];
	NS_HANDLER
		NSLog(@"divide by zero in %@\n",scriptName);
		result = [NSDecimalNumber notANumber];
	NS_ENDHANDLER
	return result;
}

- (id) doAssign:(id)p op:(int)opr
{
	long value = [NodeValue(0) longValue];
	switch(opr){
		case LEFT_ASSIGN:  value <<= [NodeValue(1) intValue]; break;
		case RIGHT_ASSIGN: value >>= [NodeValue(1) intValue]; break;
		case MOD_ASSIGN:   value %=  [NodeValue(1) intValue]; break;
		case XOR_ASSIGN:   value ^=  [NodeValue(1) intValue]; break;
		case AND_ASSIGN:   value &=  [NodeValue(1) intValue]; break;
		case OR_ASSIGN:    value |=  [NodeValue(1) intValue]; break;
	}
	return [self setValue:[NSDecimalNumber numberWithLong:value] forSymbol:VARIABLENAME(0)];
}

- (id) processOR_ASSIGN:(id)p
{
	BOOL first  = ![NodeValue(0) boolValue] == 0;
	BOOL second = ![NodeValue(1) boolValue] == 0;
	first |= second;
	return [self setValue:[NSDecimalNumber numberWithBool:first] forSymbol:VARIABLENAME(0)];
}

- (id) processObjC:(id) p
{
	NSString* argList = NodeValue(1); //argList is string name:value name:value etc...
	argList = [argList stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[[self undoManager] disableUndoRegistration];
	id result =  [NSInvocation invoke:argList withTarget:NodeValue(0)];
	[[self undoManager] enableUndoRegistration];
	return result;
}

- (id) processStatements:(id) p
{
	unsigned numNodes = [[p nodeData] count];
	int i;
	for(i=0;i<numNodes;i++)NodeValue(i);
	return nil;
}					

- (id) print:(id) p
{
	NSString* s = [scriptName length]?scriptName:@"OrcaScript";
	NSLog(@"[%@] %@\n",s, NodeValue(0)); 
	return nil;
}	

- (id) arrayAssignment:(id)p leftBranch:(id)leftNode withValue:(id)aValue
{
	NSMutableArray* theArray = [self execute:[[leftNode nodeData] objectAtIndex:0]];
	int n = [[self execute:[[leftNode nodeData] objectAtIndex:1]] longValue];
	if(n>=0 && n<[theArray count]){
		id val = NodeValue(1);
		[theArray replaceObjectAtIndex:n withObject:val];
	}
	return nil;
}

- (id) doFunctionCall:(id)p args:(id)argObject
{
	id returnValue = nil;
	NSString* functionName = VARIABLENAME(0);
	id someNodes = [functionTable objectForKey:functionName];
	if(someNodes){
		ORNodeEvaluator* anEvaluator = [[ORNodeEvaluator alloc] initWithFunctionTable:functionTable];	
		[anEvaluator setSymbolTable:[self makeSymbolTableFor:functionName args:argObject]];
		
		NS_DURING
			id aNode;
			NSEnumerator* e = [someNodes objectEnumerator];
			while(aNode = [e nextObject]){
				[anEvaluator execute:aNode];
			}
		NS_HANDLER
			if([[localException name] isEqualToString: @"return"]){
				NSDictionary* userInfo = [localException userInfo];
				if(userInfo){
					returnValue = [userInfo objectForKey:@"returnValue"];
				}
			}
			else {
				[localException raise];
				[anEvaluator release];
			}
		NS_ENDHANDLER
		[anEvaluator release];
	}
	else {
		NSMutableArray* valArray = [NSMutableArray array];
		if([argObject isKindOfClass:NSClassFromString(@"NSDecimalNumber") ]){
			[valArray addObject:argObject];
		}
		else {
			NSArray* valStringArray = [argObject componentsSeparatedByString:@","];
			int i;
			for(i=0;i<[valStringArray count];i++){
				[valArray addObject:[NSDecimalNumber decimalNumberWithString:[valStringArray objectAtIndex:i]]];
			}
		}

		//could be a unix call -- check for the ones we support
		if([functionName isEqualToString:@"pow"])			return [self c2ArgFunction:&powf	name:@"pow"		args:valArray];
		else if([functionName isEqualToString:@"sqrt"])		return [self c1ArgFunction:&sqrtf	name:@"sqrt"	args:valArray];
		else if([functionName isEqualToString:@"ceil"])		return [self c1ArgFunction:&ceilf	name:@"ceil"	args:valArray];
		else if([functionName isEqualToString:@"floor"])	return [self c1ArgFunction:&floorf	name:@"floor"	args:valArray];
		else if([functionName isEqualToString:@"round"])	return [self c1ArgFunction:&roundf	name:@"round"	args:valArray];
		else if([functionName isEqualToString:@"cos"])		return [self c1ArgFunction:&cos		name:@"cos"		args:valArray];
		else if([functionName isEqualToString:@"sin"])		return [self c1ArgFunction:&sin		name:@"sin"		args:valArray];
		else if([functionName isEqualToString:@"tan"])		return [self c1ArgFunction:&tan		name:@"tan"		args:valArray];
		else if([functionName isEqualToString:@"acos"])		return [self c1ArgFunction:&acos	name:@"acos"	args:valArray];
		else if([functionName isEqualToString:@"asin"])		return [self c1ArgFunction:&asin	name:@"asin"	args:valArray];
		else if([functionName isEqualToString:@"atan"])		return [self c1ArgFunction:&atan	name:@"atan"	args:valArray];
		else if([functionName isEqualToString:@"abs"])		return [self c1ArgFunction:&fabs	name:@"abs"		args:valArray];
		else if([functionName isEqualToString:@"exp"])		return [self c1ArgFunction:&expf	name:@"exp"		args:valArray];
		else if([functionName isEqualToString:@"log"])		return [self c1ArgFunction:&logf	name:@"log"		args:valArray];
		else if([functionName isEqualToString:@"log10"])	return [self c1ArgFunction:&log10f	name:@"log10"		args:valArray];
		else {
			NSLog(@"%@ has no function called %@ in its function table. Check the syntax.\n",scriptName,functionName);
			[NSException raise:@"Run time" format:@"Function not found"];
		}
	}
	
	return returnValue;
}


- (id) defineArray:(id) p
{
	int n = [NodeValue(1) longValue];
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:n];
	//fill it with zeros;
	int i;
	for(i=0;i<n;i++)[theArray addObject:_zero];
	[self setValue:theArray forSymbol:VARIABLENAME(0)];
	return nil;
}

- (id) defineVariable:(id) p
{
	if(!symbolTable)symbolTable = [[NSMutableDictionary dictionary] retain];
	id varName = VARIABLENAME(0);
	[symbolTable setObject:_zero forKey:varName];	
	return varName;
}

- (id) processLeftArray:(id) p
{
	int n = [NodeValue(1) longValue];
	NSMutableArray* theArray = NodeValue(0);
	if(n>=0 && n<[theArray count]){
		return [theArray objectAtIndex:n];
	}
	else { //run time error
		[NSException raise:@"Array Bounds" format:@"Out of Bounds Error"];
	}
	return nil;
}

- (id) processIf:(id) p
{
	if (![NodeValue(0) isEqual: _zero])		  NodeValue(1);
	else if ([[(Node*)p nodeData] count] > 2) NodeValue(2);
	return nil;
}

- (id) doLoop:(id) p
{
	NS_DURING
		do {
			if(exitNow)break; 
			else {
				NS_DURING
					NodeValue(0);
				NS_HANDLER
					if(![[localException name] isEqualToString:@"continue"]){
						[localException raise]; //rethrow
					}
				NS_ENDHANDLER
			}
		} while(![NodeValue(1) isEqual:_zero]);
	NS_HANDLER
		if(![[localException name] isEqualToString:@"break"]){
			[localException raise]; //rethrow
		}
	NS_ENDHANDLER
	return nil;
}

- (id) whileLoop:(id)p
{
	NS_DURING
		while(![NodeValue(0) isEqual:_zero]){ 
			if(exitNow)break; 
			else {
				NS_DURING
					NodeValue(1);
				NS_HANDLER
					if(![[localException name] isEqualToString:@"continue"]){
						[localException raise]; //rethrow
					}
				NS_ENDHANDLER
			}
		}
	NS_HANDLER
		if(![[localException name] isEqualToString:@"break"]){
			[localException raise]; //rethrow
		}
	NS_ENDHANDLER
	return nil;
}

- (id) forLoop:(id) p
{
	NS_DURING
		for(NodeValue(0) ; ![NodeValue(1) isEqual: _zero] ; NodeValue(2)){
			if(exitNow)break;
			else {
				NS_DURING
					NodeValue(3);
				NS_HANDLER
					if(![[localException name] isEqualToString:@"continue"]){
						[localException raise]; //rethrow
					}
				NS_ENDHANDLER
			}
		}
	NS_HANDLER
		if(![[localException name] isEqualToString:@"break"]){
			[localException raise]; //rethrow
		}
	NS_ENDHANDLER
	return nil;
}

- (id) waitUntil:(id)p
{
	do {
		if(exitNow)break;
		if([NodeValue(0) boolValue]){
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
			break;
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
	}while(1);
	return nil;
}

- (id) sleepFunc:(id)p
{
	float delay = [NodeValue(0) floatValue];
	float total=0;
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		if(exitNow)break;
		total += .01;
	}while(total<delay);
	return nil;
}

- (id) doReturn:(id) p
{
	id returnValue = NodeValue(0);
	NSDictionary* userInfo;
	if(returnValue)	userInfo = [NSDictionary dictionaryWithObject:returnValue forKey:@"returnValue"];
	else			userInfo = [NSDictionary dictionaryWithObject:_zero forKey:@"returnValue"];
	NSException* excep = [[[NSException alloc] initWithName:@"return" reason:@"returnValue" userInfo:userInfo] autorelease];
	[excep raise];
	return nil; //never actually gets here.
}

- (id) c2ArgFunction:(void*)afunc name:(NSString*)functionName  args:(NSArray*)valueArray
{

	float (*pt2Func)(float,float);
	pt2Func = afunc;
	if([valueArray count] == 2){
		float arg0 = [[valueArray objectAtIndex:0] floatValue];
		float arg1 = [[valueArray objectAtIndex:1] floatValue];
		return [NSDecimalNumber numberWithFloat:pt2Func(arg0,arg1)];
	}
	else {
		NSLog(@"In %@, <%@> has wrong number of arguments. Check the syntax.\n",scriptName,functionName);
		[NSException raise:@"Run time" format:@"Arg list error"];
	}
	return nil;
}

- (id) c1ArgFunction:(void*)afunc name:(NSString*)functionName args:(NSArray*)valueArray
{

	float (*pt1Func)(float);
	pt1Func = afunc;
	if([valueArray count] == 1){
		float arg0 = [[valueArray objectAtIndex:0] floatValue];
		return [NSDecimalNumber numberWithFloat:pt1Func(arg0)];
	}
	else {
		NSLog(@"In %@, <%@> has wrong number of arguments. Check the syntax.\n",scriptName,functionName);
		[NSException raise:@"Run time" format:@"Arg list error"];
	}
	return nil;
}

@end

#pragma mark •••Parse Tree Graphics Routines
/*c----cm---ce---->                       drawing of leaf-nodes
 l leaf-info
 */

/*c---------------cm--------------ce----> drawing of non-leaf-nodes
 l            node-info
 *                |
 *    -------------     ...----
 *    |       |               |
 *    v       v               v
 * child1  child2  ...     child-n
 *        che     che             che
 *cs      cs      cs              cs
 *
 */

void exNode
    (   id p,
        int c, int l,        /* start column and line of node */
        int *ce, int *cm     /* resulting end column and mid of node */
    )
{
    int w, h;           /* node width and height */
    char *s;            /* node text */
    int cbar;           /* "real" start column of node (centred above subnodes) */
    int k;              /* child number */
    int che, chm;       /* end column and mid of children */
    int cs;             /* start column of children */
    char word[50];      /* extended node text */

    if (!p) return;
    strcpy (word, "???"); /* should never appear */
    s = word;
    switch([(Node*)p type]) {
        case typeCon: sprintf (word, "c(%ld)", [[p nodeData] longValue]); break;
        case typeId:  sprintf (word, "ident(%s)", [[p nodeData] cString]); break;
        case typeSelVar:  sprintf (word, "selVar(%s)", [[p nodeData] cString]); break;
        case typeStr:  sprintf (word, "string(%s)", [[p nodeData] cString]); break;
		case typeOperationSymbol: sprintf (word, "oper(%s)", [[p nodeData] cString]); break;
        case typeOpr:
            switch([[p nodeData] operatorTag]){
	
                case kDefineArray:	s = "[defineArray]"; break;
                case kArrayAssign:	s = "[=]"; break;
                case kLeftArray:    s = "[arrayLValue]"; break;
                case kRightArray:   s = "[arrayRValue]"; break;
                case QUES:		s = "[Conditional]"; break;
                case DO:		s = "[do]"; break;
                case WHILE:     s = "[while]"; break;
                case FOR:		s = "[for]"; break;
                case IF:        s = "[if]";    break;
                case PRINT:     s = "[print]"; break;
                case kPostInc:  s = "[postInc]";     break;
                case kPreInc:   s = "[preInc]";    break;
                case kPostDec:  s = "[postDec]";     break;
                case kPreDec:   s = "[prdDec]";    break;
                case kAppend:   s = "[append]";    break;
                case ';':       s = "[;]";     break;
                case EQ:       s = "[=]";     break;
                case UMINUS:    s = "[-]";     break;
                case TILDA:       s = "[~]";     break;
                case XOR:       s = "[^]";     break;
                case MOD:       s = "[%]";     break;
                case NOT:       s = "[!]";     break;
                case PLUS:       s = "[+]";     break;
                case MINUS:       s = "[-]";     break;
                case MULTI:       s = "[*]";     break;
                case DIV:       s = "[/]";     break;
                case LT:       s = "[<]";     break;
                case GT:       s = "[>]";     break;
                case LEFT_OP:	s = "[<<]";    break;
                case RIGHT_OP:	s = "[<<]";    break;
				case AND_OP:	s = "[&&]";     break;
				case AND:		s = "[&]";     break;
				case OR_OP:		s = "[||]";     break;
				case OR:		s = "[|]";     break;
				case GE_OP:     s = "[>=]";    break;
                case LE_OP:     s = "[<=]";    break;
                case NE_OP:     s = "[!=]";    break;
                case EQ_OP:     s = "[==]";    break;
				case '@':       s = "[ObjC]";  break;
				case kObjList:  s = "[ObjVarList]";  break;
				case kSelName:  s = "[ObjCVar]";  break;
				case BREAK:     s = "[break]";  break;
				case RETURN:    s = "[return]";  break;
				case CONTINUE:  s = "[continue]";  break;
				case SLEEP:     s = "[sleep]";  break;
				case HEX:		s = "[hex]";  break;
				case WAITUNTIL: s = "[waituntil]";  break;				
                case FIND:		s = "[find]";  break;
                case LEFT_ASSIGN:	s = "[<<=]";    break;
                case RIGHT_ASSIGN:	s = "[>>=]";    break;
                case ADD_ASSIGN:	s = "[+=]";    break;
                case SUB_ASSIGN:    s = "[-=]";    break;
                case MUL_ASSIGN:    s = "[*=]";    break;
                case DIV_ASSIGN:	s = "[/=]";    break;
                case OR_ASSIGN:		s = "[|=]";    break;
                case AND_ASSIGN:	s = "[&=]";    break;
                case kFuncCall:		s = "[call]";    break;
                case kFuncCallWithArgs:		s = "[call]";    break;
                case COMMA:			s = "[,]";    break;

            }
            break;
    }
	char line[64];
	sprintf(line,"%s (%d)",s,[p  line]);
    /* construct node text box */
    graphBox (s, &w, &h);
    cbar = c;
    *ce = c + w;
    *cm = c + w / 2;
	int count = 0;
	if ([(Node*)p type] == typeOpr){
		count = [[(Node*)p nodeData] count];
	}
    /* node is leaf */
   if ([(Node*)p type] == typeCon || [(Node*)p type] == typeId || count == 0) {
        graphDrawBox (s, cbar, l);
        return;
    }

    /* node has children */
    cs = c;
    for (k = 0; k < count; k++) {
        exNode ([[(Node*)p nodeData] objectAtIndex:k], cs, l+h+kGraphLineDis, &che, &chm);
        cs = che;
    }

    /* total node width */
    if (w < che - c) {
        cbar += (che - c - w) / 2;
        *ce = che;
        *cm = (c + che) / 2;
    }

    /* draw node */
    graphDrawBox (line, cbar, l);

    /* draw arrows (not optimal: children are drawn a second time) */
    cs = c;
    for (k = 0; k < count; k++) {
        exNode ([[(Node*)p nodeData] objectAtIndex:k], cs, l+h+kGraphLineDis, &che, &chm);
        graphDrawArrow (*cm, l+h, chm, l+h+kGraphLineDis-1);
        cs = che;
    }
}


void graphTest (int l, int c)
{   int ok;
    ok = 1;
    if (l < 0) ok = 0;
    if (l >= lmax) ok = 0;
    if (c < 0) ok = 0;
    if (c >= cmax) ok = 0;
    if (ok) return;
    printf ("\n+++error: l=%d, c=%d not in drawing rectangle 0, 0 ... %d, %d", l, c, lmax, cmax);
    //exit (1);
}

void graphInit (void) {
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = 0; j < cmax; j++) {
            graph[i][j] = ' ';
        }
    }
}

void graphFinish() 
{
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = cmax-1; j > 0 && graph[i][j] == ' '; j--);
        graph[i][cmax-1] = 0;
        if (j < cmax-1) graph[i][j+1] = 0;
        if (graph[i][j] == ' ') graph[i][j] = 0;
    }
    for (i = lmax-1; i > 0 && graph[i][0] == 0; i--);
    printf ("\n\nGraph %d:\n", graphNumber++);
    for (j = 0; j <= i; j++) printf ("\n%s", graph[j]);
    printf("\n");
}

void graphBox (char *s, int *w, int *h) 
{
    *w = strlen (s) + kColDis;
    *h = 1;
}

void graphDrawBox (char *s, int c, int l) 
{
    int i;
    graphTest (l, c+strlen(s)-1+kColDis);
    for (i = 0; i < strlen (s); i++) {
        graph[l][c+i+kColDis] = s[i];
    }
}

void graphDrawArrow (int c1, int l1, int c2, int l2) 
{
    int m;
    graphTest (l1, c1);
    graphTest (l2, c2);
    m = (l1 + l2) / 2;
    while (l1 != m) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    while (c1 != c2) { graph[l1][c1] = '-'; if (c1 < c2) c1++; else c1--; }
    while (l1 != l2) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    graph[l1][c1] = '|';
}