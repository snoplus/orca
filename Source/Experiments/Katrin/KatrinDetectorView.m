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

@implementation KatrinDetectorView

- (void) makeAllSegments
{
	[super makeAllSegments];
	
	float pi = 3.1415927;
	float xc = [self bounds].size.width/2;
	float yc = [self bounds].size.height/2;
	NSPoint centerPoint = NSMakePoint(xc,yc);
	
	
	//=========the Focal Plane Part=============
	float r = MIN(xc,yc)*.14;	//radius of the center focalPlaneSegment NOTE: sets the scale of the whole thing
	float area = 2*pi*r*r;		//area of the center focalPlaneSegment
	
	area /= 4.;

	NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:145];
	NSMutableArray* errorPaths = [NSMutableArray arrayWithCapacity:145];

	//segment path
	//NSBezierPath* aPath = [NSBezierPath bezierPath];
	//[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r startAngle:0 endAngle:360];
	//[segmentPaths addObject:aPath];

	//error path
	//aPath = [NSBezierPath bezierPath];
	//[aPath appendBezierPathWithArcWithCenter:centerPoint radius:3 startAngle:0 endAngle:360];
	//[errorPaths addObject:aPath];
	
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
		//else if(j==1){
		//	numSeqPerRings = 12;
		//	startAngle = 360./(float)numSeqPerRings;
		//}
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

	
	//========the Veto part==========
	NSMutableArray* segment1Paths = [NSMutableArray arrayWithCapacity:64];
	NSMutableArray* error1Paths = [NSMutableArray arrayWithCapacity:64];
	startAngle	= 0;
	float r1	= r+MIN(xc,yc)*.03;
	float r2	= MIN(xc,yc)-5;
	float midR1 = (r2+r1)/2. - 2;
	float midR2 = midR1 + 4;
	deltaAngle  = 360./(float)kNumVetoSegments;
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