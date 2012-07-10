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
#import "NSString+HTML.h"

@implementation VideotoriumClient

@synthesize dataSource = _dataSource;
@synthesize videotoriumBaseURL = _videotoriumBaseURL;

#define DETAILS_URL @"recordings/details/"
#define SEARCH_URL @"search/all?perpage=100&q="
#define FEATURED_URL @"featured?perpage=100"

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

+ (NSArray *)substringsOf:(NSString *)string fromMatching:(NSString *)fromPattern toMatching:(NSString *)toPattern
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

+ (NSString *)substringOf:(NSString *)string fromMatching:(NSString *)fromPattern toMatching:(NSString *)toPattern
{
    NSArray *substrings = [self substringsOf:string fromMatching:fromPattern toMatching:toPattern];
    if ([substrings count] == 0) return nil;
    return [substrings objectAtIndex:0];
}

+ (NSArray *)substringsOf:(NSString *)string matching:(NSString *)pattern
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

+ (NSString *)substringOf:(NSString *)string matching:(NSString *)pattern
{
    NSArray *substrings = [self substringsOf:string matching:pattern];
    if ([substrings count] == 0) return nil;
    return [substrings objectAtIndex:0];
}


- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID error:(NSError *__autoreleasing *)error
{
    VideotoriumRecordingDetails *details = [[VideotoriumRecordingDetails alloc] init];
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, DETAILS_URL, ID];
    details.URL = [NSURL URLWithString:URLString];
    details.response = [self.dataSource contentsOfURL:URLString error:error];
    if (details.response == nil) return nil;
    NSString *titleAndPresenter = [VideotoriumClient substringOf:details.response fromMatching:@"heading recording" toMatching:@"</p>"];
    if (titleAndPresenter) {
        details.title = [[VideotoriumClient substringOf:titleAndPresenter matching:@"<h1>([^<]*)"] stringByConvertingHTMLToPlainText];
        details.presenter = [[VideotoriumClient substringOf:titleAndPresenter matching:@"<p>([^<(]*)"] stringByConvertingHTMLToPlainText];
    }
    details.dateString = [VideotoriumClient substringOf:details.response matching:@"Felvétel ideje: *</h2>([^<]*)"];
    details.durationString = [VideotoriumClient substringOf:details.response matching:@"Felvétel hossza: *</h2>([^<]*)"];
    NSString *streamURLString = [VideotoriumClient substringOf:details.response matching:@"<video[^>]*src=\"([^\"]*)\""];
    if ([streamURLString rangeOfString:@"stream.videotorium.hu:1935/"].location != NSNotFound) {
        streamURLString = [streamURLString stringByReplacingOccurrencesOfString:@"stream.videotorium.hu:1935/" withString:@"stream.videotorium.hu/"];
    }
    details.streamURL = [NSURL URLWithString:streamURLString];

    NSString *secondaryStreamsString = [VideotoriumClient substringOf:details.response matching:@"media_secondaryStreams *= *'([^']*)'"];
    if (secondaryStreamsString) {
        NSData *secondaryStreamsData = [secondaryStreamsString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *secondaryStreams = [NSJSONSerialization JSONObjectWithData:secondaryStreamsData options:0 error:NULL];
        NSString *secondaryStream = [secondaryStreams lastObject];
        if (secondaryStream) {
            NSString *stringToReplace = [VideotoriumClient substringOf:streamURLString matching:@"(mp4:[^.]*\\.mp4)"];
            NSString *secondaryStreamURLString = [streamURLString stringByReplacingOccurrencesOfString:stringToReplace withString:secondaryStream];
            details.secondaryStreamURL = [NSURL URLWithString:secondaryStreamURLString];
        }        
    }
    NSMutableArray *slides = [NSMutableArray array];
    NSString *slidesImageURLPrefix = [VideotoriumClient substringOf:details.response matching:@"slides_imageFolder *= *'([^']*)'"];
    NSString *slidesThumbnailURLPrefix = [VideotoriumClient substringOf:details.response matching:@"slides_thumbnailFolder *= *'([^']*)'"];
    NSString *slidesJSONString = [VideotoriumClient substringOf:details.response matching:@"slides_model *= *'([^']*)'"];
    if (slidesJSONString != nil) {
        NSData *slidesJSONData = [slidesJSONString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *slidesJSONArray = [NSJSONSerialization JSONObjectWithData:slidesJSONData options:0 error:NULL];
        for (NSDictionary *slideDictionary in slidesJSONArray) {
            VideotoriumSlide *slide = [VideotoriumSlide slideWithDictionary:slideDictionary imageURLPrefix:slidesImageURLPrefix thumbnailURLPrefix:slidesThumbnailURLPrefix];
            [slides addObject:slide];
        }
        details.slides = slides;        
    }
    NSString *description = [VideotoriumClient substringOf:details.response fromMatching:@"<div class=\"recordingdescription\">" toMatching:@"</div>"];
    details.descriptionText = [description stringByConvertingHTMLToPlainText];
    return details;
}

- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID
{
    return [self detailsWithID:ID error:NULL];
}

- (NSArray *)recordingsMatchingString:(NSString *)searchString error:(NSError *__autoreleasing *)error
{
    NSMutableArray *recordings = [NSMutableArray array];
    
    NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self.videotoriumBaseURL, SEARCH_URL, encodedSearchString];
    NSString *response = [self.dataSource contentsOfURL:URLString error:error];
    
    NSArray *results = [VideotoriumClient substringsOf:response fromMatching:@"^  <li[ >]" toMatching:@"^  </li>"];
    for (NSString *result in results) {
        VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
        recording.title = [[VideotoriumClient substringOf:result matching:@"<h1><a href=[^>]*>([^<]*)"] stringByConvertingHTMLToPlainText];
        recording.ID = [VideotoriumClient substringOf:result matching:@"<h1><a href=\"hu/recordings/details/([^,]*)"];
        NSString *indexPictureURLString = [VideotoriumClient substringOf:result matching:@"<img src=\"([^\"]*)"];
        if (indexPictureURLString) recording.indexPictureURL = [NSURL URLWithString:indexPictureURLString];
        recording.dateString = [VideotoriumClient substringOf:result matching:@"Felvétel ideje:</span> <span>([^<]*)"];
        recording.eventName = [VideotoriumClient substringOf:result matching:@"recordingevents[^=]*=\"hu/events[^>]*> *([^<]*)"];
        NSMutableArray *matchingSlides = [NSMutableArray array];
        NSArray *slideDivs = [VideotoriumClient substringsOf:result fromMatching:@"<div class=\"slide\">" toMatching:@"</div>"];
        for (NSString *slideDiv in slideDivs) {
            VideotoriumSlide *slide = [[VideotoriumSlide alloc] init];
            slide.ID = [VideotoriumClient substringOf:slideDiv matching:@"src=\"[^\"]*/([^/\"]*)\\.[^/\"]*\""];
            slide.thumbnailURL = [NSURL URLWithString:[VideotoriumClient substringOf:slideDiv matching:@"src=\"([^\"]*)\""]];
            [matchingSlides addObject:slide];
        }
        recording.matchingSlides = matchingSlides;
        [recordings addObject:recording];
    }
    return recordings;
}

- (NSArray *)recordingsMatchingString:(NSString *)searchString
{
    return [self recordingsMatchingString:searchString error:NULL];
}

- (NSArray *)featuredRecordingsWithError:(NSError *__autoreleasing *)error
{
    NSMutableArray *recordings = [NSMutableArray array];
    
    NSString *URLString = [NSString stringWithFormat:@"%@%@", self.videotoriumBaseURL, FEATURED_URL];
    NSString *response = [self.dataSource contentsOfURL:URLString error:error];
    
    NSArray *results = [VideotoriumClient substringsOf:response fromMatching:@"^      <li>$" toMatching:@"^  </li>"];
    for (NSString *result in results) {
        VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
        recording.title = [[VideotoriumClient substringOf:result matching:@"<h1><a href=[^>]*>([^<]*)"] stringByConvertingHTMLToPlainText];
        recording.ID = [VideotoriumClient substringOf:result matching:@"<h1><a href=\"hu/recordings/details/([^,]*)"];
        NSString *indexPictureURLString = [VideotoriumClient substringOf:result matching:@"<img src=\"([^\"]*)"];
        if (indexPictureURLString) recording.indexPictureURL = [NSURL URLWithString:indexPictureURLString];
        recording.dateString = [VideotoriumClient substringOf:result matching:@"Felvétel ideje:</span> <span>([^<]*)"];
        recording.presenter = [VideotoriumClient substringOf:result matching:@"recordingpresenters[^<]*<li> *([^<]*)"];
        if ([[recording.presenter substringFromIndex:(recording.presenter.length - 1)] isEqualToString:@","]) {
            recording.presenter = [recording.presenter stringByAppendingString:@" ..."];
        }
        [recordings addObject:recording];
    }
    return recordings;
}

- (NSArray *)featuredRecordings
{
    return [self featuredRecordingsWithError:NULL];
}

+ (NSString *)IDOfRecordingWithURL:(NSURL *)URL
{
    return [VideotoriumClient substringOf:URL.absoluteString matching:@"hu/recordings/details/([^,]*)"];
}

@end
