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
- (void) draw3D:(NSRect)aRect
{
    
    glRotatef(180, 0.0f, 1.0f, 0.0f);/* orbit the Y axis */
    glRotatef(-50, 1.0f, 0.0f, 0.0f);/* orbit the Y axis */

    glClearColor(0.9f, 0.9f, 0.9f, 0.0f);
    

	glLineWidth(.1);
	glColor3f (.8, .8, .8);
    float h=0;
    float r = .7;
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
@end
