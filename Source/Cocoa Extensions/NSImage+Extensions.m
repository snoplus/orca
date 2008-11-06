/*
	NSImage+Extensions.m
*/
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

@implementation NSImage (OrcaExtensions)
- (NSImage *) rotateIndividualImage: (NSImage *)image angle:(float)anAngle
{
    NSImage *existingImage = image;
    NSSize existingSize;
    existingSize.width = [[existingImage bestRepresentationForDevice: nil] pixelsWide];
    existingSize.height = [[existingImage bestRepresentationForDevice: nil] pixelsHigh];

    NSSize newSize = NSMakeSize(existingSize.height, existingSize.width);
    NSImage *rotatedImage = [[NSImage alloc] initWithSize:newSize];

    [rotatedImage lockFocus];

    NSAffineTransform *rotateTF = [NSAffineTransform transform];
    NSPoint centerPoint = NSMakePoint(newSize.width / 2, newSize.height / 2);

    [rotateTF translateXBy: centerPoint.x yBy: centerPoint.y];
    [rotateTF rotateByDegrees: anAngle];
    [rotateTF translateXBy: -centerPoint.y yBy: -centerPoint.x];
    [rotateTF concat];

    NSRect r1 = NSMakeRect(0, 0, newSize.height, newSize.width);
    [[existingImage bestRepresentationForDevice: nil] drawInRect: r1];

    [rotatedImage unlockFocus];

    return [rotatedImage autorelease];
}

@end
