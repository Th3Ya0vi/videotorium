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
    NSString *response = [self.dataSource contentsOfURL:urlString];
    NSRange responseRange = NSMakeRange(0, [response length]);
    recording.response = response;
    NSRegularExpression *streamURLRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"<video[^>]*src=\"([^\"]*)\""
                                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                                  error:NULL];
    NSTextCheckingResult *match = [streamURLRegularExpression firstMatchInString:response options:0 range:responseRange];
    if (match) recording.streamURL = [NSURL URLWithString:[response substringWithRange:[match rangeAtIndex:1]]];
    return recording;
}

@end
