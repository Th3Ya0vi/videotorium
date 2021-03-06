//
//  VideotoriumRecording.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.27..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideotoriumRecordingDetails : NSObject

@property (nonatomic, strong) NSString *response;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *streamURL;
@property (nonatomic, strong) NSURL *secondaryStreamURL;
@property (nonatomic, strong) NSArray *slides; // array of VideotoriumSlide objects
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *presenter;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *durationString;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSURL *indexPictureURL;
@property (nonatomic, strong) UIImage *indexPicture;
@end
