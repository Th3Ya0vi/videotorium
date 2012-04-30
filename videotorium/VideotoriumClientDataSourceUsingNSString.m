//
//  VideotoriumClientDataSourceUsingNSString.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumClientDataSourceUsingNSString.h"

@implementation VideotoriumClientDataSourceUsingNSString

- (NSString *)contentsOfURL:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return [NSString stringWithContentsOfURL:url
                                    encoding:NSUTF8StringEncoding
                                       error:nil];
}

@end
