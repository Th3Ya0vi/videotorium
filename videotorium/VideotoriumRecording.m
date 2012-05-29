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


- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"VideotoriumRecording (ID: %@, title: %@, indexPictureURL: %@)", self.ID, self.title, self.indexPictureURL];
}

@end
