//
//  VideotoriumRecording.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.29..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecording.h"

@implementation VideotoriumRecording

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumRecording (ID: %@, title: %@, dateString: %@, eventName: %@, presenter: %@, indexPictureURL: %@, matchingSlides: %@)", self.ID, self.title, self.dateString, self.eventName, self.presenter, self.indexPictureURL, self.matchingSlides];
}

@end
