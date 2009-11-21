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

#import "KatrinDetectorView.h"
#import "ORColorScale.h"
#import "KatrinConstants.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
@interface KatrinDetectorView (private)
- (void) makeAllSegments;
- (void) makeVetoSegments;
@end

@implementation KatrinDetectorView

- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}

- (void) drawRect:(NSRect)rect
{
	if(viewType == kUseCrateView){
		float x;
		float y;
		float dx = [self bounds].size.width/21.;
		float dy = [self bounds].size.height/22.;
		[[NSColor blackColor] set];
		[NSBezierPath fillRect:[self bounds]];
		[[NSColor whiteColor] set];
		NSBezierPath* thePath = [NSBezierPath bezierPath];
		for(x=0;x<[self bounds].size.width;x+=dx){
			[thePath moveToPoint:NSMakePoint(x,0)];
			[thePath lineToPoint:NSMakePoint(x,[self bounds].size.height)];
		}
		for(y=0;y<=[self bounds].size.height;y+=dy){
			[thePath moveToPoint:NSMakePoint(0,y)];
			[thePath lineToPoint:NSMakePoint([self bounds].size.width,y)];
		}
		[thePath moveToPoint:NSMakePoint([self bounds].size.width,0)];
		[thePath lineToPoint:NSMakePoint([self bounds].size.width,[self bounds].size.height)];
		[thePath stroke];
	}
	else if(viewType == kUsePreampView){
		float xc = [self bounds].size.width/2;
		float yc = [self bounds].size.height/2;
		NSBezierPath* aPath = [NSBezierPath bezierPath];
		NSPoint centerPoint = NSMakePoint(xc,yc);
		float r = MIN(xc,yc)-5;
		[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r startAngle:360 endAngle:0 clockwise:YES];
		[aPath closePath];
				
		[[NSColor blackColor] set];
		[aPath stroke];
	}
	[super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(int)aValue
{
	if(setIndex==0)return [focalPlaneColorScale getColorForValue:aValue];
	else return [vetoColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumFocalPlaneSegments;
	else				 selectedPath %= kNumVetoSegments;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumFocalPlaneSegments-1;
	}
	else {
		if(selectedPath < 0) selectedPath = kNumVetoSegments-1;
	}
}

- (void) leftArrow
{
	if(selectedSet == 0){

		int d;
		if(selectedPath>=0 && selectedPath<4)d = 4;
		else if(selectedPath>=4 && selectedPath<12)d = 8;
		else d= 12;

		selectedPath-=d;
		if(selectedPath == -4) selectedPath = kNumFocalPlaneSegments-1;
		else if(selectedPath < 0) selectedPath = 0;
	}
	else {
		selectedPath--;
		if(selectedPath < 0) selectedPath = kNumVetoSegments-1;
	}
}

- (void) rightArrow
{
	if(selectedSet == 0) {
		int d;
		if(selectedPath>=0 && selectedPath<4)d = 4;
		else if(selectedPath>=4 && selectedPath<12)d = 8;
		else d= 12;
		selectedPath+=d;
		if(selectedPath > kNumFocalPlaneSegments-1) selectedPath = 0;
	}
	else {
		selectedPath++;
		selectedPath %= kNumVetoSegments;
	}
}
@end
@implementation KatrinDetectorView (private)
- (void) makeAllSegments
{
	float pi = 3.1415927;
	float xc = [self bounds].size.width/2;
	float yc = [self bounds].size.height/2;
	float r = MIN(xc,yc)*.14;	//radius of the center focalPlaneSegment NOTE: sets the scale of the whole thing
	float area = 2*pi*r*r;		//area of the center focalPlaneSegment
	
	[super makeAllSegments];
	
	NSPoint centerPoint = NSMakePoint(xc,yc);

	if(viewType == kUseCrateView){
		float dx = [self bounds].size.width/21.;
		float dy = [self bounds].size.height/22.;
		int set;
		int numSets = [delegate numberOfSegmentGroups];
		for(set=0;set<numSets;set++){
			NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
			NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
			ORSegmentGroup* aGroup = [delegate segmentGroup:set];
			int i;
			int n = [aGroup numSegments];
			for(i=0;i<n;i++){
				ORDetectorSegment* aSegment = [aGroup segment:i];
				int cardSlot = [aSegment cardSlot];
				int channel = [aSegment channel];
				if(channel <0){
					cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
				}
				NSRect channelRect = NSMakeRect(cardSlot*dx,channel*dy,dx,dy);
				[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
				[errorPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
			}
			
			[segmentPathSet addObject:segmentPaths];
			[errorPathSet addObject:errorPaths];
		}
	}
	else if(viewType == kUsePreampView){	
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		
		//do the four inner channels
		int i;
		
		for(i=0;i<4;i++){
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy: xc yBy: yc];
			[transform rotateByDegrees:i*360/4. + 2*360/24.];
			NSRect segRect = NSMakeRect(5,-3,15,6);
			NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
			[segPath transformUsingAffineTransform: transform];
			[segmentPaths addObject:segPath];
			[errorPaths addObject:segPath];
		}
		int j;
		for(j=0;j<6;j++){
			float angle = 0;
			float deltaAngle = 360/12.;
			for(i=0;i<24;i++){
				NSAffineTransform *transform = [NSAffineTransform transform];
				[transform translateXBy: xc yBy: yc];
				[transform rotateByDegrees:angle];
				NSRect segRect = NSMakeRect(20+j*18,-3,18,6);
				NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
				[segPath transformUsingAffineTransform: transform];
				[segmentPaths addObject:segPath];
				[errorPaths addObject:segPath];
				angle += deltaAngle;
				if(i==11)angle = deltaAngle/2.;
			}
		}
		

		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		[self makeVetoSegments];
	}	
	else if(viewType == kUsePixelView) {
		//=========the Focal Plane Part=============
		area /= 4.;
		
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		
		float startAngle;
		float deltaAngle;
		int j;
		r = 0;
		for(j=0;j<kNumRings;j++){
			
			int i;
			int numSeqPerRings;
			if(j==0){
				numSeqPerRings = 4;
				startAngle = 0.;
			}
			else {
				numSeqPerRings = kNumSegmentsPerRing;
				if(kStaggeredSegments){
					if(!(j%2))startAngle = 0;
					else startAngle = -360./(float)numSeqPerRings/2.;	
				}
				else {
					startAngle = 0;
				}
			}
			deltaAngle = 360./(float)numSeqPerRings;
			
			float errorAngle1 = deltaAngle/5.;
			float errorAngle2 = 2*errorAngle1;
			
			//calculate the next radius, where the area of each 1/12 of the ring is equal to the center area.
			float r2 = sqrtf(numSeqPerRings*area/(pi*2) + r*r);
			float midR1 = (r2+r)/2. - 2.;
			float midR2 = midR1 + 4.;
			
			for(i=0;i<numSeqPerRings;i++){
				NSBezierPath* aPath = [NSBezierPath bezierPath];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:NO];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r2 startAngle:startAngle+deltaAngle endAngle:startAngle clockwise:YES];
				[aPath closePath];
				[segmentPaths addObject:aPath];
				
				float midAngleStart = (startAngle + startAngle + deltaAngle)/2. - errorAngle1;
				float midAngleEnd   = midAngleStart + errorAngle2;
				
				aPath = [NSBezierPath bezierPath];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR1 startAngle:midAngleStart endAngle:midAngleEnd clockwise:NO];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR2 startAngle:midAngleEnd endAngle:midAngleStart clockwise:YES];
				[aPath closePath];
				[errorPaths addObject:aPath];
				
				startAngle += deltaAngle;
			}
			r = r2;
		}
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		
		[self makeVetoSegments];
		
		[self setNeedsDisplay:YES];
	}
}

- (void) makeVetoSegments
{
	//========the Veto part==========
	float xc = [self bounds].size.width/2;
	float yc = [self bounds].size.height/2;
	NSPoint centerPoint = NSMakePoint(xc,yc);
	NSMutableArray* segment1Paths = [NSMutableArray arrayWithCapacity:64];
	NSMutableArray* error1Paths = [NSMutableArray arrayWithCapacity:64];
	float startAngle	= 0;
	float r1	= MIN(xc,yc)-15;
	float r2	= MIN(xc,yc)-5;
	float midR1 = (r2+r1)/2. - 2;
	float midR2 = midR1 + 4;
	float deltaAngle  = 360./(float)kNumVetoSegments;
	float errorAngle1 = deltaAngle/5.;
	float errorAngle2 = 2*errorAngle1;
	int i;
	for(i=0;i<kNumVetoSegments;i++){
		NSBezierPath* aPath = [NSBezierPath bezierPath];
		[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r1 startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:NO];
		[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r2 startAngle:startAngle+deltaAngle endAngle:startAngle clockwise:YES];
		[aPath closePath];
		[segment1Paths addObject:aPath];
		
		float midAngleStart = (startAngle+startAngle+deltaAngle)/2 - errorAngle1;
		float midAngleEnd   = midAngleStart + errorAngle2;
		
		aPath = [NSBezierPath bezierPath];
		[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR1 startAngle:midAngleStart endAngle:midAngleEnd clockwise:NO];
		[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR2 startAngle:midAngleEnd endAngle:midAngleStart clockwise:YES];
		[aPath closePath];
		[error1Paths addObject:aPath];
		
		startAngle += deltaAngle;
	}
	//store into the whole set
	[segmentPathSet addObject:segment1Paths];
	[errorPathSet addObject:error1Paths];
}


@end
