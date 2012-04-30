//
//  VideotoriumClientDataSourceUsingNSString.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClientDataSourceUsingSynchronousRequest.h"

@implementation VideotoriumClientDataSourceUsingSynchronousRequest

- (NSString *)contentsOfURL:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"iPad" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:NULL];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
