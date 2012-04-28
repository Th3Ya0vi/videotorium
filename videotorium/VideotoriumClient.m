//
//  Videotorium.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideotoriumClient.h"

@implementation VideotoriumClient

- (VideotoriumRecording *)recordingWithID:(NSString *)ID
{
    VideotoriumRecording *recording = [[VideotoriumRecording alloc] init];
    NSString *urlString = [NSString stringWithFormat:@"http://videotorium.hu/hu/recordings/details/%@", ID];
    NSURL *url = [NSURL URLWithString:urlString];
    recording.response = [NSString stringWithContentsOfURL:url
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    return recording;
}

@end
