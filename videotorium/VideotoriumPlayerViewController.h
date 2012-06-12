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

@interface VideotoriumPlayerViewController : UIViewController <UISplitViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString *recordingID;
@property (nonatomic) BOOL shouldAutoplay;

- (void)dismissSplitViewPopover;
- (void)seekToSlideWithID:(NSString *)ID;

@end
