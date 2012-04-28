//
//  videotoriumTests.m
//  videotoriumTests
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "videotoriumTests.h"
#import "VideotoriumClient.h"
#import "VideotoriumRecording.h"

@interface videotoriumTests ()

@property (nonatomic, strong) VideotoriumClient *videotoriumClient;

@end

@implementation videotoriumTests

@synthesize videotoriumClient = _videotoriumClient;

- (void)setUp
{
    [super setUp];

    self.videotoriumClient = [[VideotoriumClient alloc] init];
}

- (void)tearDown
{    
    [super tearDown];
}

- (void)testClassExists
{
    STAssertTrue([self.videotoriumClient isKindOfClass:[VideotoriumClient class]], nil);
}

- (void)testGetRecordingDetails
{
    VideotoriumRecording *recording = [self.videotoriumClient recordingWithID:@"2487"];
    STAssertTrue([recording isKindOfClass:[VideotoriumRecording class]], nil);
//    NSLog(@"%@", recording.response);
    STAssertNotNil(recording.response, nil);
}

@end
