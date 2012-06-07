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
#import "VideotoriumRecordingDetails.h"
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
    VideotoriumRecordingDetails *recording = [self.videotoriumClient detailsWithID:@"2487"];
    NSURL *expectedURL = [NSURL URLWithString:@"http://stream.videotorium.hu:1935/vtorium/_definst_/mp4:487/2487/2487_2483_mobile.mp4/playlist.m3u8?sessionid=i2kmtu98s810o3b1itn5p6u0b3_2487"];
    STAssertEqualObjects(expectedURL, recording.streamURL, nil);
}

- (void)testGetArrayOfSlides
{
    VideotoriumRecordingDetails *recording = [self.videotoriumClient detailsWithID:@"2487"];
    NSArray *slides = recording.slides;
    STAssertEquals([slides count], (NSUInteger)19, nil);
    VideotoriumSlide *slide = [slides objectAtIndex:0];
    STAssertEquals(slide.timestamp, (NSTimeInterval)1, nil);
    NSURL *expectedImageURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/slides/51687.jpg"];
    NSURL *expectedThumbnailURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/slides/400x400/51687.jpg"];
    STAssertEqualObjects(slide.imageURL, expectedImageURL, nil);
    STAssertEqualObjects(slide.thumbnailURL, expectedThumbnailURL, nil);
}

- (void)testGetRecordingMetadata
{
    VideotoriumRecordingDetails *recording = [self.videotoriumClient detailsWithID:@"2487"];
    STAssertEqualObjects(recording.title, @"Módszerek, amelyek megváltoztatják a világot - A számítógépes szimuláció és optimalizáció jelentősége", nil);
    STAssertEqualObjects(recording.presenter, @"Dr. Horváth Zoltán", nil);
    STAssertEqualObjects(recording.dateString, @"2010. november 10.", nil);
    STAssertEqualObjects(recording.durationString, @"59p 46mp", nil);
    STAssertEqualObjects(recording.URL, [NSURL URLWithString:@"http://videotorium.hu/hu/recordings/details/2487"], nil);
    STAssertEquals([recording.descriptionText length], (NSUInteger)693, nil);
}

- (void)testCreatingSlide
{
    NSString *JSONString = @"{\"timestamp\":\"1\",\"id\":\"51687\",\"isChapter\":0,\"thumbnail\":\"51687.jpg\",\"image\":\"51687.jpg\",\"captions\":{\"english\":\"\",\"original\":\"\"}}";
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *slideDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:NULL];
    NSString *imageURLPrefix = @"http://static.videotorium.hu/files/recordings/487/2487/slides/";
    NSString *thumbnailURLPrefix = @"http://static.videotorium.hu/files/recordings/487/2487/slides/400x400/";
    VideotoriumSlide *slide = [VideotoriumSlide slideWithDictionary:slideDictionary imageURLPrefix:imageURLPrefix thumbnailURLPrefix:thumbnailURLPrefix];
    NSURL *expectedImageURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/slides/51687.jpg"];
    NSURL *expectedThumbnailURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/slides/400x400/51687.jpg"];
    STAssertEqualObjects(slide.imageURL, expectedImageURL, nil);
    STAssertEqualObjects(slide.thumbnailURL, expectedThumbnailURL, nil);
    STAssertEqualObjects(slide.ID, @"51687", nil);
    STAssertEquals(slide.timestamp, (NSTimeInterval)1, nil);
}

- (void)testSearchResults
{
    NSArray *results = [self.videotoriumClient recordingsMatchingString:@"cucc"];
    STAssertEquals([results count], (NSUInteger)10, nil);
    VideotoriumRecording *recording31;
    for (VideotoriumRecording *recording in results) {
        if ([recording.ID isEqual:@"31"]) {
            recording31 = recording;
        }
    }
    STAssertNotNil(recording31, @"No recording with ID 31 found among the results");
    STAssertEqualObjects(recording31.title, @"Alapvető szimmetriák kísérleti ellenőrzése a CERN-ben", nil);
    STAssertEqualObjects(recording31.indexPictureURL, [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/31/31/indexpics/192x144/31_31_13.jpg"], nil);
    STAssertEqualObjects(recording31.dateString, @"2004. szeptember 22.", nil);
    STAssertEqualObjects(recording31.eventName, @"A CERN és a magyar részecskefizikusok", nil);
    STAssertEqualObjects(recording31.resultsOnSlides, [NSArray arrayWithObject:@"297"], nil);
}

@end
