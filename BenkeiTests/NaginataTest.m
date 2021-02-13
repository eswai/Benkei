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

- (void)testSpace {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2;

    r1 = [n pressKey:kVK_Space];
    r2 = [n releaseKey:kVK_Space];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 1, "b");
    XCTAssertEqual([r2 objectAtIndex:0], [NSNumber numberWithInt:kVK_Space], "b");
}

- (void)testA {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2;

    r1 = [n pressKey:kVK_ANSI_J];
    r2 = [n releaseKey:kVK_ANSI_J];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 1, "b");
    XCTAssertEqual([r2 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testKI {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2;

    r1 = [n pressKey:kVK_ANSI_W];
    r2 = [n releaseKey:kVK_ANSI_W];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_K], "b");
    XCTAssertEqual([r2 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I], "b");
    
}

- (void)testDA {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2, *r3, *r4;
    r1 = [n pressKey:kVK_ANSI_F];
    r2 = [n pressKey:kVK_ANSI_N];
    r3 = [n releaseKey:kVK_ANSI_F];
    r4 = [n releaseKey:kVK_ANSI_N];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_D], "b");
    XCTAssertEqual([r3 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r4 count], 0, "b");
}

- (void)testPA {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2, *r3, *r4;
    r1 = [n pressKey:kVK_ANSI_M];
    r2 = [n pressKey:kVK_ANSI_C];
    r3 = [n releaseKey:kVK_ANSI_C];
    r4 = [n releaseKey:kVK_ANSI_M];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P], "b");
    XCTAssertEqual([r3 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r4 count], 0, "b");
}

- (void)testPA2 {
    Naginata *n = [Naginata new];
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_M];
    r3 = [n pressKey:kVK_ANSI_C];
    r4 = [n releaseKey:kVK_ANSI_C];
    r5 = [n releaseKey:kVK_ANSI_M];
    r6 = [n releaseKey:kVK_Space];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r5 count], 0, "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testAIU {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_ANSI_J];
    r2 = [n pressKey:kVK_ANSI_K];
    r3 = [n pressKey:kVK_ANSI_L];
    r4 = [n releaseKey:kVK_ANSI_J];
    r5 = [n releaseKey:kVK_ANSI_K];
    r6 = [n releaseKey:kVK_ANSI_L];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_I], "b");
    XCTAssertEqual([r6 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_U], "b");
}

- (void)testNOYO {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_J];
    r3 = [n pressKey:kVK_ANSI_I];
    r4 = [n releaseKey:kVK_ANSI_J];
    r5 = [n releaseKey:kVK_ANSI_I];
    r6 = [n releaseKey:kVK_Space];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testNOYO2 {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_J];
    r3 = [n pressKey:kVK_ANSI_I];
    r4 = [n releaseKey:kVK_Space];
    r5 = [n releaseKey:kVK_ANSI_J];
    r6 = [n releaseKey:kVK_ANSI_I];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testNORU {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_J];
    r3 = [n releaseKey:kVK_Space];
    r4 = [n pressKey:kVK_ANSI_I];
    r5 = [n releaseKey:kVK_ANSI_J];
    r6 = [n releaseKey:kVK_ANSI_I];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r3 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r4 count], 0, "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_R], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_U], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testAYO1 {
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
    XCTAssertEqual([r2 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r5 count], 0, "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testNOYO3 {
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
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testGAGA {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_ANSI_J];
    r2 = [n pressKey:kVK_ANSI_F];
    r3 = [n releaseKey:kVK_ANSI_F];
    r4 = [n pressKey:kVK_ANSI_F];
    r5 = [n releaseKey:kVK_ANSI_F];
    r6 = [n releaseKey:kVK_ANSI_J];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_G], "b");
    XCTAssertEqual([r3 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r4 count], 0, "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_G], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testSENU {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_A];
    r3 = [n releaseKey:kVK_ANSI_A];
    r4 = [n pressKey:kVK_ANSI_S];
    r5 = [n releaseKey:kVK_ANSI_S];
    r6 = [n releaseKey:kVK_Space];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S], "b");
    XCTAssertEqual([r3 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E], "b");
    XCTAssertEqual([r4 count], 0, "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([r5 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_U], "b");
    XCTAssertEqual([r6 count], 0, "b");
}

- (void)testSENU2 {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSArray *r1, *r2, *r3, *r4, *r5, *r6;
    r1 = [n pressKey:kVK_Space];
    r2 = [n pressKey:kVK_ANSI_A];
    r3 = [n pressKey:kVK_ANSI_S];
    r4 = [n releaseKey:kVK_ANSI_A];
    r5 = [n releaseKey:kVK_ANSI_S];
    r6 = [n releaseKey:kVK_Space];
    XCTAssertEqual([r1 count], 0, "b");
    XCTAssertEqual([r2 count], 0, "b");
    XCTAssertEqual([r3 count], 0, "b");
    XCTAssertEqual([r4 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S], "b");
    XCTAssertEqual([r4 objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E], "b");
    XCTAssertEqual([r5 objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
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
