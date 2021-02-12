//
//  NaginataTest.m
//  NaginataTests
//
//  Created by eswai on 2021/02/07.
//

#import <XCTest/XCTest.h>
#import "Naginata.h"
#import <Carbon/Carbon.h>

@interface NaginataTest : XCTestCase

@end

@implementation NaginataTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testKI {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    Naginata *n = [Naginata new];
    NSArray *r1, *r2;

    r1 = [n pressKey:kVK_ANSI_W];
    r2 = [n releaseKey:kVK_ANSI_W];
    XCTAssertEqual(r1, NULL, "a");
    XCTAssertEqual([NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_K], "a");
    XCTAssertEqual([r2 firstObject], [NSNumber numberWithInt:kVK_ANSI_K], "b");
    XCTAssertEqual([r2 lastObject], [NSNumber numberWithInt:kVK_ANSI_I], "b");
    
}

- (void)testXA {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2, *r3, *r4;    
    r1 = [n pressKey:kVK_ANSI_Q];
    r2 = [n pressKey:kVK_ANSI_J];
    r3 = [n releaseKey:kVK_ANSI_Q];
    r4 = [n releaseKey:kVK_ANSI_J];
    XCTAssertEqual([r3 firstObject], [NSNumber numberWithInt:kVK_ANSI_X], "b");
    XCTAssertEqual([r3 lastObject], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testAYO {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_ANSI_J];
    r2 = [n pressKey:kVK_Space];
    r3 = [n pressKey:kVK_ANSI_I];
    r4 = [n releaseKey:kVK_ANSI_J];
    r5 = [n releaseKey:kVK_Space];
    r6 = [n releaseKey:kVK_ANSI_I];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 count], 1, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r5 count], 2, "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testNORU {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_ANSI_J];
    r2 = [n pressKey:kVK_Space];
    r3 = [n pressKey:kVK_ANSI_I];
    r4 = [n releaseKey:kVK_ANSI_J];
    r5 = [n releaseKey:kVK_Space];
    r6 = [n releaseKey:kVK_ANSI_I];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 count], 2, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r5 count], 2, "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_R], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_U], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
