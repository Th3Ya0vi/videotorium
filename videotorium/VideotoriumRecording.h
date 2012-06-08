//
//  VideotoriumRecording.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.29..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideotoriumRecording : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *indexPictureURL;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSArray *matchingSlides; // array of VideotoriumSlide objects returned by the search

@end
