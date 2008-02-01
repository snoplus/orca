//
//  FilterScriptGraph.m
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
#include <string.h>
#import "StatusLog.h"

#include "FilterScript.h"
#include "FilterScript.tab.h"

int del = 1; /* distance of graph columns */
int eps = 3; /* distance of graph lines */

/* interface for drawing (can be replaced by "real" graphic using GD or other) */
void graphInit (void);
void graphFinish();
void graphBox (char *s, int *w, int *h);
void graphDrawBox (char *s, int c, int l);
void graphDrawArrow (int c1, int l1, int c2, int l2);

/* recursive drawing of the syntax tree */
void exNode (nodeType *p, int c, int l, int *ce, int *cm);

/*****************************************************************************/

/* main entry point of the manipulation of the syntax tree */
int filterGraph (nodeType *p ) {
    int rte, rtm;

    graphInit ();
    exNode (p, 0, 0, &rte, &rtm);
    graphFinish();
    return 0;
}

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
    (   nodeType *p,
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
    char word[20];      /* extended node text */

    if (!p) return;

    strcpy (word, "???"); /* should never appear */
    s = word;
    switch(p->type) {
        case typeCon: sprintf (word, "c(%ld)", p->con.value); break;
        case typeId:  sprintf (word, "(%s)", p->ident.key); break;
        case typeOpr:
            switch(p->opr.oper){
                case kConditional:		s="[Conditional]";	break;
                case DO:				s="[do]";			break;
                case WHILE:				s="[while]";		break;
                case FOR:				s="[for]";			break;
                case IF:				s="[if]";			break;
                case SWITCH:			s="[switch]";		break;
                case CASE:				s="[case]";		break;
                case DEFAULT:			s="[default]";		break;
                case PRINT:				s="[print]";		break;
                case kPostInc:			s="[postInc]";		break;
                case kPreInc:			s="[preInc]";		break;
                case kPostDec:			s="[postDec]";		break;
                case kPreDec:			s="[prdDec]";		break;
                case ';':				s="[;]";			break;
                case '=':				s="[=]";			break;
                case UMINUS:			s="[-]";			break;
                case '~':				s="[~]";			break;
                case '^':				s="[^]";			break;
                case '%':				s="[%]";			break;
                case '!':				s="[!]";			break;
                case '+':				s="[+]";			break;
                case '-':				s="[-]";			break;
                case '*':				s="[*]";			break;
                case '/':				s="[/]";			break;
                case '<':				s="[<]";			break;
                case '>':				s="[>]";			break;
                case LEFT_OP:			s="[<<]";			break;
                case RIGHT_OP:			s="[<<]";			break;
				case AND_OP:			s="[&&]";			break;
				case '&':				s="[&]";			break;
				case OR_OP:				s="[||]";			break;
				case '|':				s="[|]";			break;
				case GE_OP:				s="[>=]";			break;
                case LE_OP:				s="[<=]";			break;
                case NE_OP:				s="[!=]";			break;
                case EQ_OP:				s="[==]";			break;
				case BREAK:				s="[break]";		break;
				case CONTINUE:			s="[continue]";	break;
				case ALARM:				s="[alarm]";		break;				
				case CLEAR:				s="[clear]";		break;				
                case LEFT_ASSIGN:		s="[<<=]";			break;
                case RIGHT_ASSIGN:		s="[>>=]";			break;
                case ADD_ASSIGN:		s="[+=]";			break;
                case SUB_ASSIGN:		s="[-=]";			break;
                case MUL_ASSIGN:		s="[*=]";			break;
                case DIV_ASSIGN:		s="[/=]";			break;
                case OR_ASSIGN:			s="[|=]";			break;
                case AND_ASSIGN:		s="[&=]";			break;
                case ',':				s="[,]";			break;
                case HELLO:				s="[hello]";		break;
            }
            break;
    }

    /* construct node text box */
    graphBox (s, &w, &h);
    cbar = c;
    *ce = c + w;
    *cm = c + w / 2;

    /* node is leaf */
    if (p->type == typeCon || p->type == typeId || p->opr.nops == 0) {
        graphDrawBox (s, cbar, l);
        return;
    }

    /* node has children */
    cs = c;
    for (k = 0; k < p->opr.nops; k++) {
        exNode (p->opr.op[k], cs, l+h+eps, &che, &chm);
        cs = che;
    }

    /* total node width */
    if (w < che - c) {
        cbar += (che - c - w) / 2;
        *ce = che;
        *cm = (c + che) / 2;
    }

    /* draw node */
    graphDrawBox (s, cbar, l);

    /* draw arrows (not optimal: children are drawn a second time) */
    cs = c;
    for (k = 0; k < p->opr.nops; k++) {
        exNode (p->opr.op[k], cs, l+h+eps, &che, &chm);
        graphDrawArrow (*cm, l+h, chm, l+h+eps-1);
        cs = che;
    }
}

/* interface for drawing */

#define lmax 200
#define cmax 200

char graph[lmax][cmax]; /* array for ASCII-Graphic */
int graphNumber = 0;

void graphTest (int l, int c)
{   int ok;
    ok = 1;
    if (l < 0) ok = 0;
    if (l >= lmax) ok = 0;
    if (c < 0) ok = 0;
    if (c >= cmax) ok = 0;
    if (ok) return;
    printf ("\n+++error: l=%d, c=%d not in drawing rectangle 0, 0 ... %d, %d", 
        l, c, lmax, cmax);
    exit (1);
}

void graphInit (void) {
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = 0; j < cmax; j++) {
            graph[i][j] = ' ';
        }
    }
}

void graphFinish() {
    int i, j;
    for (i = 0; i < lmax; i++) {
        for (j = cmax-1; j > 0 && graph[i][j] == ' '; j--);
        graph[i][cmax-1] = 0;
        if (j < cmax-1) graph[i][j+1] = 0;
        if (graph[i][j] == ' ') graph[i][j] = 0;
    }
    for (i = lmax-1; i > 0 && graph[i][0] == 0; i--);
	NSString* aString = [NSString stringWithFormat:@"\nGraph %d:\n", graphNumber++];
    for (j = 0; j <= i; j++){
		aString = [aString stringByAppendingFormat:@"\n%s", graph[j]];
	}
    NSLogFont([NSFont fontWithName:@"Monaco" size:9],@"%@\n\n",aString);
}

void graphBox (char *s, int *w, int *h) {
    *w = strlen (s) + del;
    *h = 1;
}

void graphDrawBox (char *s, int c, int l) {
    int i;
    graphTest (l, c+strlen(s)-1+del);
    for (i = 0; i < strlen (s); i++) {
        graph[l][c+i+del] = s[i];
    }
}

void graphDrawArrow (int c1, int l1, int c2, int l2) {
    int m;
    graphTest (l1, c1);
    graphTest (l2, c2);
    m = (l1 + l2) / 2;
    while (l1 != m) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    while (c1 != c2) { graph[l1][c1] = '-'; if (c1 < c2) c1++; else c1--; }
    while (l1 != l2) { graph[l1][c1] = '|'; if (l1 < l2) l1++; else l1--; }
    graph[l1][c1] = '|';
}

