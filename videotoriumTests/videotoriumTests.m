//
//  videotoriumTests.m
//  videotoriumTests
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "videotoriumTests.h"
#import "VideotoriumClient.h"

@implementation videotoriumTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testClassExists
{
    VideotoriumClient *videotoriumClient = [[VideotoriumClient alloc] init];
    STAssertTrue([videotoriumClient isKindOfClass:[VideotoriumClient class]], nil);
}

@end
