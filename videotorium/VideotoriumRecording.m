//
//  VideotoriumRecording.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.29..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecording.h"

@implementation VideotoriumRecording

@synthesize ID = _ID;
@synthesize title = _title;
@synthesize indexPictureURL = _indexPictureURL;
@synthesize dateString = _dateString;
@synthesize eventName = _eventName;
@synthesize presenter = _presenter;
@synthesize matchingSlides = _matchingSlides;

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumRecording (ID: %@, title: %@, dateString: %@, eventName: %@, presenter: %@, indexPictureURL: %@, resultsOnSlides: %@)", self.ID, self.title, self.dateString, self.eventName, self.presenter, self.indexPictureURL, self.matchingSlides];
}

@end
