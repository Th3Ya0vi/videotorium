//
//  VideotoriumSlide.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideotoriumSlide : NSObject

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSURL *thumbnailURL;
@property (nonatomic, strong) NSString *ID;
@property (nonatomic) NSTimeInterval timestamp;

+ (VideotoriumSlide *)slideWithDictionary:(NSDictionary *)slideDictionary imageURLPrefix:(NSString *)imageURLPrefix thumbnailURLPrefix:(NSString *)thumbnailURLPrefix;

@end
