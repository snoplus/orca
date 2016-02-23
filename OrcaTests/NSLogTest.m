//
//  NSLogTest.m
//  Orca
//
//  Created by Eric Marzec (marzece@gmail.com) on 2/22/16.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ORStatusController.h"
@interface NSLogTest : XCTestCase {
    ORStatusController *statusCont; //The status controller that is being tested.
    BOOL sharedVar; //Used to represent a variable different threads share
    int TimeOut; //How long to wait for things to get printed to the screen
    uint nPrints; //For functions that print many times (e.g. printSequentially), this specifies exactly how many
    NSString* printSingleLineTestString; //Test string that is used in printSingleLine()
    NSString* printSeqTestString; //(unformatted) Test string that is used in printSequentially()
    
}
- (void)printSingleLine;
- (void)printSequentially;
- (void)printStringToStatusController:(NSString*)str;
- (void)RunMainLoop;
- (void)CheckSequentialPrints;
@end

@implementation NSLogTest

- (void)setUp {
    [super setUp];
    statusCont = [ORStatusController sharedStatusController];
    [statusCont retain];
    TimeOut = 3;
    nPrints = 100;
    printSingleLineTestString = @"Single Line Test string\n";
    printSeqTestString = @"PrintSeq%d\n";
}

- (void)tearDown {
    [statusCont release];
    [super tearDown];
}

- (void)testRetrieveStatusController {
    XCTAssertNotNil(statusCont,@"Could not get status controller");
}

- (void)testBasicPrinting {
    //Prints a string using the status controller then immediatly
    //checks to see if it shows up
    NSString *testString = @"TEST STRING\n";
    [self printStringToStatusController:testString];

    
    NSString* txt =[statusCont contents];
    NSRange range = [txt rangeOfString:testString];
    
    XCTAssert(range.length>0,@"Test string was not printed");
}

- (void)testBasicPrint_wRML{
    //wRML = with Run Main Loop
    //Prints a string to the status controller then lets the main
    //loop run for a while, then checks if the string is there
    NSString *testString = @"TEST STRING with RML\n";
    [self printStringToStatusController:testString];
    
    [self RunMainLoop];
    
    NSString* txt =[statusCont contents];
    NSRange range = [txt rangeOfString:testString];
    XCTAssert(range.length>0,@"Test string was not printed");
}

- (void)testSecondaryThreadPrint {
    //Prints to in a (non-main) thread then checks if the output
    //shows up. The main loop stays in the function the entire time
    time_t TimeOutTimer = time(0);
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    UInt StartingLength = [[statusCont contents] length];
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    [NSThread sleepForTimeInterval:TimeOut]; //Wait a reasonable amount of time
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    NSRange range = [txt rangeOfString:printSingleLineTestString];
    XCTAssert(range.length >0,@"Secondary thread failed to print correctly");
}

- (void)testSecondaryThreadPrint_wRML {
    //wRML = with Run Main Loop
    //Same as testSecondaryThreadPrint except a pause is taken to let the
    //main loop run before any checking is done.
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    UInt StartingLength = [[statusCont contents] length];
    sharedVar = YES;
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    [self RunMainLoop];
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    NSRange range = [txt rangeOfString:printSingleLineTestString];
    XCTAssert(range.length >0,@"Secondary thread failed to print correctly");
}

- (void)testLotsOfPrinting_MainThread {
    //This test will print 10000 statements to the status controller and check
    //to make sure they all get logged properly, in the correct order.
    //All this is done within the main thread
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
    [self CheckSequentialPrints];
}

- (void)testLotsOfPrinting_MainThread_wRML {
    //wRML = with Run Main Loop
    //Same as testLotsOfPrinting_MainThread except a pause is taken to let the
    //main loop run before any checking is done.
    if(![NSThread isMainThread]) {
        XCTFail(@"Main thread test not launched on main thread");
    }
    UInt StartingLength = [[statusCont contents] length];
    [self printSequentially];
    
    [self RunMainLoop];
    
    NSString *txt = [statusCont contents];
    if ([txt length] <= StartingLength)
    {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    [self CheckSequentialPrints];
}

- (void)testLotsOfPrinting_SecondaryThread {
    //Runs a separate thread that outputs lots of times then
    //checks after a reasonable time if that output is show.
    //The main loop never leaves this function
    UInt StartingLength = [[statusCont contents] length];

    [NSThread detachNewThreadSelector:@selector(printSequentially) toTarget:self withObject:nil];
    [NSThread sleepForTimeInterval:TimeOut];     //Wait a reasonable amount of time
    NSString *txt = [statusCont contents];
    XCTAssertGreaterThan([txt length], StartingLength,@"Secondary thread failed to print");
    if([txt length] <= StartingLength) {
        return;
    }
    [self CheckSequentialPrints];
}

- (void)testLotsOfPrinting_SecondaryThread_wRML { //RML = Run Main Loop
    
    UInt StartingLength = [[statusCont contents] length];

    [NSThread detachNewThreadSelector:@selector(printSequentially) toTarget:self withObject:nil];
    
    [self RunMainLoop];    //Wait a reasonable amount of time
    
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        //Note I could just use XCTFail here but I don't b/c that doesn't give any useful debugging output
        XCTAssertGreaterThan([txt length], StartingLength,@"Secondary thread failed to print");
        return;
    }
    //Check that every string showed up and are in the correct order
    [self CheckSequentialPrints];
}

- (void)testDeadlock {
    //This test just detects if a deadlock can occur when launching a secondary thread.
    //It doesn't not bother checking if things actually get outputted correctly.
    //So the actual logging could totally fail and this test would still pass
    //so long as it fails without locking up
    time_t TimeOutTimer = time(0);
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

-(void)testPerformance {
    NSString *testString = @"performance test string\n";
    NSAttributedString *attrString1 = [[NSAttributedString alloc] initWithString:testString];
    [self measureBlock:^{
    for(int i=0;i<1000;i++)
        {
            [statusCont printAttributedString:attrString1];
        }
    }];
    [attrString1 release];
}

//Helper Functions
- (void)printSingleLine {
    //This function is meant to be run on a secondary (non-main) thread.
    //It is supposed to print a test string to the status controller, and then it should return.
    //If printing to the status controller blocks this function will not return until that block is resolved.
    [self printStringToStatusController:printSingleLineTestString];
    sharedVar = NO; //Change this so other threads know this function is done
}
- (void)printSequentially {
    //Prints many line of text which can be checked to make sure they show up in the correct order.
    for (uint i=0; i < nPrints; i++) {
        NSString* testString = [NSString stringWithFormat:printSeqTestString,i];
        [self printStringToStatusController:testString];
        usleep(10000);
        sharedVar = NO; //Change this so other threads know this function is done
    }
}
- (void)printStringToStatusController:(NSString*)str {
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:str];
    [statusCont printAttributedString:attrString];
    [attrString release];
}
- (void)RunMainLoop {
    //This function just lets the main loop run for a few seconds (or whatever TimeOut is set to)
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSinceNow:TimeOut];
    [[NSRunLoop mainRunLoop] runUntilDate:date];
    [date release];
}
- (void) CheckSequentialPrints {
    //This function is used to check that the output for printSequentially actually showed up.
    NSString* txt = [statusCont contents];
    for(uint i=0;i< nPrints-1;i++)
    {
        NSRange range1 = [txt rangeOfString:[NSString stringWithFormat:printSeqTestString,i]];
        NSRange range2 = [txt rangeOfString:[NSString stringWithFormat:printSeqTestString,i+1]];
        XCTAssertLessThan(range1.location,range2.location,@"%d showed up before %d\n",i+1,i);
        XCTAssertNotEqual(range1.length,(UInt)0,@"%d not found\n",i);
        XCTAssertNotEqual(range2.length,(UInt)0,@"%d not found\n",i+1);
    }
}

@end
