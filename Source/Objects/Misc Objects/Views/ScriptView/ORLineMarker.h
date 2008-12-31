
#import <Cocoa/Cocoa.h>

@interface ORLineMarker : NSRulerMarker
{
	unsigned		lineNumber;
}

- (id) initWithRulerView:(NSRulerView *)aRulerView lineNumber:(float)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin;
- (void) setLineNumber:(unsigned)line;
- (unsigned) lineNumber;

@end
