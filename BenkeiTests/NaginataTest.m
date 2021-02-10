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

- (void)testType {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    Naginata *n = [Naginata new];
    NSArray *r1 = [n pressKey:kVK_ANSI_W];
    NSArray *r2 = [n releaseKey:kVK_ANSI_W];
    XCTAssertEqual(r1, NULL, "a");
    XCTAssertEqual([NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_K], "a");
    XCTAssertEqual([r2 firstObject], [NSNumber numberWithInt:kVK_ANSI_K], "b");
    XCTAssertEqual([r2 lastObject], [NSNumber numberWithInt:kVK_ANSI_I], "b");
    
    NSArray *r3 = [n pressKey:kVK_ANSI_Q];
    NSArray *r4 = [n pressKey:kVK_ANSI_W];
    NSArray *r5 = [n releaseKey:kVK_ANSI_Q];
    NSArray *r6 = [n releaseKey:kVK_ANSI_W];
    XCTAssertEqual([r5 firstObject], [NSNumber numberWithInt:kVK_ANSI_X], "b");
    XCTAssertEqual([r5 lastObject], [NSNumber numberWithInt:kVK_ANSI_I], "b");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
