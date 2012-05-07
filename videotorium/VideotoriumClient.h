//
//  Videotorium.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.26..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideotoriumRecordingDetails.h"
#import "VideotoriumSlide.h"

@protocol VideotoriumClientDataSource <NSObject>

- (NSString *)contentsOfURL:(NSString *)urlString;

@end


@interface VideotoriumClient : NSObject

@property (nonatomic, strong) id <VideotoriumClientDataSource> dataSource;

- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID;

@end
