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
    NSURL *expectedURL = [NSURL URLWithString:@"http://stream.videotorium.hu/vtorium/_definst_/mp4:487/2487/2487_2483_mobile.mp4/playlist.m3u8?sessionid=i2kmtu98s810o3b1itn5p6u0b3_2487"];
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
    STAssertEqualObjects(recording.indexPictureURL, [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/487/2487/indexpics/400x250/2487_2483_20.jpg"], nil);
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
    STAssertEquals([recording31.matchingSlides count], (NSUInteger)1, nil);
    VideotoriumSlide *slide = [recording31.matchingSlides lastObject];
    NSURL *expectedThumbnailURL = [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/31/31/slides/150x150/297.jpg"];
    STAssertEqualObjects(slide.thumbnailURL, expectedThumbnailURL, nil);
    STAssertEqualObjects(slide.ID, @"297", nil);
}

- (void)testFeauturedRecordings
{
    NSArray *results = [self.videotoriumClient featuredRecordings];
    STAssertEquals([results count], (NSUInteger)100, nil);
    
    VideotoriumRecording *recording = [results objectAtIndex:0];
    STAssertEqualObjects(recording.ID, @"4313", nil);
    STAssertEqualObjects(recording.title, @"NIIF videokonferencia", nil);
    STAssertEqualObjects(recording.indexPictureURL, [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/313/4313/indexpics/192x144/4313_4167_19.jpg"], nil);
    STAssertEqualObjects(recording.dateString, @"2012. május 16.", nil);
    STAssertEqualObjects(recording.presenter, @"Kovács András, ...", nil);
    
    recording = [results objectAtIndex:1];
    STAssertEqualObjects(recording.ID, @"3234", nil);
    STAssertEqualObjects(recording.title, @"A bibliai idők emberének növényei", nil);
    STAssertEqualObjects(recording.indexPictureURL, [NSURL URLWithString:@"http://static.videotorium.hu/files/recordings/234/3234/indexpics/192x144/3234_3145_8.jpg"], nil);
    STAssertEqualObjects(recording.dateString, @"2011. május  4.", nil);
    STAssertEqualObjects(recording.presenter, @"Dr. Juhász Miklós", nil);

}

@end
