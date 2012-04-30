//
//  VideotoriumTests.m
//  tests
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumTests.h"
#import "VideotoriumClient.h"
#import "VideotoriumClientMockDataSource.h"
#import "VideotoriumRecording.h"
#import "VideotoriumSlide.h"

@interface VideotoriumTests ()

@property (nonatomic, strong) VideotoriumClient *videotoriumClient;

@end

@implementation VideotoriumTests

@synthesize videotoriumClient = _videotoriumClient;

- (void)setUp
{
    [super setUp];

    self.videotoriumClient = [[VideotoriumClient alloc] init];
    self.videotoriumClient.dataSource = [[VideotoriumClientMockDataSource alloc] init];
}

- (void)tearDown
{    
    [super tearDown];
}

- (void)testGetRecordingStreamURL
{
    VideotoriumRecording *recording = [self.videotoriumClient recordingWithID:@"2487"];
    NSURL *expectedURL = [NSURL URLWithString:@"http://stream.videotorium.hu:1935/vtorium/_definst_/mp4:487/2487/2487_2483_mobile.mp4/playlist.m3u8?sessionid=i2kmtu98s810o3b1itn5p6u0b3_2487"];
    STAssertEqualObjects(expectedURL, recording.streamURL, nil);
}

- (void)testGetArrayOfSlides
{
    VideotoriumRecording *recording = [self.videotoriumClient recordingWithID:@"2487"];
    NSArray *slides = recording.slides;
    STAssertEquals([slides count], (NSUInteger)19, nil);
}

- (void)testCreatingSlide
{
    NSString *JSONString = @"{\"timestamp\":\"1\",\"id\":\"51687\",\"isChapter\":0,\"thumbnail\":\"51687.jpg\",\"image\":\"51687.jpg\",\"captions\":{\"english\":\"\",\"original\":\"\"}}";
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *slideDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:NULL];
    NSString *URLPrefix = @"http://static.videotorium.hu/files/recordings/487/2487/slides/";
    VideotoriumSlide *slide = [VideotoriumSlide slideWithDictionary:slideDictionary URLPrefix:URLPrefix];
    NSURL *expectedURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/slides/51687.jpg"];
    STAssertEqualObjects(slide.URL, expectedURL, nil);
    STAssertEquals(slide.timestamp, (NSTimeInterval)1, nil);
}

@end
