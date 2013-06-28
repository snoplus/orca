//
//  OROpenGLObject.h
//  ORCA
//
//  Created by Laura Wendlandt on 6/28/13.
//  
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

#import <Foundation/Foundation.h>
#import "ORVertex.h"

@interface OROpenGLObject : NSObject
{
    NSMutableArray *vertices;
    NSMutableArray *faces;
    NSMutableArray *faceNormals;
    NSMutableArray *faceColors;
    NSMutableArray *normals;
 
    NSMutableDictionary *colors;
}

- (id) init;
- (void) dealloc;
 
- (BOOL) createObjectFromFile:(NSString*)inputFile; //returns false if not valid files

- (void) parseFacesFirst:(NSString*)first Second:(NSString*)second Third:(NSString*)third currentColor:(NSString*)currentColor;
- (void) normalize:(NSMutableArray*)v;
- (BOOL) importColors:(NSString*)file; //returns false if not valid file

- (void) drawScaleX:(float)sx scaleY:(float)sy scaleZ:(float)sz
        translateX:(float)tx translateY:(float)ty translateZ:(float)tz
        rotateAngle:(float)ra rotateX:(float)rx rotateY:(float)ry rotateZ:(float)rz;

 @end