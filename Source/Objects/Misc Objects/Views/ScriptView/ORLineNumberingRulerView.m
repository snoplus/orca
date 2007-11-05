//  ORLineNumberingRulerView.m
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



#import "ORLineNumberingRulerView.h"

// Ruler thickness value
#define RULER_THICKNESS					25

// Margin of displaying bookmarked line in a context menu.
#define STRIP_PREVIEW_MARGIN			15

// Default
#define DEFAULT_OPTION					MNLineNumber


const int MNNoLineNumbering = 0x00;
const int MNLineNumber		= 0x01;

@implementation ORLineNumberingRulerView

- (id)initWithScrollView:(NSScrollView *)aScrollView orientation:(NSRulerOrientation)orientation
{
	
	if ( self = [super initWithScrollView:(NSScrollView *)aScrollView
							  orientation:(NSRulerOrientation)orientation]){		
		// Set default width
		[self setRuleThickness:RULER_THICKNESS];
				
		// Set letter attributes
		marginAttributes = [[NSMutableDictionary alloc] init];
		[marginAttributes setObject:[NSFont labelFontOfSize:9] forKey: NSFontAttributeName];
		[marginAttributes setObject:[NSColor darkGrayColor] forKey: NSForegroundColorAttributeName];
	
		rulerOption = DEFAULT_OPTION;
		
		textView = [aScrollView documentView];
		layoutManager = [textView layoutManager];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowDidUpdate:)
													 name:NSWindowDidUpdateNotification
												   object:[aScrollView window]];
	}
	
    return self;
}


- (void)windowDidUpdate:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
}

-(unsigned)lineNumberAtIndex:(unsigned)charIndex
{
	unsigned index = 0;
	unsigned lineNumber = 1;
	NSRange lineRange;
	
	//convert charindex to glyphIndex
	
	unsigned glyphIndex = [layoutManager glyphRangeForCharacterRange:NSMakeRange(charIndex,1)
												actualCharacterRange:NULL].location;
	
	// Skip all lines that are visible at the top of the text view (if any)
	while ( index < glyphIndex ){
		++lineNumber;
		
		[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		index = NSMaxRange( lineRange );
	}
	
	return lineNumber;
}

-(void)setVisible:(BOOL)flag
{
	if( flag == YES )
		[self setRuleThickness:RULER_THICKNESS];
	else
		[self setRuleThickness:0];
	
}
-(BOOL)isVisible
{
	if( [self ruleThickness] == 0 )
		return NO;
	else
		return YES;
	
}
-(void)setOption:(unsigned)option
{
	rulerOption = option;
	[self display];
}

- (void) dealloc
{
	//NSLog(@"view dealloc");
	[layoutManager setDelegate:NULL];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self ];
	
	
	textView = NULL;
	layoutManager = NULL;
	
    [marginAttributes release];
	
    [super dealloc];
}

#pragma mark Drawing

-(void)drawRect:(NSRect)rect
{
	if( ! [[self window] isKeyWindow] ) return;
	[super drawRect:rect];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect 
	//Draw numbers
{	
	if( [self isVisible] ){
		
		// *** (1) draw background ***
		[self drawEmptyMargin  ];
		
		// *** (2) draw numbers ***
		[self drawNumbersInMargin ];
		
	}		
	
}

-(void)drawEmptyMargin
{
	NSRect aRect = NSMakeRect(0,0,[self ruleThickness],[self frame].size.height);
	/*
     These values control the color of our margin. Giving the rect the 'clear' 
     background color is accomplished using the windowBackgroundColor.  Change 
     the color here to anything you like to alter margin contents.
	 */
	
	aRect.origin.x += 1;
    [[NSColor controlHighlightColor] set];
    [NSBezierPath fillRect: aRect]; 
    
	
	// These points should be set to the left margin width.
    NSPoint top = NSMakePoint([self frame].size.width, aRect.origin.y + aRect.size.height);
    NSPoint bottom = NSMakePoint([self frame].size.width, aRect.origin.y);
	
	
	// This draws the dark line separating the margin from the text area.
    [[NSColor darkGrayColor] set];
    [NSBezierPath setDefaultLineWidth:1.0];
    [NSBezierPath strokeLineFromPoint:top toPoint:bottom];
	
	
}

-(void) drawParagraphNumbersInMargin:(unsigned)startParagraph start:(unsigned)start_index end:(unsigned)end_index
{
	unsigned index;
	for ( index = start_index; index < end_index;  ){
		NSRange paragraphRange = 
		[textView selectionRangeForProposedRange:NSMakeRange(index, 1) granularity:NSSelectByParagraph];
		
		unsigned glyphIndex = [layoutManager glyphRangeForCharacterRange:NSMakeRange(paragraphRange.location,1)
													actualCharacterRange:NULL].location;
		
		NSRect drawingRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange: NULL];
		
		[self drawOneNumberInMargin:startParagraph inRect:drawingRect];
		
		index  = NSMaxRange( [layoutManager glyphRangeForCharacterRange:paragraphRange
												   actualCharacterRange:NULL] );
		
		startParagraph++;
	}
}


-(void) drawNumbersInMargin
{
	//NSLog(@"drawNumbersInMargin");
	
	UInt32		index, lineNumber;
	NSRange		lineRange;
	NSRect		lineRect;
	
	NSTextContainer* textContainer = [[layoutManager firstTextView] textContainer];
	
	// Only get the visible part of the scroller view
	NSRect documentVisibleRect = [[[layoutManager firstTextView] enclosingScrollView] documentVisibleRect];
	
	// Find the glyph range for the visible glyphs
	NSRange glyphRange = [layoutManager glyphRangeForBoundingRect: documentVisibleRect inTextContainer: textContainer];
	
	
	// Calculate the start and end indexes for the glyphs	
	unsigned start_index = glyphRange.location;
	unsigned end_index = glyphRange.location + glyphRange.length;
	
	//
	NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	// Calculate the start and end char indexes	
	unsigned start_charIndex =	charRange.location;
	
	
	index = 0;
	lineNumber = 1;
	
	unsigned start_paragraphNumber;
	start_paragraphNumber = [self lineNumberAtIndex:start_charIndex];
	
	// Skip all lines that are visible at the top of the text view (if any)
	while (index < start_index){
		lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		index = NSMaxRange( lineRange );
		++lineNumber;
	}
	
	for ( index = start_index; index < end_index; lineNumber++ ){
		lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		
		
		if(  ( rulerOption & 0x0F ) ==  MNLineNumber ){
			[self drawOneNumberInMargin:lineNumber inRect:lineRect];
		}		
		
		index = NSMaxRange( lineRange );
    }	
}


-(void)drawOneNumberInMargin:(unsigned) aNumber inRect:(NSRect)r 
{
	//draw a number
	r = [textView convertRect:r toView:self]; //Convert coordinates
	
    NSString    *s;
    NSSize      stringSize;
    
    s = [NSString stringWithFormat:@"%d", aNumber, nil];
	if( aNumber == 0 )
		s = @"-";
    stringSize = [s sizeWithAttributes:marginAttributes];
	
	// Simple algorithm to center the line number next to the glyph.
    [s drawAtPoint: NSMakePoint( [self ruleThickness] - stringSize.width, 
								 r.origin.y + ((r.size.height / 2) - (stringSize.height / 2))) 
								withAttributes:marginAttributes];
}



///////////
- (BOOL) acceptsFirstResponder
{
	return NO;
}
-(unsigned)characterIndexAtLocation:(float)pos
{
	
	//convert
	float viewPos = [textView convertPoint:NSMakePoint(0,pos) fromView:[[self window] contentView]].y;
	
	NSRect sweepRect = NSMakeRect( 0,viewPos,100,viewPos+1);
	
	NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:sweepRect inTextContainer:[textView textContainer] ];
	NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	
	//NSLog(@"characterIndexAtLocation = %d",charRange.location);
	return charRange.location;
}

#pragma mark Context Menu

-(void)menu_selected	{}	// dummy method.
-(void)menu_selected_main:(NSNotification *)notification
	// this is called when contextual menu is selected
{
	
	NSMenuItem* aMenuItem = [[notification userInfo] objectForKey:@"MenuItem"];
	int tag = [aMenuItem tag];
	if( tag == -1 )		[self setOption: MNNoLineNumbering];
	else if( tag == -2 )	[self setOption: MNLineNumber];
	else if( tag == -3 )	[self setVisible:![self isVisible]];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenuItem* aMenuItem;
	NSMenu* menu = [[NSMenu alloc] init];
	
	////////
	NSMenu* submenu = [[NSMenu alloc] init];
	aMenuItem = [[NSMenuItem alloc] initWithTitle:@"No Line Numbering" action:@selector(menu_selected)
									keyEquivalent:@""];
	[aMenuItem setTag:-1];
	[aMenuItem setTarget:self];
	[aMenuItem setState:( (rulerOption & 0x0F) == MNNoLineNumbering ? NSOnState : NSOffState)];
	[submenu addItem:[aMenuItem autorelease]];
	
	
	////////
	aMenuItem = [[NSMenuItem alloc] initWithTitle:@"Line Number" action:@selector(menu_selected)
									keyEquivalent:@""];
	[aMenuItem setTag:-2];
	[aMenuItem setTarget:self];
	[aMenuItem setState:( (rulerOption & 0x0F) == MNLineNumber ? NSOnState : NSOffState)];
	[submenu addItem:[aMenuItem autorelease]];
	
	
	////////
	aMenuItem = [[NSMenuItem alloc] initWithTitle:@"Hide Ruler"	 action:@selector(menu_selected)
									keyEquivalent:@""];
	[aMenuItem setTag:-3];
	[aMenuItem setTarget:self];
	[aMenuItem setState:( ![self isVisible] ? NSOnState : NSOffState)];
	[submenu addItem:[aMenuItem autorelease]];
	
	
	////////
	aMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Options" action:@selector(menu_selected)
									keyEquivalent:@""];
	[aMenuItem setTag:-6];
	[aMenuItem setTarget:self];
	[menu addItem:[aMenuItem autorelease]];
	[menu setSubmenu:[submenu autorelease] forItem:aMenuItem];
	
	
	////////
	//OBSERVE CONTEXT MENU
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menu_selected_main:)
												 name:NSMenuDidSendActionNotification object:menu];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menu_selected_main:)
												 name:NSMenuDidSendActionNotification object:submenu];
	
	return [menu autorelease];
	
}


@end
