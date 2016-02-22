//
//  NSLogTest.m
//  Orca
//
//  Created by snotdaq on 2/22/16.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ORStatusController.h"

@interface NSLogTest : XCTestCase {
    ORStatusController *statusCont;
    BOOL finishLoop; //Used for deciding when "non-returning" function should return
    BOOL sharedVar; //Used to represent a variable different threads share
    int TimeOut; //How long to wait for a timeout
    uint nPrints; //For functions that print many times, this specifies exactly how many
}
- (void)printSingleLine;
- (void)printSequentially;
@end

@implementation NSLogTest

- (void)setUp {
    [super setUp];
    statusCont = [ORStatusController sharedStatusController];
    XCTAssertNotNil(statusCont,@"Could not get status controller");
    [statusCont retain];
    finishLoop = NO;
    TimeOut = 3;
    nPrints = 100;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}
- (void)tearDown {
    finishLoop = YES;
    [statusCont release];
    [super tearDown];
}
- (void)testBasicPrinting {
    NSString *testString = @"TEST STRING\n";
    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:testString];
    [statusCont printAttributedString:attrString];
    
    NSString* txt =[statusCont contents];
    NSRange range = [txt rangeOfString:testString];
    
    XCTAssert(range.length>0,@"Test string was not printed");
    [attrString release];

}
- (void)testPrintOrder {
    NSString *testString1 = @"First Print Statement\n";
    NSString *testString2 = @"Second Print Statement\n";

    NSAttributedString *attrString1 = [[NSAttributedString alloc]initWithString:testString1];
    NSAttributedString *attrString2 = [[NSAttributedString alloc]initWithString:testString2];

    [statusCont printAttributedString:attrString1];
    [statusCont printAttributedString:attrString2];

    NSString* txt =[statusCont contents];
    NSRange range1 = [txt rangeOfString:testString1];
    NSRange range2 = [txt rangeOfString:testString2];
    
    XCTAssert(range1.length>0,@"Test string1 was not printed");
    XCTAssert(range2.length>0,@"Test string1 was not printed");
    XCTAssertLessThan(range1.location, range2.location,"@Test string 1 did not appear before test string 2");
}
- (void)testSecondaryThreadPrint {
    time_t TimeOutTimer = time(0);
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    UInt StartingLength = [[statusCont contents] length];
    sharedVar = YES;
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    while(1) { //Wait a resonable amount of time
        if(time(0) - TimeOutTimer > TimeOut)
        {
            break;
        }
        else
        {
            usleep(10000); //Sleep for 0.1 seconds
        }
    }
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    NSRange range = [txt rangeOfString:@"printAndReturn test string\n"];
    XCTAssert(range.length >0,@"Secondary thread failed to print correctly");
}
- (void)testLotsOfPrinting_MainThread {
    //This test will print 10000 statements to the status controller and check
    //to make sure they all get logged properly, in the correct order.
    //All this is doesn't within the main thread
    if(![NSThread isMainThread]) {
        XCTFail(@"Main thread test not launched on main thread");
    }
    UInt StartingLength = [[statusCont contents] length];
    [self printSequentially];
    NSString *txt = [statusCont contents];
    if ([txt length] <= StartingLength)
    {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    for(uint i=0;i< nPrints-1;i++)
    {
        NSRange range1 = [txt rangeOfString:[NSString stringWithFormat:@"PrintSeq%d\n",i]];
        NSRange range2 = [txt rangeOfString:[NSString stringWithFormat:@"PrintSeq%d\n",i+1]];
        XCTAssertLessThan(range1.location,range2.location,@"%d showed up before %d\n",i+1,i);
        XCTAssertNotEqual(range1.length,(UInt)0,@"%d not found\n",i);
        XCTAssertNotEqual(range2.length,(UInt)0,@"%d not found\n",i+1);
    }
}
- (void)testLotsOfPrinting_SecondaryThread {
    time_t TimeOutTimer = time(0);
    [NSThread detachNewThreadSelector:@selector(printSequentially) toTarget:self withObject:nil];
    //Wait a reasonable amount of time
    sharedVar = YES;
    UInt StartingLength = [[statusCont contents] length];
    NSLog(@"LENGTH IS %d",StartingLength);
    while(1) { // Wait a reasonable amount of time
        if(time(0) - TimeOutTimer > TimeOut)
        {
            break;
        }
        else
        {
            usleep(10000); //Sleep for 0.1 seconds
        }
    }
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSinceNow:TimeOut];
    [[NSRunLoop mainRunLoop] runUntilDate:date];
    NSString *txt = [statusCont contents];
    XCTAssertGreaterThan([txt length], StartingLength,@"Secondary thread failed to print");
    if([txt length] <= StartingLength) {
        return;
    }
    for(uint i=0;i< nPrints-1;i++)
    {
        NSRange range1 = [txt rangeOfString:[NSString stringWithFormat:@"PrintSeq%d\n",i]];
        NSRange range2 = [txt rangeOfString:[NSString stringWithFormat:@"PrintSeq%d\n",i+1]];
        XCTAssertLessThan(range1.location,range2.location,@"%d showed up before %d\n",i+1,i);
        XCTAssertNotEqual(range1.length,(UInt)0,@"%d not found\n",i);
        XCTAssertNotEqual(range2.length,(UInt)0,@"%d not found\n",i+1);
    }
}
- (void)testDeadlock {
    //This test just detects if a deadlock can occur when launching a secondary thread.
    //It doesn't not bother checking if things actually get outputted correctly.
    //So the actual logging could totally fail and this test would still pass.
    time_t TimeOutTimer = time(0);
    UInt StartingLength = [[statusCont contents] length];
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    sharedVar = YES;
    while(sharedVar) {
        if(time(0) - TimeOutTimer > TimeOut)
        {
            break;
        }
        else
        {
            usleep(10000); //Sleep for 0.1 seconds
        }
    }
    XCTAssert(!sharedVar,"Deadlock occurred"); //If sharedVar is not false it's b/c a timeout/deadlock occurred

    
}

//Helper Functions
- (void)printSingleLine {
    //This function is meant to be run on a secondary (non-main) thread.
    //It is supposed to print a test string to the status controller, and then it should return.
    //If printing to the status controller blocks this function will not return until that block is resolved.
    NSString *testString = @"printAndReturn test string\n";
    NSAttributedString *attrString1 = [[NSAttributedString alloc] initWithString:testString];
    
    [statusCont printAttributedString:attrString1];
    
    [attrString1 release];
    sharedVar = NO; //Change this so other threads know this function is done
}
- (void)printSequentially {
    for (uint i=0; i < nPrints; i++) {
        NSAttributedString *testString = [[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"PrintSeq%d\n",i]];
        [statusCont printAttributedString:testString];
        usleep(10000);
        [testString release];
        sharedVar = NO; //Change this so other threads know this function is done
    }
}

@end
