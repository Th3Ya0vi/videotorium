//
//  VideotoriumRecording.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.27..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideotoriumRecording : NSObject

@property (nonatomic, strong) NSString *response;
@property (nonatomic, strong) NSURL *streamURL;
@property (nonatomic, strong) NSArray *slides; // array of VideotoriumSlide objects

@end
