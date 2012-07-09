//
//  VideotoriumClientMockDataSource.m
//  tests
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClientMockDataSource.h"

@implementation VideotoriumClientMockDataSource

- (NSString *)contentsOfURL:(NSString *)urlString error:(NSError *__autoreleasing *)error
{
    NSString *plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"VideotoriumClientMockDataSourceResponses" ofType:@"plist"];
    NSDictionary *responses = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    return [responses objectForKey:urlString];
}

@end
