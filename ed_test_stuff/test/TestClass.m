#import "TestClass.h"

@implementation TestClass

-(void) generateRunDict
{
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    runDocDict[@"type"] = @"tellie_run";
    runDocDict[@"version"] = @"0";
    runDocDict[@"pass"] = @"0";
    runDocDict[@"production"] = [NSNumber numberWithBool:YES];
    runDocDict[@"comment"] = @"";
    self.runDoc = runDocDict;
}

@end