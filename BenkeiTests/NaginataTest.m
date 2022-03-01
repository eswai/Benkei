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
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_Space]);
}

- (void)testNumber {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_1]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_1]];
    // pass through number
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_1]);
}

- (void)testA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testNO1 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k count], 2);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testNO2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k count], 2);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testKI {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_W]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_W]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_K]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I]);
}

- (void)testDA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_N]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_N]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_D]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testPA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testXWA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Q]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Q]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];

    XCTAssertEqual([k count], 3);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_X]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_W]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testPYA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_H]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_X]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_H]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_X]];

    XCTAssertEqual([k count], 3);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_Y]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testQ {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Q]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Q]];
    
    XCTAssertEqual([k count], 0);
}

- (void)testAS {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k count], 2);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_Space]);
}

- (void)testPA2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

//    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_C]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];
//    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_P]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testAIU {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_U]);
}

- (void)testNOYO {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k count], 4);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testNOYO2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k count], 4);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testNORU {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k count], 4);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_R]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U]);
}

- (void)testAYO1 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k count], 3);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_Y]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testNOYO3 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0.05;
    n.kouchiShift = true;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_I]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_I]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_Y]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_O]);
}

- (void)testGAGA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_F]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_G]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_G]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testRenzokuEnter {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_V]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_Return]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_Return]);
}

- (void)testRenzokuEnter2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_M]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_V]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_V]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_V]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_V]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_M]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_Return]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_Return]);
}

- (void)testSENU {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U]);
}

- (void)testSENU2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_Space]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_A]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_S]];
    [k addObjectsFromArray:[n releaseKey:kVK_Space]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_S]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_E]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_N]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_U]);
}

- (void)testMUIA1 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Semicolon]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Semicolon]];

    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_U]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_Minus]);
}

- (void)testMUIA2 {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Semicolon]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Semicolon]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];

    XCTAssertEqual([k count], 4);
    XCTAssertEqual([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqual([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_I]);
    XCTAssertEqual([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_U]);
    XCTAssertEqual([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_Minus]);
}

- (void)testXAXA {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Q]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Q]];

    XCTAssertEqual([k count], 4);
    XCTAssertEqualObjects([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_X]);
    XCTAssertEqualObjects([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqualObjects([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_X]);
    XCTAssertEqualObjects([k objectAtIndex:3], [NSNumber numberWithInt:kVK_ANSI_A]);
}

- (void)testTAI {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_N]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_N]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];

    XCTAssertEqual([k count], 3);
    XCTAssertEqualObjects([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_T]);
    XCTAssertEqualObjects([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_A]);
    XCTAssertEqualObjects([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_I]);
}

- (void)testHOU {
    Naginata *n = [Naginata new];
    n.doujiTime = 0;
    n.kouchiShift = false;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_Z]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_Z]];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_L]];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_L]];

    XCTAssertEqual([k count], 3);
    XCTAssertEqualObjects([k objectAtIndex:0], [NSNumber numberWithInt:kVK_ANSI_H]);
    XCTAssertEqualObjects([k objectAtIndex:1], [NSNumber numberWithInt:kVK_ANSI_O]);
    XCTAssertEqualObjects([k objectAtIndex:2], [NSNumber numberWithInt:kVK_ANSI_U]);
}


- (void)testQuesExc {
    Naginata *n = [Naginata new];
    n.doujiTime = 0.04;
    n.kouchiShift = true;
    NSMutableArray *k = [NSMutableArray new];

    [k addObjectsFromArray:[n pressKey:kVK_ANSI_J]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_K]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_D]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_D]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n pressKey:kVK_ANSI_C]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_C]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_J]];
    [NSThread sleepForTimeInterval:0.2f];
    [k addObjectsFromArray:[n releaseKey:kVK_ANSI_K]];

    XCTAssertEqual([k count], 2);
    XCTAssertEqualObjects([k objectAtIndex:0], @"？");
    XCTAssertEqualObjects([k objectAtIndex:1], @"！");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
