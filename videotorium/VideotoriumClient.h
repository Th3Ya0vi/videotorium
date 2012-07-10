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

- (NSString *)contentsOfURL:(NSString *)urlString error:(NSError **)error;

@end


@interface VideotoriumClient : NSObject

@property (nonatomic, strong) id <VideotoriumClientDataSource> dataSource;
@property (nonatomic, strong) NSString *videotoriumBaseURL;

- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID;
- (VideotoriumRecordingDetails *)detailsWithID:(NSString *)ID error:(NSError**)error;
- (NSArray *)recordingsMatchingString:(NSString *)searchString; // returns an array of VideotoriumRecording objects
- (NSArray *)recordingsMatchingString:(NSString *)searchString error:(NSError**)error; // returns an array of VideotoriumRecording objects
- (NSArray *)featuredRecordings; // returns an array of VideotoriumRecording objects
- (NSArray *)featuredRecordingsWithError:(NSError**)error; // returns an array of VideotoriumRecording objects
+ (NSString *)IDOfRecordingWithURL:(NSURL *)URL;

@end
