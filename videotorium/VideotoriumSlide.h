//
//  VideotoriumSlide.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideotoriumSlide : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic) NSTimeInterval timestamp;

+ (VideotoriumSlide *)slideWithDictionary:(NSDictionary *)slideDictionary URLPrefix:(NSString *)URLPrefix;

@end
