//
//  OR3DScanPlatformModel.m
//  Orca
//
//  Created by Mark Howe on Tue June 4,2013.
//  Copyright ¬© 2013 University of North Carolina. All rights reserved.
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


#import "OR3DScanPlatformView.h"

@implementation OR3DScanPlatformView
-(void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}
- (void) awakeFromNib
{
    [super awakeFromNib];
    [self performSelector:@selector(incRot) withObject:nil afterDelay:.1];
}
- ( void) incRot
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    rot += .5;
    [self performSelector:@selector(incRot) withObject:nil afterDelay:.01];
    [self setNeedsDisplay:YES];
}

- (void) draw3D:(NSRect)aRect
{
    
    glRotatef(180, 0.0f, 1.0f, 0.0f);/* orbit the Y axis */
    glRotatef(-50, 1.0f, 0.0f, 0.0f);/* orbit the X axis */

    glClearColor(0.93f, 0.93f, 0.93f, 0.0f);
    

	glLineWidth(.1);
	glColor3f (.8, .8, .8);
    float h=0;
    float r = 1.;
    glBegin (GL_LINES);
    int i;
    float x1,y1,x2,y2;
    for(i=0;i<360;i++){
        if(i==0){
            x1 = r*cos(i*3.1415/180.);
            y2 = r*sin(i*3.1415/180.);
        }
        else {
            x2 = r*cos(i*3.1415/180.);
            y2 = r*sin(i*3.1415/180.);
            glVertex3f(x1, y1, h);
            glVertex3f(x2, y2, h);
            x1=x2;
            y1=y2;
        }

    }

    glEnd();
        
    glRotatef(rot, 0.0f, 0.0f, 1.0f);/* orbit the X axis */
    glTranslatef(1.0f,0.0f,0.0f);
    r *= .3;
    
    glBegin (GL_LINES);
    
    glVertex3f(-r, -r, h);
    glVertex3f(-r, r, h);
    
    glVertex3f(-r, r, h);
    glVertex3f(r, r, h);
    
    glVertex3f(r, r, h);
    glVertex3f(r, -r, h);
    
    glVertex3f(r, -r, h);
    glVertex3f(-r, -r, h);

    glEnd();

    
    
}
@end
