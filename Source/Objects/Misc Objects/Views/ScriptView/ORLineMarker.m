
#import "ORLineMarker.h"

#define CORNER_RADIUS	3.0
#define MARKER_HEIGHT	13.0

@implementation ORLineMarker

- (id) initWithRulerView:(NSRulerView *)aRulerView lineNumber:(float)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin
{
	if ((self = [super initWithRulerView:aRulerView markerLocation:0.0 image:anImage imageOrigin:imageOrigin]) != nil) {
		lineNumber = line;
	}
	return self;
}

- (void) setLineNumber:(unsigned)line
{
	lineNumber = line;
}

- (unsigned) lineNumber
{
	return lineNumber;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]) != nil) {
		if ([decoder allowsKeyedCoding]) {
			lineNumber = [[decoder decodeObjectForKey:@"line"] unsignedIntValue];
		}
		else {
			lineNumber = [[decoder decodeObject] unsignedIntValue];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];	
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject:[NSNumber numberWithUnsignedInt:lineNumber] forKey:@"line"];
	}
	else {
		[encoder encodeObject:[NSNumber numberWithUnsignedInt:lineNumber]];
	}
}


#pragma mark NSCopying methods
- (id)copyWithZone:(NSZone *)zone
{	
	id copy = [super copyWithZone:zone];
	[copy setLineNumber:lineNumber];
	return copy;
}


@end
