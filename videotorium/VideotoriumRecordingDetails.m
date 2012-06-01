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
@synthesize URLString = _URLString;
@synthesize streamURL = _streamURL;
@synthesize slides = _slides;
@synthesize title = _title;
@synthesize presenter = _presenter;
@synthesize dateString = _dateString;
@synthesize durationString = _durationString;

-(NSArray *)slides
{
    if (_slides == nil) {
        _slides = [NSArray array];
    }
    return _slides;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumRecordingDetails (title: %@, presenter: %@, dateString: %@, durationString: %@, streamURL: %@, number of slides: %@)", self.title, self.presenter, self.dateString, self.durationString, self.streamURL, [self.slides count]];
}


@end
