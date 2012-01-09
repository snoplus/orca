//
//  SNODetectorView.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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

#import "SNODetectorView.h"
#import "ORPSUPTubePosition.h"
#import "ORColorScale.h"
#import "ORAxis.h"

NSString* selectionStringChanged			 = @"selectionStringChanged";

@implementation SNODetectorView

- (id)initWithFrame:(NSRect)frameRect
{	
	[super initWithFrame:frameRect];
	db = [SNOMonitoredHardware sharedSNOMonitoredHardware];
	crateRectsInCrateView = [[NSMutableArray alloc] init];
	cardRectsInCrateView = [[NSMutableArray alloc] init];
	channelRectsInCrateView = [[NSMutableArray alloc] init];
	channelRectsInPSUPView = [[NSMutableArray alloc] init];
	pmtColorArray = [[NSMutableArray alloc] init];
	selectionMode = kTubeSelectionMode;
	[self getRectPositions];
	pickPSUPView=YES;
	parameterToDisplay = 1;
	[self updateSNODetectorView];
	return self;
}

- (void)dealloc
{
	[crateRectsInCrateView release];
	[cardRectsInCrateView release];
	[channelRectsInCrateView release];
	[channelRectsInPSUPView release];
	[pmtColorArray release];
	[super dealloc];
}

- (void) setViewType:(BOOL)aViewType
{
	pickPSUPView = aViewType;
}

- (void) setParameterToDisplay:(int)aParameter
{
	parameterToDisplay = aParameter;
}

- (void) setSelectionMode:(int)aMode
{
	selectionMode = aMode;
}

- (NSMutableString *) selectionString
{
	return selectionString;
}

- (void) formatDetectorTitleString
{
	if (detectorTitle) {[detectorTitle release];};
	
	NSString *aString =[NSString stringWithFormat:@""];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Papyrus" size:20], 
								NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	if (parameterToDisplay == kOnlineTubeDisplay){
		aString = [NSString stringWithFormat:@"Online tubes"];
	}else if (parameterToDisplay == kTubeTypeDisplay){
		aString = [NSString stringWithFormat:@"Tube type"];
	}else if (parameterToDisplay == kPedestalsDisplay){
		aString = [NSString stringWithFormat:@"Pedestals"];
	}else if (parameterToDisplay == kThresholdsDisplay){
		aString = [NSString stringWithFormat:@"Thresholds"];
	}else if (parameterToDisplay == kVBalsLoDisplay){
		aString = [NSString stringWithFormat:@"V Bals Lo"];
	}else if (parameterToDisplay == kVBalsHiDisplay){
		aString = [NSString stringWithFormat:@"V Bals Hi"];
	}else if (parameterToDisplay == kCmosRatesDisplay){
		aString = [NSString stringWithFormat:@"CMOS Rates"];
	}else if (parameterToDisplay == kHvOnDisplay){
		aString = [NSString stringWithFormat:@"HV On"];
	}else if (parameterToDisplay == kRelaysDisplay){
		aString = [NSString stringWithFormat:@"Relays"];
	}else if (parameterToDisplay == kThreshMaxDisplay){
		aString = [NSString stringWithFormat:@"Thresh Max"];
	}else if (parameterToDisplay == kSequencerDisplay){
		aString = [NSString stringWithFormat:@"Sequencer"];
	}else if (parameterToDisplay == k20nsTriggerDisplay){
		aString = [NSString stringWithFormat:@"20 ns Trigger"];
	}else if (parameterToDisplay == k100nsTriggerDisplay){
		aString = [NSString stringWithFormat:@"100 ns Trigger"];
	}else if (parameterToDisplay == kCmosReadDisplay){
		aString = [NSString stringWithFormat:@"CMOS Read"];
	}else if (parameterToDisplay == kQllDisplay){
		aString = [NSString stringWithFormat:@"Qll"];
	}else if (parameterToDisplay == kTempDisplay){
		aString = [NSString stringWithFormat:@"Temperature"];
	}else if (parameterToDisplay == kFifoDisplay){
		aString = [NSString stringWithFormat:@"FIFO"];
	}else if (parameterToDisplay == kBaseCurrentDisplay){
		aString = [NSString stringWithFormat:@"Base Currents"];
	}else if (parameterToDisplay == kCheckerMismatchesDisplay){
		aString = [NSString stringWithFormat:@"Checker Mistmatch"];
	}else if (parameterToDisplay == kRatesDisplay){
		aString = [NSString stringWithFormat:@"Rates"];
	}else if (parameterToDisplay == kCrateVoltagesDisplay){
		aString = [NSString stringWithFormat:@"Crate Voltages"];
	}
	
	detectorTitle=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
}

- (void) formatGlobalStatsString
{
	if (globalStatsString) {[globalStatsString release];}
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:10], 
								NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
	globalStatsString=[[NSMutableAttributedString alloc] initWithString:@"Overall detector statistics:  " attributes: attributes];
	
	if (parameterToDisplay == kTubeTypeDisplay){
		NSString *aString =[NSString stringWithFormat:@"Normal tubes:%i, ",numTubesOnline];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
									NSFontAttributeName,[NSColor greenColor], NSForegroundColorAttributeName, nil];
		NSAttributedString *currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Unknown tubes:%i, ",numUnknownTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"OWL tubes:%i, ",numOwlTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor blueColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Low gain tubes:%i, ",numLowGainTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor yellowColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Butt tubes:%i, ",numButtTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor brownColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Neck tubes:%i",numNeckTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor cyanColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
	}
}

- (void) getRectPositions
{
	float scaleFactor = 1.005*([self bounds].size.width-20)/kPSUP_width;
	float tubeSize = 4.*[self bounds].size.width/kPSUP_width;

	int crate, card, pmt;
	float x,y;
	for(crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				x = psupTubePosition[tubeIndex].x * scaleFactor;
				y = (psupTubePosition[tubeIndex].y-22) * scaleFactor;
				NSRect tubeRect = NSMakeRect(x-tubeSize/2.,y-tubeSize/2.,tubeSize,tubeSize);
				[channelRectsInPSUPView insertObject:[NSBezierPath bezierPathWithOvalInRect:tubeRect] atIndex:tubeIndex];
			}
		}
	}
		
	float xc = [self bounds].size.width/2.;
	float yc = [self bounds].size.height/2.;
	float segSize = [self bounds].size.height/100.;
		
	//Establish crate areas in the view window
	NSRect crateRect = NSMakeRect(xc,yc,segSize*16,segSize*32);
		
	float xOffset, yOffset;
	for(crate=0;crate<kMaxSNOCrates;++crate){
		if (crate<10) {
			xOffset=-5.5*segSize*16+crate*segSize*17.5;
			yOffset=-1.2*segSize*32;
			NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
			[crateRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:crate];
		}else if (crate >=10){
			xOffset=-5.5*segSize*16+(crate-10)*segSize*17.5;
			yOffset=0.2*segSize*32;			
			NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
			[crateRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:crate];
		}
	}
		
	//card areas
	NSRect cardRect = NSMakeRect(xc,yc,segSize,segSize*32);
	for (crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<16;card++){
			int cardIndex = kCardsPerCrate * crate + card;
			if (crate<10){
				xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
				yOffset=-1.2*segSize*32;	
					
				NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
				[cardRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:cardIndex];
			}else if (crate>=10){
				xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
				yOffset=0.2*segSize*32;
					
				NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
				[cardRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:cardIndex];
			}
		}
	}
		
		
	//channel areas
	NSRect tubeRect = NSMakeRect(xc,yc,segSize,segSize);
	for (crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				if (crate<10){
					xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
					yOffset=-1*pmt*segSize-0.2*segSize*32-segSize;	
						
					NSRect theRect = NSOffsetRect(tubeRect,xOffset,yOffset);
					[channelRectsInCrateView insertObject:[NSBezierPath bezierPathWithOvalInRect:theRect] atIndex:tubeIndex];
				}else if (crate>=10){
					xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
					yOffset=-1*pmt*segSize+1.2*segSize*32-segSize;	
						
					NSRect theRect = NSOffsetRect(tubeRect,xOffset,yOffset);
					[channelRectsInCrateView insertObject:[NSBezierPath bezierPathWithOvalInRect:theRect] atIndex:tubeIndex];
				}
			}
		}
	}	
}

- (void) drawRect:(NSRect)aRect
{	
	int crate, card, pmt, tubeIndex;
	NSBezierPath *aPath;
	
	[detectorTitle drawAtPoint:NSMakePoint([self bounds].size.width*0.42,5)];
	
	if (pickPSUPView){
		
		float xc = [self bounds].size.width/60.;
		float yc = [self bounds].size.height/13.;
		//float segSize = [self bounds].size.height/100.;
		//xOffset=-5.5*segSize*16+crate*segSize*17.5;
		//yOffset=-1.2*segSize*32;
		NSRect backRect = NSMakeRect(xc,yc,[self bounds].size.width*0.99,[self bounds].size.height*0.89);
		[[NSColor blackColor] set];
		[NSBezierPath fillRect:backRect];
		
		//draw psup in grey
		float scaleFactor = 1.005*([self bounds].size.width-20)/kPSUP_width;
		
		int i;
		float xoffset = 25;
		float yoffset = 17;
		for(i=0;i<kCMPSUPSTRUT;i++){
			float x1 = (PSUPstrut[i].x1+xoffset) * scaleFactor;
			float y1 = (PSUPstrut[i].y1+yoffset) * scaleFactor;
			float x2 = (PSUPstrut[i].x2+xoffset) * scaleFactor;
			float y2 = (PSUPstrut[i].y2+yoffset) * scaleFactor;
			[[NSColor grayColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		}

		//draw pmts as filled circles with given colour
		for (crate=0;crate<kMaxSNOCrates;crate++){
			for(card=0;card<kNumSNOCards;card++){
				for(pmt=0;pmt<kNumSNOPmts;pmt++){
					tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
					[[pmtColorArray objectAtIndex:tubeIndex] set];
					[[channelRectsInPSUPView objectAtIndex:tubeIndex] fill];
					aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
					[aPath setLineWidth:highlightLineWidth-2.5];
					[[NSColor grayColor] set];
					[aPath stroke];								
				}
			}
		}
		
		//highlight selected pmt at mousedown
		if(selectedCrate>=0 && selectedCard>=0 && selectedChannel >=0){	
			if (selectionMode == kTubeSelectionMode){
				tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + selectedChannel;
				aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
				[aPath setLineWidth:highlightLineWidth-1];
				//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[NSColor whiteColor] set];
				[aPath stroke];
			
				selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i Channel %i\n",selectedCrate,selectedCard,selectedChannel];
				[selectionString appendString:[NSString stringWithFormat:@"PMT ID: %@\n",[db pmtID:selectedCrate card:selectedCard channel:selectedChannel]]];
				float x,y,z;
				x=[db xpos:selectedCrate card:selectedCard channel:selectedChannel];
				y=[db ypos:selectedCrate card:selectedCard channel:selectedChannel];
				z=[db zpos:selectedCrate card:selectedCard channel:selectedChannel];
				if ([db tubeTypeCrate:selectedCrate card:selectedCard channel:selectedChannel]==kTubeTypeNormal){
					[selectionString appendString:[NSString stringWithFormat:@"x=%f, y=%f, z=%f\n",x,y,z]];
				} else {
					[selectionString appendString:[NSString stringWithFormat:@"x=N/A, y=N/A, z=N/A\n"]];
				}
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
			} else if (selectionMode == kCardSelectionMode) {
				for (pmt=0;pmt<kNumSNOPmts;pmt++){
					tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + pmt;
					aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
					[aPath setLineWidth:highlightLineWidth-2];
					//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
					[[NSColor whiteColor] set];
					[aPath stroke];					
				}
				selectionString = [NSString stringWithFormat:@"Crate %i Card %i\n",selectedCrate,selectedCard];
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
			} else if (selectionMode == kCrateSelectionMode){
				for(card=0;card<kNumSNOCards;card++){
					for (pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * selectedCrate+ kChannelsPerBoard* card + pmt;
						aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
						[aPath setLineWidth:highlightLineWidth-2];
						//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
						[[NSColor whiteColor] set];
						[aPath stroke];			
					}
				}
				selectionString = [NSString stringWithFormat:@"Crate %i\n",selectedCrate];
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];				
			}
		}else{
			selectionString = [NSString stringWithFormat:@"No hardware selected\n"];
			[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
		}

		[globalStatsString drawAtPoint:NSMakePoint(30,[self bounds].size.height*0.97)];
		
	}else if (!pickPSUPView){
		
		float xc = [self bounds].size.width/2.;
		float yc = [self bounds].size.height/2.;
		float segSize = [self bounds].size.height/100.;
		
		//Establish crate areas
		NSRect crateRect = NSMakeRect(xc,yc,segSize*16,segSize*32);
		
		float xOffset, yOffset;
		for(crate=0;crate<kMaxSNOCrates;++crate){
			if (crate<10) {
				xOffset=-5.5*segSize*16+crate*segSize*17.5;
				yOffset=-1.2*segSize*32;
				NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
				[NSBezierPath strokeRect:theRect];
				[[NSColor blackColor] set];
				[NSBezierPath fillRect:theRect];
				
			}else if (crate >=10){
				xOffset=-5.5*segSize*16+(crate-10)*segSize*17.5;
				yOffset=0.2*segSize*32;			
				NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
				[NSBezierPath strokeRect:theRect];
				[[NSColor blackColor] set];
				[NSBezierPath fillRect:theRect];
				
			}
			
			NSString *crateName=[NSString stringWithFormat:@"Crate %i",crate];
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:12], 
										NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
			NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:crateName attributes: attributes];
			[currentText drawAtPoint:NSMakePoint(xc+xOffset+20,yc+yOffset+180)];
			[currentText release];
			
			[[NSColor grayColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*8) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*8)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*16) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*16)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*24) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*24)];
		}
		
		//draw Cards
		NSRect cardRect = NSMakeRect(xc,yc,segSize,segSize*32);
		for (crate=0;crate<kMaxSNOCrates;crate++){
			for(card=0;card<16;card++){
				if (crate<10){
					xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
					yOffset=-1.2*segSize*32;	
					
					NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
					[[NSColor grayColor] set];
					[NSBezierPath strokeRect:theRect];
				}else if (crate>=10){
					xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
					yOffset=0.2*segSize*32;
					
					NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
					[[NSColor grayColor] set];
					[NSBezierPath strokeRect:theRect];	
				}
				
				if (card%4==0){
					NSString *cardNum=[NSString stringWithFormat:@"%i",card];
					NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:9], 
												NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
					NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:cardNum attributes: attributes];
					[currentText drawAtPoint:NSMakePoint(xc+xOffset,yc+yOffset+172)];
					[currentText release];
					
					[NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset+segSize*0.5,yc+yOffset+174) 
											  toPoint:NSMakePoint(xc+xOffset+segSize*0.5,yc+yOffset+168)];
				}
			}
		}
		
		
		//draw Channels as filled circles with pre-determined colour
		for (crate=0;crate<kMaxSNOCrates;crate++){
			for(card=0;card<kNumSNOCards;card++){
				for(pmt=0;pmt<kNumSNOPmts;pmt++){
					tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
					[[pmtColorArray objectAtIndex:tubeIndex] set];
					[[channelRectsInCrateView objectAtIndex:tubeIndex] fill];
				}
			}
		}
		
		//highlight selected pmt at mousedown
		if(selectedCrate>=0 && selectedCard>=0 && selectedChannel >=0){	
			if (selectionMode == kTubeSelectionMode) {
				tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + selectedChannel;
				aPath  = [channelRectsInCrateView objectAtIndex:tubeIndex];
				[aPath setLineWidth:highlightLineWidth-1];
				//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[NSColor whiteColor] set];
				[aPath stroke];
				
				selectionString = [NSString stringWithFormat:@"Crate %i Card %i Channel %i\n",selectedCrate,selectedCard,selectedChannel];
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
			}else if (selectionMode == kCardSelectionMode) {
				int cardIndex = kCardsPerCrate * selectedCrate + selectedCard;
			    aPath  = [cardRectsInCrateView objectAtIndex:cardIndex];
				[aPath setLineWidth:highlightLineWidth-1];
				//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[NSColor whiteColor] set];
				[aPath stroke];
				
				selectionString = [NSString stringWithFormat:@"Crate %i Card %i\n",selectedCrate,selectedCard];
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
			}else if (selectionMode == kCrateSelectionMode) {
				aPath  = [crateRectsInCrateView objectAtIndex:selectedCrate];
				[aPath setLineWidth:highlightLineWidth-1];
				[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				//[[NSColor whiteColor] set];
				[aPath stroke];
				
				selectionString = [NSString stringWithFormat:@"Crate %i\n",selectedCrate];
				[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
			}
		}else{
			selectionString = [NSString stringWithFormat:@"No hardware selected\n"];
			[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
		}
		
		[globalStatsString drawAtPoint:NSMakePoint(10,[self bounds].size.height*0.97)];
	}
}


//update display with respect to selected view (crate or PSUP), variable type, mousedown etc
- (void)updateSNODetectorView
{
	if (pmtColorArray) [pmtColorArray release], pmtColorArray=nil;
	pmtColorArray = [[NSMutableArray alloc] init];
	[self formatDetectorTitleString];
	
	int pmt,card,crate,tubeIndex;
	float fecfifo,xl3rate;

	//clear all colors first
	for (crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				[pmtColorArray insertObject:[NSColor clearColor] atIndex:tubeIndex];
			}
		}
	}
	
	//if (pickPSUPView) {
		if (parameterToDisplay == kTubeTypeDisplay){
			numTubesOnline=0,numUnknownTubes=0,numOwlTubes=0,numLowGainTubes=0,numButtTubes=0,numNeckTubes=0;
			for (crate=0;crate<kMaxSNOCrates;crate++){
				for(card=0;card<kNumSNOCards;card++){
					for(pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
						NSColor *tubeColor = [db pmtColor:crate card:card channel:pmt];
						if ([NSColor greenColor]==tubeColor){
							numTubesOnline++;
						}else if ([NSColor blackColor]==tubeColor) {
							numUnknownTubes++;
						}else if ([NSColor blueColor]==tubeColor) {
							numOwlTubes++;
						}else if ([NSColor yellowColor]==tubeColor) {
							numLowGainTubes++;
						}else if ([NSColor brownColor]==tubeColor) {
							numButtTubes++;
						}else if ([NSColor cyanColor]==tubeColor) {
							numNeckTubes++;
						}
						[pmtColorArray replaceObjectAtIndex:tubeIndex withObject:tubeColor];
					}
				}
			}
		} else if (parameterToDisplay == kCmosRatesDisplay){
			[[detectorColorBar colorAxis] setMinValue:0];
			[[detectorColorBar colorAxis] setMaxValue:5000];
			[[detectorColorBar colorAxis] setAxisMinLimit:0];
			[[detectorColorBar colorAxis] setAxisMaxLimit:5000];
			
			for (crate=0;crate<kMaxSNOCrates;crate++){
				for(card=0;card<kNumSNOCards;card++){
					for(pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
						
						
						//NSLog(@"%i %i %i %f\n",crate,card,pmt,cmosrate);
						
						//NSLog(@"colordone %i %i %i\n",tubeColor,[NSColor clearColor],[detectorColorBar getColorForValue:converted]);
						if (crate==0){
							//cmosrate*=100;
							NSColor *tubeColor = [detectorColorBar getColorForValue:[db cmosRate:crate card:card channel:pmt]];
							[pmtColorArray replaceObjectAtIndex:tubeIndex withObject:tubeColor];
						}
					}
				}
			}			
		} else if (parameterToDisplay == kBaseCurrentDisplay){
			[[detectorColorBar colorAxis] setMinValue:0];
			[[detectorColorBar colorAxis] setMaxValue:50];
			[[detectorColorBar colorAxis] setAxisMinLimit:0];
			[[detectorColorBar colorAxis] setAxisMaxLimit:50];

			for (crate=0;crate<kMaxSNOCrates;crate++){
				for(card=0;card<kNumSNOCards;card++){
					for(pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
						if (crate==0){
							NSColor *tubeColor = [detectorColorBar getColorForValue:[db baseCurrent:crate card:card channel:pmt]];
							[pmtColorArray replaceObjectAtIndex:tubeIndex withObject:tubeColor];
						}
					}
				}
			}
		}  else if (parameterToDisplay == kFifoDisplay){
			[[detectorColorBar colorAxis] setMinValue:0];
			[[detectorColorBar colorAxis] setMaxValue:1000000];
			[[detectorColorBar colorAxis] setAxisMinLimit:0];
			[[detectorColorBar colorAxis] setAxisMaxLimit:1000000];

			for (crate=0;crate<kMaxSNOCrates;crate++){
				for(card=0;card<kNumSNOCards;card++){
					fecfifo = [db fifo:crate card:card];
					NSColor *tubeColor = [detectorColorBar getColorForValue:fecfifo];
					for(pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
						if (crate==0){
							[pmtColorArray replaceObjectAtIndex:tubeIndex withObject:tubeColor];
						}
					}
				}
			}
		}  else if (parameterToDisplay == kRatesDisplay){
			[[detectorColorBar colorAxis] setMinValue:0];
			[[detectorColorBar colorAxis] setMaxValue:5];
			[[detectorColorBar colorAxis] setAxisMinLimit:0];
			[[detectorColorBar colorAxis] setAxisMaxLimit:5];

			for (crate=0;crate<kMaxSNOCrates;crate++){
				xl3rate = [db xl3Rate:crate];
				NSColor *tubeColor = [detectorColorBar getColorForValue:xl3rate];
				for(card=0;card<kNumSNOCards;card++){
					for(pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
						if (crate==0){
							[pmtColorArray replaceObjectAtIndex:tubeIndex withObject:tubeColor];
						}
					}
				}
			}
		}
	
	[self formatGlobalStatsString];
	[self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
	return YES;
}

- (void) mouseDown:(NSEvent*)anEvent
{
	selectedCrate = -1;
	selectedCard = -1;
	selectedChannel = -1;	
	
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	NSBezierPath *aPath;
	
	int crate,card,pmt;
	for(crate=0;crate<kMaxSNOCrates;crate++){
		for(card=0;card<kCardsPerCrate;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				
				if (pickPSUPView) {
					aPath = [channelRectsInPSUPView objectAtIndex:tubeIndex];
				}else if (!pickPSUPView) {
					aPath = [channelRectsInCrateView objectAtIndex:tubeIndex];
				}

				if([aPath containsPoint:localPoint]){
					selectedCrate = crate;
					selectedCard = card;
					selectedChannel = pmt;
					break;
				}				
			}
		}
	}
	
	[self setNeedsDisplay:YES];
}

@end