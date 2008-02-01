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

extern unsigned short   switchLevel;
extern long				switchValue[512];


long ex(nodeType*,id);
void doSwitch(nodeType *p, id delegate)
{
	NS_DURING
		switchLevel++;
		switchValue[switchLevel] = ex(p->opr.op[0],delegate);
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
	if(switchValue[switchLevel] == ex(p->opr.op[0],delegate)){
		ex(p->opr.op[1],delegate);
		if (p->opr.nops == 3)ex(p->opr.op[2],delegate);
	}
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
	} while(ex(p->opr.op[1],delegate));
}

void whileLoop(nodeType* p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	while(ex(p->opr.op[0],delegate)){ 
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
	for(ex(p->opr.op[0],delegate) ; ex(p->opr.op[1],delegate) ; ex(p->opr.op[2],delegate)){
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

long ex(nodeType *p,id delegate) {
    if (!p) return 0;
	long tempValue;
    switch(p->type) {
		case typeCon:       return p->con.value;
		case typeId:       
			{
				long theValue;
				[symbolTable getData:&theValue forKey:p->ident.key];
				return theValue;
			}
		break;
		case typeOpr:
			switch(p->opr.oper) {
			case DO:		doLoop(p,delegate); return 0;
			case WHILE:     whileLoop(p,delegate); return 0;
			case FOR:		forLoop(p,delegate); return 0;
			case CONTINUE:	[NSException raise:@"continue" format:nil]; return 0;
			case IF:        if (ex(p->opr.op[0],delegate))     ex(p->opr.op[1],delegate);
							else if (p->opr.nops > 2) ex(p->opr.op[2],delegate);
							return 0;
			case BREAK:		[NSException raise:@"break" format:nil]; return 0;
			case SWITCH:	doSwitch(p,delegate); return 0;
			case CASE:		doCase(p,delegate); return 0;
			case PRINT:     NSLog(@"%d\n", ex(p->opr.op[0],delegate)); return 0;
			case ';':       ex(p->opr.op[0],delegate); return ex(p->opr.op[1],delegate);
			case '=':      
				{
					long theValue = ex(p->opr.op[1],delegate);
					[symbolTable setData:theValue forKey:p->opr.op[0]->ident.key];
					return theValue;
				}
			case UMINUS:    return -ex(p->opr.op[0],delegate);
			case '+':       return ex(p->opr.op[0],delegate) + ex(p->opr.op[1],delegate);
			case '-':       return ex(p->opr.op[0],delegate) - ex(p->opr.op[1],delegate);
			case '*':       return ex(p->opr.op[0],delegate) * ex(p->opr.op[1],delegate);
			case '/':       return ex(p->opr.op[0],delegate) / ex(p->opr.op[1],delegate);
			case '<':       return ex(p->opr.op[0],delegate) < ex(p->opr.op[1],delegate);
			case '>':       return ex(p->opr.op[0],delegate) > ex(p->opr.op[1],delegate);
			case '^':       return ex(p->opr.op[0],delegate) ^ ex(p->opr.op[1],delegate);
			case '%':       return ex(p->opr.op[0],delegate) % ex(p->opr.op[1],delegate);
			case '|':       return ex(p->opr.op[0],delegate) | ex(p->opr.op[1],delegate);
			case '&':       return ex(p->opr.op[0],delegate) & ex(p->opr.op[1],delegate);
			case GE_OP:     return ex(p->opr.op[0],delegate) >= ex(p->opr.op[1],delegate);
			case LE_OP:     return ex(p->opr.op[0],delegate) <= ex(p->opr.op[1],delegate);
			case NE_OP:     return ex(p->opr.op[0],delegate) != ex(p->opr.op[1],delegate);
			case EQ_OP:     return ex(p->opr.op[0],delegate) == ex(p->opr.op[1],delegate);
			case LEFT_OP:   return ex(p->opr.op[0],delegate) << ex(p->opr.op[1],delegate);
			case RIGHT_OP:  return ex(p->opr.op[0],delegate) >> ex(p->opr.op[1],delegate);
			case AND_OP:	return ex(p->opr.op[0],delegate) && ex(p->opr.op[1],delegate);
			case OR_OP:		return ex(p->opr.op[0],delegate) || ex(p->opr.op[1],delegate);

			case RIGHT_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)>>ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;
			case LEFT_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)<<ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case MUL_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)*ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case DIV_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)/ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case OR_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)|ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case MOD_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)%ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case AND_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)&ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case XOR_ASSIGN: 
				tempValue = ex(p->opr.op[0],delegate)^ex(p->opr.op[1],delegate);
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;


			case kPostInc: 
				tempValue = ex(p->opr.op[0],delegate);
				[symbolTable setData:tempValue+1 forKey:p->opr.op[0]->ident.key];
				return tempValue;
			case kPreInc: 
				tempValue = ex(p->opr.op[0],delegate)+1;
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;
			case kPostDec: 
				tempValue = ex(p->opr.op[0],delegate);
				[symbolTable setData:tempValue-1 forKey:p->opr.op[0]->ident.key];
				return tempValue;
			case kPreDec: 
				tempValue = ex(p->opr.op[0],delegate)-1;
				[symbolTable setData:tempValue forKey:p->opr.op[0]->ident.key];
				return tempValue;

			case HELLO: return [delegate hello:ex(p->opr.op[0],delegate)];

        }
    }
    return 0;
}

