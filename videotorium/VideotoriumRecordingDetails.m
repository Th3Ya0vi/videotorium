//
//  VideotoriumRecording.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.27..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecordingDetails.h"

@implementation VideotoriumRecordingDetails

-(NSArray *)slides
{
    if (_slides == nil) {
        _slides = [NSArray array];
    }
    return _slides;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumRecordingDetails (title: %@, presenter: %@, dateString: %@, durationString: %@, streamURL: %@, number of slides: %d, descriptionText: %@)", self.title, self.presenter, self.dateString, self.durationString, self.streamURL, [self.slides count], self.descriptionText];
}


@end
