
//
//  OR3DScanPlatformController.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "OR3DScanPlatformController.h"
#import "OR3DScanPlatformModel.h"
#import "ORBasicOpenGLView.h"
static long randomNumber( long minValue, long maxValue)
{
	return (rand() % ((maxValue +1) - minValue)) + minValue;
}
static void seedRandom()
{
	time_t t;
	time(&t);
	srand(t);
	
}

static void drawPixel (GLfloat r1,GLfloat r2, float startAngle, float deltaAngle, GLfloat z,
					   float endRed, float endGreen, float endBlue)
{
#define kNumPoints 20
	float startRed = endRed/5.;
	float startGreen = endGreen/5.;
	float startBlue = endBlue/5.;
	GLfloat xInner[kNumPoints];
	GLfloat yInner[kNumPoints];
	GLfloat xOuter[kNumPoints];
	GLfloat yOuter[kNumPoints];
    r1 = r1+.001;
    r2 = r2-.001;
    startAngle += .1;
    deltaAngle -= .2;
	float endAngle = startAngle + deltaAngle;
	float delta = (endAngle-startAngle)/(float)(kNumPoints-1);
	int i;
	for(i=0;i<kNumPoints;i++){
		xInner[i] = r1*cos((startAngle+(delta*i))*3.14159/180.);
		yInner[i] = r1*sin((startAngle+(delta*i))*3.14159/180.);
	}
    
	delta = (endAngle-startAngle)/(float)(kNumPoints-1);
	for(i=0;i<kNumPoints;i++){
		xOuter[i] = r2*cos((startAngle+(delta*i))*3.14159/180.);
		yOuter[i] = r2*sin((startAngle+(delta*i))*3.14159/180.);
	}
    
	//draw the top
	glBegin (GL_TRIANGLE_STRIP);
	glColor3f (endRed, endGreen, endBlue);
	for(i=0;i<kNumPoints;i++){
		glVertex3f(xInner[i], yInner[i], z);
		glVertex3f(xOuter[i], yOuter[i], z);
	}
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z);
	glEnd();
    
	//draw the bottom
	glBegin (GL_TRIANGLE_STRIP);
	glColor3f (endRed, endGreen, endBlue);
	for(i=kNumPoints-1;i>=0;i--){
		glVertex3f(xInner[i], yInner[i], 0);
		glVertex3f(xOuter[i], yOuter[i], 0);
	}
	glEnd();
    
	
	//draw the start angle side
	glBegin(GL_QUADS);
	glColor3f (endRed, endGreen, endBlue);
	glVertex3f(xOuter[0], yOuter[0], z); //top
	glVertex3f(xInner[0], yInner[0], z); //top
	glColor3f (startRed, startGreen, startBlue);
	glVertex3f(xInner[0], yInner[0], 0); //bott
	glVertex3f(xOuter[0], yOuter[0], 0); //bott
	glEnd();
	
	//draw the end angle side
	glBegin(GL_QUADS);
	glColor3f (endRed, endGreen, endBlue);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z); //top
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z); //top
	glColor3f (startRed, startGreen, startBlue);
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0); //bott
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0); //bott
	glEnd();
    
	//inside surface
	glBegin (GL_QUAD_STRIP);
	for(i=0;i<kNumPoints;i++){
		glColor3f (startRed, startGreen, startBlue);
		glVertex3f(xInner[i], yInner[i], 0);
		glColor3f (endRed, endGreen, endBlue);
		glVertex3f(xInner[i], yInner[i], z);
	}
	glEnd();
	
	//outside surface
	glBegin (GL_QUAD_STRIP);
	for(i=0;i<kNumPoints;i++){
		glColor3f (endRed, endGreen, endBlue);
		glVertex3f(xOuter[i], yOuter[i], z);
		glColor3f (startRed, startGreen, startBlue);
		glVertex3f(xOuter[i], yOuter[i], 0);
	}
	glEnd();
	
	//lines
	glLineWidth(1.0);
	glEnable (GL_LINE_SMOOTH);
	//glEnable (GL_LINE_STIPPLE);
	//top
	glColor3f (0.0, 0.0, 0.0);
	glBegin (GL_LINES);
	glVertex3f(xInner[0], yInner[0], z);
	glVertex3f(xOuter[0], yOuter[0], z);
	for(i=0;i<kNumPoints-1;i++){
		glVertex3f(xOuter[i], yOuter[i], z);
		glVertex3f(xOuter[i+1], yOuter[i+1], z);
	}
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z);
	for(i=kNumPoints-1;i>0;i--){
		glVertex3f(xInner[i], yInner[i], z);
		glVertex3f(xInner[i-1], yInner[i-1], z);
	}
	glEnd();
	
	glBegin (GL_LINES);
	glVertex3f(xInner[0], yInner[0], 0);
	glVertex3f(xOuter[0], yOuter[0], 0);
	for(i=0;i<kNumPoints-1;i++){
		glVertex3f(xOuter[i], yOuter[i], 0);
		glVertex3f(xOuter[i+1], yOuter[i+1], 0);
	}
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0);
	for(i=kNumPoints-1;i>0;i--){
		glVertex3f(xInner[i], yInner[i], 0);
		glVertex3f(xInner[i-1], yInner[i-1], 0);
	}
	glEnd();
	
	//draw the start angle side
	glBegin(GL_LINES);
	glVertex3f(xOuter[0], yOuter[0], z); //top
	glVertex3f(xOuter[0], yOuter[0], 0); //bott
	glVertex3f(xInner[0], yInner[0], z); //top
	glVertex3f(xInner[0], yInner[0], 0); //bott
	glEnd();
	
	//draw the start angle side
	glBegin(GL_LINES);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z); //top
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0); //bott
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z); //top
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0); //bott
	glEnd();
	
}

@implementation OR3DScanPlatformController
- (id) init
{
    self = [super initWithWindowNibName:@"3DScanPlatform"];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	seedRandom();
    int i;
    for(i=0;i<148;i++)height[i] = randomNumber(0,3)/10.;
	[subComponentsView setGroup:model];
	[super awakeFromNib];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : OR3DScanPlatformLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
	
}

- (void) updateWindow
{
    [super updateWindow];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:OR3DScanPlatformLock];
    [lockButton setState: locked];
	
	//[view updateButtons];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OR3DScanPlatformLock to:secure];
    [lockButton setEnabled:secure];
}
#define kNumRings				 13
#define kNumSegmentsPerRing		 12
#define kStaggeredSegments		YES

-(void)draw3D:(NSRect)aRect;
{
    glClearColor(0.9f, 0.9f, 0.9f, 0.0f);

    //=========the Focal Plane Part=============
	float r = .3;	//radius of the center focalPlaneSegment NOTE: sets the scale of the whole thing
	float pi = 3.14159;
	float area = 2*pi*r*r;		//area of the center focalPlaneSegment
	area /= 4.;
    
	
	float startAngle;
	float deltaAngle;
	int j;
	r = 0;
    int seg = 0;
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
			else startAngle = 0;
		}
		deltaAngle = 360./(float)numSeqPerRings;
		//calculate the next radius, where the area of each 1/12 of the ring is equal to the center area.
		float r2 = sqrtf(numSeqPerRings*area/(pi*2) + r*r);
		float z = .05;
		for(i=0;i<numSeqPerRings;i++){
            float rc = .5;
            if(height[seg]<=.05)rc=.2;
			drawPixel(r, r2,startAngle,deltaAngle,z+height[seg],
                      .5+height[seg]/3.,0.2,0.2);
            seg++;
			
			startAngle += deltaAngle;
		}
		
		r = r2;
	}
	r += .2;
	glLineWidth(.1);
	glEnable (GL_LINE_SMOOTH);
	glEnable (GL_LINE_STIPPLE);
	glColor3f (.8, .8, .8);
    float h=0;
    glBegin (GL_LINES);
    
    glVertex3f(-r, -r, h);
    glVertex3f(-r, r, h);
    
    glVertex3f(-r, r, h);
    glVertex3f(r, r, h);
    
    glVertex3f(r, r, h);
    glVertex3f(r, -r, h);
    
    glVertex3f(r, -r, h);
    glVertex3f(-r, -r, h);
    
    
    glVertex3f(-r, 0, h);
    glVertex3f(r, 0, h);
    
    glVertex3f(0, -r, h);
    glVertex3f(0, r, h);
    
    glEnd();
    

}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:OR3DScanPlatformLock to:[sender intValue] forWindow:[self window]];
}

@end
