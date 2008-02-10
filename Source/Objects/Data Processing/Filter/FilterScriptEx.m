//
//  FilterScriptEx.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 25 2008.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#include <stdio.h>
#include "FilterScript.h"
#include "ORFilterModel.h"
#include "FilterScript.tab.h"
#import "StatusLog.h"
#import "ORDataTypeAssigner.h"

extern unsigned short   switchLevel;
extern long				switchValue[512];
extern nodeType** allFilterNodes;
extern long filterNodeCount;
extern long maxFilterNodeCount;
filterData ex(nodeType*,id);

void runFilterScript(id delegate)
{
	unsigned node;
	for(node=0;node<filterNodeCount;node++){
		NS_DURING
			ex(allFilterNodes[node],delegate);
		NS_HANDLER
		NS_ENDHANDLER
	}
}

void doSwitch(nodeType *p, id delegate)
{
	NS_DURING
		switchLevel++;
		switchValue[switchLevel] = ex(p->opr.op[0],delegate).val.lValue;
		ex(p->opr.op[1],delegate);
	NS_HANDLER
		if(![[localException name] isEqualToString:@"break"]){
			switchValue[switchLevel] = 0;
			switchLevel--;
			[localException raise]; //rethrow
		}
	NS_ENDHANDLER
	switchValue[switchLevel] = 0;
	switchLevel--;
}

void doCase(nodeType *p, id delegate)
{
	if(switchValue[switchLevel] == ex(p->opr.op[0],delegate).val.lValue){
		ex(p->opr.op[1],delegate);
		if (p->opr.nops == 3)ex(p->opr.op[2],delegate);
	}
}

void doDefault(nodeType *p, id delegate)
{
	ex(p->opr.op[0],delegate);
	if (p->opr.nops == 2)ex(p->opr.op[1],delegate);
}


void doLoop(nodeType *p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	do {
		if([delegate exitNow])break; 
		else {
			NS_DURING
				ex(p->opr.op[0],delegate);
			NS_HANDLER
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			NS_ENDHANDLER
		}
		if(breakLoop)break;
		if(continueLoop)continue;
	} while(ex(p->opr.op[1],delegate).val.lValue);
}

void whileLoop(nodeType* p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	while(ex(p->opr.op[0],delegate).val.lValue){ 
		if([delegate exitNow])break; 
		else {
			NS_DURING
				ex(p->opr.op[1],delegate);
			NS_HANDLER
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			NS_ENDHANDLER
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

void forLoop(nodeType* p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	for(ex(p->opr.op[0],delegate).val.lValue ; ex(p->opr.op[1],delegate).val.lValue ; ex(p->opr.op[2],delegate).val.lValue){
		if([delegate exitNow])break;
		else {
			NS_DURING
				ex(p->opr.op[3],delegate);
			NS_HANDLER
				if([[localException name] isEqualToString:@"continue"])  continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			NS_ENDHANDLER
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

void defineArray(nodeType* p, id delegate)
{
	int n = ex(p->opr.op[1],delegate).val.lValue;
	long* ptr = 0;
	if(n>0) ptr = calloc(n, sizeof(long));
	filterData tempData;
	tempData.type		= kFilterPtrType;
	tempData.val.pValue = ptr;
	[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
}

void freeArray(nodeType* p, id delegate)
{
	filterData theFilterData;
	if([symbolTable getData:&theFilterData forKey:p->opr.op[0]->ident.key]){
		if(theFilterData.type == kFilterPtrType){
			if(theFilterData.val.pValue !=0){
				free(theFilterData.val.pValue);
				theFilterData.val.pValue = 0;
				[symbolTable setData:theFilterData forKey:p->opr.op[0]->ident.key];
			}
			//else {
			//	[NSException raise:@"Access Violation" format:@"Free of NIL pointer"];
			//}
		}
	}
}


//long arrayAssignment(nodeType* p, id delegate)
//{
//	int n = ex(p->opr.op[1],delegate).val.lValue;
//	long* ptr = ex(p->opr.op[0],delegate).val.pValue;
//	return ptr[n];
//	else { //run time error
//		[NSException raise:@"Array Bounds" format:@"Out of Bounds Error"];
//	}
//}

/*void arrayAssignment:(id)p leftBranch:(id)leftNode withValue:(id)aValue
{
	long* ptr = ex(p->opr.op[1],delegate).val.pValue;
	
	NSMutableArray* theArray = [self execute:[[leftNode nodeData] objectAtIndex:0] container:nil];
	int n = [[self execute:[[leftNode nodeData] objectAtIndex:1] container:nil] longValue];
	if(n>=0 && n<[theArray count]){
		id val = NodeValue(1);
		[theArray replaceObjectAtIndex:n withObject:val];
	}
	return nil;
}
*/
filterData ex(nodeType *p,id delegate) 
{
	filterData tempData = {0,{0}};
	filterData tempData1 = {0,{0}};
    if (!p) {
		tempData.type = kFilterLongType;
		tempData.val.lValue = 0;

	}
    switch(p->type) {
		case typeCon:       
			tempData.type = kFilterLongType;
			tempData.val.lValue = p->con.value;
		return tempData;
		
		case typeId:       
			[symbolTable getData:&tempData forKey:p->ident.key];
			return tempData;
			
		case typeOpr:
			switch(p->opr.oper) {
			case DO:		doLoop(p,delegate); return tempData;
			case WHILE:     whileLoop(p,delegate); return tempData;
			case FOR:		forLoop(p,delegate); return tempData;
			case CONTINUE:	[NSException raise:@"continue" format:nil]; return tempData;
			case IF:        if (ex(p->opr.op[0],delegate).val.lValue) ex(p->opr.op[1],delegate);
							else if (p->opr.nops > 2) ex(p->opr.op[2],delegate);
							return tempData;
			case BREAK:		[NSException raise:@"break" format:nil]; return tempData;
			case SWITCH:	doSwitch(p,delegate); return tempData;
			case CASE:		doCase(p,delegate); return tempData;
			case DEFAULT:	doDefault(p,delegate); return tempData;
			case PRINT:
					tempData = ex(p->opr.op[0],delegate);
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) printf("%ld\n", *tempData.val.pValue); 
						else					printf("<nil ptr>\n"); 
					}
					else printf("%ld\n", tempData.val.lValue); 
			return tempData;
			
			case PRINTH:
					tempData = ex(p->opr.op[0],delegate);
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) printf("0x%07lx\n", *tempData.val.pValue); 
						else					printf("<nil ptr>\n"); 
					}
					else printf("0x%07lx\n", tempData.val.lValue); 
			return tempData;
			case ';':       if (p->opr.nops>=1) ex(p->opr.op[0],delegate); if (p->opr.nops>=2)return ex(p->opr.op[1],delegate); else return tempData;
			case '=':      
				{
					tempData = ex(p->opr.op[1],delegate);
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
				}
			case UMINUS: 
				tempData = ex(p->opr.op[0],delegate);
				tempData.val.lValue = -tempData.val.lValue;
			return tempData;
			
			case '+':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue + ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '-':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue - ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '*':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue * ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '/':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue / ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '<':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue < ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '>':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue > ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '^':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue ^ ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '%':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue % ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '|':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue | ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case '&':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue & ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case GE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue >= ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case LE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue <= ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case NE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue != ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case EQ_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue == ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case LEFT_OP:   tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue << ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case RIGHT_OP:  tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue >> ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case AND_OP:	tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue && ex(p->opr.op[1],delegate).val.lValue; return tempData;
			case OR_OP:		tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue || ex(p->opr.op[1],delegate).val.lValue; return tempData;

			case RIGHT_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue>>ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;
				
			case LEFT_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue<<ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case MUL_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue * ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case DIV_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue / ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case OR_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue | ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case MOD_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue % ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case AND_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue & ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;

			case XOR_ASSIGN: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue ^ ex(p->opr.op[1],delegate).val.lValue;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;


			case kPostInc: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue;
				tempData1 = tempData;
				tempData1.val.lValue++;
				[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
				return tempData;
				
			case kPreInc: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue+1;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;
				
			case kPostDec: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue;
				tempData1 = tempData;
				tempData1.val.lValue--;
				[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
				
			case kPreDec: 
				tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue-1;
				[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
				return tempData;


			//array stuff
			case kArrayAssign:
				{
					long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						*ptr = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = *ptr;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
			return tempData;

			case kLeftArray:
				{
					long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						long offset = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterPtrType;
						tempData.val.pValue = ptr+offset;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
			return tempData;

			case kArrayElement:
				{
					long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						long offset = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = ptr[offset];
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
			return tempData;

			case kDefineArray:		defineArray(p,delegate); return tempData;
			case FREEARRAY:			freeArray(p,delegate); return tempData;
			//case kLeftArray:		return [self processLeftArray:p];
			//case kArrayAssign:      arrayAssignment(p,delegate); return;

			//case kArrayListAssign:	
			//	tempData.type = kFilterLongType;
			//	defineArray(p,delegate); return tempData;return [self arrayList:p];

			case EXTRACTRECORD_ID: 
				tempData.val.lValue =  [delegate extractRecordID:ex(p->opr.op[0],delegate).val.lValue]; 
			return tempData;

			case EXTRACTRECORD_LEN: 
				tempData.val.lValue =  [delegate extractRecordLen:ex(p->opr.op[0],delegate).val.lValue]; 
			return tempData;
			
			case SHIP_RECORD:
				{
					long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr) [delegate shipRecord:ptr length:ExtractLength(*ptr)]; 
				}
			break;

			case PUSH_RECORD:
				{
					long stack = ex(p->opr.op[0],delegate).val.lValue;
					long* ptr  = ex(p->opr.op[1],delegate).val.pValue;
					if(ptr)[delegate pushOntoStack:stack record:ptr]; 
				}
			break;

			case POP_RECORD:
				{
					long stack = ex(p->opr.op[0],delegate).val.lValue;
					tempData.val.pValue = [delegate popFromStack:stack];
				}
			return tempData;

			case SHIP_STACK:
				{
					long stack = ex(p->opr.op[0],delegate).val.lValue;
					[delegate shipStack:stack];
				}
			return tempData;
		}
    }
    return tempData;
}

