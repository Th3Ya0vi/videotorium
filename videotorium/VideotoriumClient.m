//
//  Videotorium.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClient.h"
#import "VideotoriumClientDataSourceUsingSynchronousRequest.h"
#import "VideotoriumRecording.h"

@implementation VideotoriumClient

@synthesize dataSource = _dataSource;
@synthesize videotoriumBaseURL = _videotoriumBaseURL;

#define DETAILS_URL @"recordings/details/"
#define SEARCH_URL @"search/all?perpage=100&q="

- (NSString *)videotoriumBaseURL
{
    if (_videotoriumBaseURL == nil) {
        _videotoriumBaseURL = @"http://videotorium.hu/hu/";
    }
    return _videotoriumBaseURL;
}

- (id <VideotoriumClientDataSource>)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [[VideotoriumClientDataSourceUsingSynchronousRequest alloc] init];
    }
    return _dataSource;
}

- (NSArray *)substringsOf:(NSString *)string matching:(NSString *)pattern
{
    NSMutableArray *results = [NSMutableArray array];
    if (string) {
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSArray *matches = [regexp matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *match in matches) {
            [results addObject:[string substringWithRange:[match rangeAtIndex:1]]];
        }        
    }
    return results;
}

- (NSString *)substringOf:(NSString *)string matching:(NSString *)pattern
{
    return [[self substringsOf:string matching:pattern] lastObject];
}


- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID
{
    VideotoriumRecordingDetails *details = [[VideotoriumRecordingDetails alloc] init];
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, DETAILS_URL, ID];
    details.response = [self.dataSource contentsOfURL:URLString];
    if (details.response == nil) return nil;
    details.streamURL = [NSURL URLWithString:[self substringOf:details.response matching:@"<video[^>]*src=\"([^\"]*)\""]];
    
    NSMutableArray *slides = [NSMutableArray array];
    NSString *slidesURLPrefix = [self substringOf:details.response matching:@"slides_imageFolder *= *'([^']*)'"];
    NSString *slidesJSONString = [self substringOf:details.response matching:@"slides_model *= *'([^']*)'"];
    if (slidesJSONString != nil) {
        NSData *slidesJSONData = [slidesJSONString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *slidesJSONArray = [NSJSONSerialization JSONObjectWithData:slidesJSONData options:0 error:NULL];
        for (NSDictionary *slideDictionary in slidesJSONArray) {
            VideotoriumSlide *slide = [VideotoriumSlide slideWithDictionary:slideDictionary URLPrefix:slidesURLPrefix];
            [slides addObject:slide];
        }
        details.slides = slides;        
    }
    return details;
}

- (NSArray *)recordingsMatchingString:(NSString *)searchString
{
    NSMutableDictionary *recordings = [NSMutableDictionary dictionary];
    
    NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, SEARCH_URL, encodedSearchString];
    NSString *response = [self.dataSource contentsOfURL:URLString];
    
    NSArray *titlesAndURLs = [self substringsOf:response matching:@"<h1><a href=\"([^<]*)"];
    for (NSString *titleAndURL in titlesAndURLs) {
        NSString *title = [self substringOf:titleAndURL matching:@">(.*)$"];
        NSString *ID = [self substringOf:titleAndURL matching:@"hu/recordings/details/([^,]*),"];
        if (ID && title) {
            VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
            recording.title = title;
            recording.ID = ID;
            [recordings setObject:recording forKey:ID];
        }
    }
    NSArray *picturesAndURLs = [self substringsOf:response matching:@"<a href=\"([^\"]*\"><span class=\"playpic\"></span><img src=\"[^\"]*)"];
    for (NSString *pictureAndURL in picturesAndURLs) {
        NSString *picture = [self substringOf:pictureAndURL matching:@"src=\"(.*)$"];
        NSString *ID = [self substringOf:pictureAndURL matching:@"hu/recordings/details/([^,]*),"];
        VideotoriumRecording* recording = [recordings objectForKey:ID];
        if (recording) {
            recording.indexPictureURL = [NSURL URLWithString:picture];
        }
    }
    return [recordings allValues];
}

@end
