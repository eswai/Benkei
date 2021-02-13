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
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_Space], "b");
}

- (void)testA {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testKI {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_W]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_W]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_K], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I], "b");
}

- (void)testDA {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_N]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_N]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_D], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testPA {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testPA2 {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testAIU {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_U], "b");
}

- (void)testNOYO {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O], "b");
}

- (void)testNOYO2 {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O], "b");
}

- (void)testNORU {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_R], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U], "b");
}

- (void)testAYO1 {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_O], "b");
}

- (void)testNOYO3 {
    Naginata *n = [Naginata new];
    n.kouchiShift = true;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O], "b");
}

- (void)testGAGA {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_G], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_G], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_A], "b");
}

- (void)testSENU {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U], "b");
}

- (void)testSENU2 {
    Naginata *n = [Naginata new];
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S], "b");
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E], "b");
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_N], "b");
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U], "b");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
