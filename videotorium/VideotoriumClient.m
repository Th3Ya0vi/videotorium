//
//  Videotorium.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClient.h"
#import "VideotoriumClientDataSourceUsingSynchronousRequest.h"

@implementation VideotoriumClient

@synthesize dataSource = _dataSource;

- (id <VideotoriumClientDataSource>)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [[VideotoriumClientDataSourceUsingSynchronousRequest alloc] init];
    }
    return _dataSource;
}

- (VideotoriumRecording *)recordingWithID:(NSString *)ID
{
    VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
    NSString *urlString = [NSString stringWithFormat:@"http://videotorium.hu/hu/recordings/details/%@", ID];
    recording.response = [self.dataSource contentsOfURL:urlString];
    return recording;
}

@end
