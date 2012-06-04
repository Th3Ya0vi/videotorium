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
        NSRegularExpression *fromRegexp = [NSRegularExpression regularExpressionWithPattern:fromPattern options:NSRegularExpressionAnchorsMatchLines error:NULL];
        NSArray *fromMatches = [fromRegexp matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *fromMatch in fromMatches) {
            NSRange fromRange = [fromMatch range];
            NSRegularExpression *toRegexp = [NSRegularExpression regularExpressionWithPattern:toPattern options:NSRegularExpressionAnchorsMatchLines error:NULL];
            NSTextCheckingResult *toMatch = [toRegexp firstMatchInString:string options:0 range:NSMakeRange(fromRange.location + fromRange.length, [string length] - fromRange.location - fromRange.length)];
            if (toMatch) {
                NSRange toRange = [toMatch range];
                NSRange range = NSMakeRange(fromRange.location, toRange.location + toRange.length - fromRange.location);
                [results addObject:[string substringWithRange:range]];                
            }
        }        
    }
    return results;
}

- (NSString *)substringOf:(NSString *)string fromMatching:(NSString *)fromPattern toMatching:(NSString *)toPattern
{
    NSArray *substrings = [self substringsOf:string fromMatching:fromPattern toMatching:toPattern];
    if ([substrings count] == 0) return nil;
    return [substrings objectAtIndex:0];
}

- (NSArray *)substringsOf:(NSString *)string matching:(NSString *)pattern
{
    NSMutableArray *results = [NSMutableArray array];
    if (string) {
        NSString *oneliner = [[string stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSArray *matches = [regexp matchesInString:oneliner options:0 range:NSMakeRange(0, [oneliner length])];
        for (NSTextCheckingResult *match in matches) {
            NSString *result = [oneliner substringWithRange:[match rangeAtIndex:1]];
            [results addObject:[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }        
    }
    return results;
}

- (NSString *)substringOf:(NSString *)string matching:(NSString *)pattern
{
    NSArray *substrings = [self substringsOf:string matching:pattern];
    if ([substrings count] == 0) return nil;
    return [substrings objectAtIndex:0];
}


- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID
{
    VideotoriumRecordingDetails *details = [[VideotoriumRecordingDetails alloc] init];
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, DETAILS_URL, ID];
    details.URL = [NSURL URLWithString:URLString];
    details.response = [self.dataSource contentsOfURL:URLString];
    if (details.response == nil) return nil;
    NSString *titleAndPresenter = [self substringOf:details.response fromMatching:@"heading recording" toMatching:@"</p>"];
    if (titleAndPresenter) {
        details.title = [self substringOf:titleAndPresenter matching:@"<h1>([^<]*)"];
        details.presenter = [self substringOf:titleAndPresenter matching:@"<p>([^<(]*)"];
    }
    details.dateString = [self substringOf:details.response matching:@"Felvétel ideje: *</h2>([^<]*)"];
    details.durationString = [self substringOf:details.response matching:@"Felvétel hossza: *</h2>([^<]*)"];
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
    NSMutableArray *recordings = [NSMutableArray array];
    
    NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, SEARCH_URL, encodedSearchString];
    NSString *response = [self.dataSource contentsOfURL:URLString];
    
    NSArray *results = [self substringsOf:response fromMatching:@"^  <li[ >]" toMatching:@"^  </li>"];    
    for (NSString *result in results) {
        VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
        recording.title = [self substringOf:result matching:@"<h1><a href=[^>]*>([^<]*)"];
        recording.ID = [self substringOf:result matching:@"<h1><a href=\"hu/recordings/details/([^,]*)"];
        NSString *indexPictureURLString = [self substringOf:result matching:@"<img src=\"([^\"]*)"];
        if (indexPictureURLString) recording.indexPictureURL = [NSURL URLWithString:indexPictureURLString];
        recording.dateString = [self substringOf:result matching:@"Felvétel ideje:</span> <span>([^<]*)"];
        recording.eventName = [self substringOf:result matching:@"recordingevents[^=]*=\"hu/events[^>]*> *([^<]*)"];
        [recordings addObject:recording];
    }
    return recordings;
}

@end
