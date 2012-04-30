//
//  VideotoriumSlide.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumSlide.h"

@implementation VideotoriumSlide

@synthesize URL = _URL;
@synthesize timestamp = _timestamp;

+ (VideotoriumSlide *)slideWithDictionary:(NSDictionary *)slideDictionary URLPrefix:(NSString *)URLPrefix
{
    VideotoriumSlide *slide = [[VideotoriumSlide alloc] init];
    NSString *image = [slideDictionary objectForKey:@"image"];
    slide.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URLPrefix, image]];
    slide.timestamp = [[slideDictionary objectForKey:@"timestamp"] intValue];
    return slide;
}

@end
