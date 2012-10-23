//
//  VideotoriumPlayerViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

//#define SCREENSHOTMODE

#define kLastRecordingID @"lastRecordingID"
#define kLastRecordingPosition @"lastRecordingPosition"

#import <Foundation/Foundation.h>

@protocol VideotoriumPlayerViewController <NSObject>

@property (nonatomic, strong) NSString *recordingID;

- (void)setRecordingID:(NSString *)recordingID autoplay:(BOOL)shouldAutoplay;

- (void)seekToSlideWithID:(NSString *)ID;
- (void)seekToPosition:(NSNumber *)position;


@end
