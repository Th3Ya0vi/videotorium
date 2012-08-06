//
//  VideotoriumSlide.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumSlide.h"

@implementation VideotoriumSlide

+ (VideotoriumSlide *)slideWithDictionary:(NSDictionary *)slideDictionary imageURLPrefix:(NSString *)imageURLPrefix thumbnailURLPrefix:(NSString *)thumbnailURLPrefix
{
    VideotoriumSlide *slide = [[VideotoriumSlide alloc] init];
    NSString *image = [slideDictionary objectForKey:@"image"];
    NSString *thumbnail = [slideDictionary objectForKey:@"thumbnail"];
    NSString *ID = [slideDictionary objectForKey:@"id"];
    slide.ID = ID;
    slide.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", imageURLPrefix, image]];
    slide.thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", thumbnailURLPrefix, thumbnail]];
    slide.timestamp = [[slideDictionary objectForKey:@"timestamp"] floatValue];
    return slide;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumSlide (ID: %@, timestamp: %.2f, imageURL: %@, thumbnailURL: %@)", self.ID, self.timestamp, self.imageURL, self.thumbnailURL];
}

@end
