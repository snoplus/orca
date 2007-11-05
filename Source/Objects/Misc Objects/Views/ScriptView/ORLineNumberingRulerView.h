//  ORLineNumberingRulerView.h
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


extern const int MNNoLineNumbering;
extern const int MNParagraphNumber;
extern const int MNCharacterNumber;
extern const int MNLineNumber;
extern const int MNDrawBookmarks;

@interface ORLineNumberingRulerView : NSRulerView {
	
	NSMutableDictionary*	marginAttributes;	
	NSTextView*				textView;
	NSLayoutManager*		layoutManager;
	int						rulerOption;
}

- (void) setVisible:(BOOL)flag;
- (BOOL) isVisible;
- (void) setOption:(unsigned)option;

////// private
- (unsigned) lineNumberAtIndex:(unsigned)charIndex;

- (void) drawEmptyMargin;
- (void) drawNumbersInMargin;
- (void) drawOneNumberInMargin:(unsigned) aNumber inRect:(NSRect)r ;

- (unsigned) characterIndexAtLocation:(float)pos;
@end
