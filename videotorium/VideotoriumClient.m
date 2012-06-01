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

- (NSArray *)substringsOf:(NSString *)string fromMatching:(NSString *)fromPattern toMatching:(NSString *)toPattern
{
    NSMutableArray *results = [NSMutableArray array];
    if (string) {
        NSRegularExpression *fromRegexp = [NSRegularExpression regularExpressionWithPattern:fromPattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSArray *fromMatches = [fromRegexp matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *fromMatch in fromMatches) {
            NSRange fromRange = [fromMatch range];
            NSRegularExpression *toRegexp = [NSRegularExpression regularExpressionWithPattern:toPattern options:NSRegularExpressionCaseInsensitive error:NULL];
            NSTextCheckingResult *toMatch = [toRegexp firstMatchInString:string options:0 range:NSMakeRange(fromRange.location, [string length] - fromRange.location)];
            if (toMatch) {
                NSRange toRange = [toMatch range];
                NSRange range = NSMakeRange(fromRange.location, toRange.location + toRange.length - fromRange.location);
                [results addObject:[string substringWithRange:range]];                
            }
        }        
    }
    return results;
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
    NSString *titleAndPresenter = [[self substringsOf:details.response fromMatching:@"heading recording" toMatching:@"</p>"] lastObject];
    if (titleAndPresenter) {
        titleAndPresenter = [titleAndPresenter stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        details.title = [self substringOf:titleAndPresenter matching:@"<h1>([^<]*)"];
        details.presenter = [[self substringOf:titleAndPresenter matching:@"<p>([^<]*)</p>"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        details.streamURL = [NSURL URLWithString:[self substringOf:details.response matching:@"<video[^>]*src=\"([^\"]*)\""]];        
    }
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
    NSMutableArray *recordings = [NSMutableArray array];
    
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
            [recordings addObject:recording];
        }
    }
    NSArray *indexPictureURLs = [self substringsOf:response matching:@"<span class=\"playpic\"></span><img src=\"([^\"]*)"];
    NSUInteger index;
    index = 0;
    for (NSString *indexPictureURL in indexPictureURLs) {
        VideotoriumRecording* recording = [recordings objectAtIndex:index];
        if (recording) {
            recording.indexPictureURL = [NSURL URLWithString:indexPictureURL];
        }
        index++;
    }
    NSArray *dateStrings = [self substringsOf:response matching:@"Felvétel ideje:</span> <span>([^<]*)"];
    index = 0;
    for (NSString *dateString in dateStrings) {
        VideotoriumRecording* recording = [recordings objectAtIndex:index];
        if (recording) {
            recording.dateString = dateString;
        }
        index++;
    }
    return recordings;
}

@end
