#import "TestClass.h"

int main(int argc, const char* argv[]){
    TestClass* new = [[TestClass alloc] init];
    NSMutableDictionary* initial = new.runDoc;
    for(NSString* field in initial){
        NSLog(@"Field : %@", field);
    }

    [new generateRunDict];
    for(NSString* field in initial){
        NSLog(@"Field : %@", field);
    }
    return 0;
}