//
//  OROpenGLObject.hm
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
//
//.obj specification info: http://paulbourke.net/dataformats/obj/
//.mtl specification info: http://www.fileformat.info/format/material/
//
//Right now, the only commands this parser pays attention to are:
//  geometric vertices (v)
//  vertex normals (vn)
//  faces (f)

#import "OROpenGLObject.h"

@implementation OROpenGLObject

- (id) init
{
    self = [super init];
    
    vertices = [[NSMutableArray alloc] init];
    faces = [[NSMutableArray alloc] init];
    faceNormals = [[NSMutableArray alloc] init];
    faceColors = [[NSMutableArray alloc] init];
    normals = [[NSMutableArray alloc] init];
    
    colors = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) dealloc
{
    [vertices release];
    [faces release];
    [faceNormals release];
    [faceColors release];
    [normals release];
    
    [colors release];
    
    [super dealloc];
}

- (BOOL) createObjectFromFile:(NSString*)inputFile
{
    NSMutableString* inputData = [NSMutableString stringWithContentsOfFile:inputFile encoding:NSASCIIStringEncoding error:nil];
    if(inputData == nil)
        return NO;
    
    //delete comments
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"#([^\n]*)(\n|$)" options:NSRegularExpressionCaseInsensitive error:nil];
    
    [regex replaceMatchesInString:inputData options:0 range:NSMakeRange(0,[inputData length]) withTemplate:@""];

    [inputData replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[inputData length])];
    NSArray* tokens = [inputData componentsSeparatedByString:@" "];
    
    NSMutableString* currentColor = [[NSMutableString alloc] init];
    
    NSEnumerator* enumerator = [tokens objectEnumerator];
    id anObject;
    while(anObject = [enumerator nextObject])
    {
        if([anObject isEqualToString:@"mtllib"])
        {
            if(![self importColors:[enumerator nextObject]])
            {
                [currentColor release];
                return NO;
            }
        }
        else if([anObject isEqualToString:@"usemtl"])
        {
            [currentColor setString:[enumerator nextObject]];
        }
        else if([anObject isEqualToString:@"v"])
        {
            ORVertex* v = [[ORVertex alloc] initWithX:[[enumerator nextObject] floatValue] Y:[[enumerator nextObject] floatValue] Z:[[enumerator nextObject] floatValue]];
            [vertices addObject:v];
            [v release];
        }
        else if([anObject isEqualToString:@"vn"])
        {
            ORVertex* v = [[ORVertex alloc] initWithX:[[enumerator nextObject] floatValue] Y:[[enumerator nextObject] floatValue] Z:[[enumerator nextObject] floatValue]];
            [normals addObject:v];
            [v release];
        }
        else if([anObject isEqualToString:@"f"])
        {
            [self parseFacesFirst:[enumerator nextObject] Second:[enumerator nextObject] Third:[enumerator nextObject] currentColor:currentColor];
        }
    }

    [self normalize:vertices];
    [self normalize:normals];

    for(ORVertex* v in faces)
        [v subtractOne];
    
    for(ORVertex* v in faceNormals)
        [v subtractOne];
    
    [currentColor release];

    return YES;
}

- (void) parseFacesFirst:(NSString*)first Second:(NSString*)second Third:(NSString*)third currentColor:(NSString*)currentColor
{ 
    NSMutableArray *faceNumbers = [[NSMutableArray alloc] init];
    NSMutableArray *faceNormalNumbers = [[NSMutableArray alloc] init];
 
    NSString* current;
    int i;
    for(i=0; i<3; i++)
    {
        switch(i)
        {
            case 0: current = first; break;
            case 1: current = second; break;
            case 2: current = third; break;
        }
        NSArray *components = [current componentsSeparatedByString:@"/"];
 
        NSScanner *scan1 = [[NSScanner alloc] initWithString:[components objectAtIndex:0]];
        int myInt;
        [scan1 scanInt:&myInt];
        [faceNumbers insertObject:[NSNumber numberWithInt:myInt] atIndex:i];
        [scan1 release];
        
        NSScanner *scan2 = [[NSScanner alloc] initWithString:[components objectAtIndex:2]];
        [scan2 scanInt:&myInt];
        [faceNormalNumbers insertObject:[NSNumber numberWithInt:myInt] atIndex:i];
        [scan2 release];
    }
 
    ORVertex* tempFaces = [[ORVertex alloc] initWithX:[[faceNumbers objectAtIndex:0] floatValue] Y:[[faceNumbers objectAtIndex:1] floatValue] Z:[[faceNumbers objectAtIndex:2] floatValue]];
    [faces addObject:tempFaces];
    [tempFaces release];
 
    ORVertex* tempFaceNormals = [[ORVertex alloc] initWithX:[[faceNormalNumbers objectAtIndex:0] floatValue] Y:[[faceNormalNumbers objectAtIndex:1] floatValue] Z:[[faceNormalNumbers objectAtIndex:2] floatValue]];
    [faceNormals addObject:tempFaceNormals];
    [tempFaceNormals release];
    
    [faceNumbers release];
    [faceNormalNumbers release];

    [faceColors addObject:[colors valueForKey:currentColor]];
}
 
- (void) normalize:(NSMutableArray*)v
{
    float largest = [[v objectAtIndex:0] largestAbsolute];
    int i;
    for(i=1; i<[v count]; i++)
    {
        if([[v objectAtIndex:i] largestAbsolute] > largest)
            largest = [[v objectAtIndex:i] largestAbsolute];
    }
 
    for(i=0; i<[v count]; i++)
        [[v objectAtIndex:i] divideAllBy:largest];
}

- (BOOL) importColors:(NSString*)file
{    
    NSRange dot = [file rangeOfString:@"."];
    NSString* fileName = [[NSString alloc] initWithString:[file substringWithRange:NSMakeRange(0, dot.location)]];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* fullPath = [mainBundle pathForResource:fileName ofType: @"mtl"];
    
    NSMutableString* inputData = [NSMutableString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:nil];
    if(inputData == nil)
    {
        [fileName release];
        return NO;
    }
    
    [inputData replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[inputData length])];
    NSArray* tokens = [inputData componentsSeparatedByString:@" "];
    
    NSEnumerator* enumerator = [tokens objectEnumerator];
    id anObject;
    while(anObject = [enumerator nextObject])
    {
        if([anObject isEqualToString:@"newmtl"])
        {
            NSString* name = [enumerator nextObject];
            int i;
            for(i=0; i<5; i++)
                [enumerator nextObject]; //skip to diffuse light numbers
            ORVertex* tempColors = [[ORVertex alloc] initWithX:[[enumerator nextObject] floatValue] Y:[[enumerator nextObject] floatValue] Z:[[enumerator nextObject] floatValue]];
            [colors setObject:tempColors forKey:name];
            [tempColors release];
        }
    }
    
    [fileName release];

    return YES;
}

- (void) drawScaleX:(float)sx scaleY:(float)sy scaleZ:(float)sz
         translateX:(float)tx translateY:(float)ty translateZ:(float)tz
        rotateAngle:(float)ra rotateX:(float)rx rotateY:(float)ry rotateZ:(float)rz
{
    glPushMatrix();
    glRotatef(ra,rx,ry,rz);
    glTranslatef(tx,ty,tz);
    glScalef(sx,sy,sz);
    
    int i;
    for(i=0; i<[faces count]; i++)
    {
        glColor3f([[faceColors objectAtIndex:i] getX], [[faceColors objectAtIndex:i] getY], [[faceColors objectAtIndex:i] getZ]);
        glBegin(GL_POLYGON);
        

        glNormal3f([[normals objectAtIndex:[[faceNormals objectAtIndex:i] getX]] getX], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getX]] getY], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getX]] getZ]);
        glVertex3f([[vertices objectAtIndex:[[faces objectAtIndex:i] getX]] getX], [[vertices objectAtIndex:[[faces objectAtIndex:i] getX]] getY], [[vertices objectAtIndex:[[faces objectAtIndex:i] getX]] getZ]);
        
        glNormal3f([[normals objectAtIndex:[[faceNormals objectAtIndex:i] getY]] getX], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getY]] getY], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getY]] getZ]);
        glVertex3f([[vertices objectAtIndex:[[faces objectAtIndex:i] getY]] getX], [[vertices objectAtIndex:[[faces objectAtIndex:i] getY]] getY], [[vertices objectAtIndex:[[faces objectAtIndex:i] getY]] getZ]);
        
        glNormal3f([[normals objectAtIndex:[[faceNormals objectAtIndex:i] getZ]] getX], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getZ]] getY], [[normals objectAtIndex:[[faceNormals objectAtIndex:i] getZ]] getZ]);
        glVertex3f([[vertices objectAtIndex:[[faces objectAtIndex:i] getZ]] getX], [[vertices objectAtIndex:[[faces objectAtIndex:i] getZ]] getY], [[vertices objectAtIndex:[[faces objectAtIndex:i] getZ]] getZ]);

        glEnd();
    }
    
    glPopMatrix();
}

@end