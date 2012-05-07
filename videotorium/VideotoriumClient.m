//
//  Videotorium.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClient.h"
#import "VideotoriumClientDataSourceUsingSynchronousRequest.h"

@implementation VideotoriumClient

@synthesize dataSource = _dataSource;

//#define VIDEOTORIUM_BASE_URL @"http://localhost/"
#define VIDEOTORIUM_BASE_URL @"http://videotorium.hu/hu/recordings/details/"

- (id <VideotoriumClientDataSource>)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [[VideotoriumClientDataSourceUsingSynchronousRequest alloc] init];
    }
    return _dataSource;
}

- (NSString *)substringOf:(NSString *)string matching:(NSString *)pattern
{
    if (string == nil) return nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *match = [regexp firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (match) {
        return [string  substringWithRange:[match rangeAtIndex:1]];
    } else {
        return nil;
    }
}

- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID
{
    VideotoriumRecordingDetails *details = [[VideotoriumRecordingDetails alloc] init];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", VIDEOTORIUM_BASE_URL, ID];
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

@end
