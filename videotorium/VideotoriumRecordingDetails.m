//
//  VideotoriumRecording.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.27..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecordingDetails.h"

@implementation VideotoriumRecordingDetails

@synthesize response = _response;
@synthesize streamURL = _streamURL;
@synthesize slides = _slides;


-(NSArray *)slides
{
    if (_slides == nil) {
        _slides = [NSArray array];
    }
    return _slides;
}

@end
