//
//  VideotoriumViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

//#define SCREENSHOTMODE

#import <UIKit/UIKit.h>
#import "VideotoriumSlidesTableViewController.h"
#import "VideotoriumRecordingInfoViewController.h"

#define kLastSearchKey @"lastSearchString"
#define kLastSelectedTab @"lastSelectedTab"
#define kLastRecordingID @"lastRecordingID"


@interface VideotoriumPlayerViewController : UIViewController <UISplitViewControllerDelegate, VideotoriumRecordingInfoViewDelegate>

@property (nonatomic, strong) NSString *recordingID;
@property (nonatomic) BOOL shouldAutoplay;

- (void)dismissSplitViewPopover;
- (void)seekToSlideWithID:(NSString *)ID;

@end
