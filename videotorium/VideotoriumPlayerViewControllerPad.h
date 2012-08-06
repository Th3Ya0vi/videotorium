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
#import "VideotoriumPlayerViewController.h"

#define kLastSearchKey @"lastSearchString"
#define kLastSelectedTab @"lastSelectedTab"
#define kLastRecordingID @"lastRecordingID"


@interface VideotoriumPlayerViewControllerPad : UIViewController <UISplitViewControllerDelegate, VideotoriumRecordingInfoViewDelegate, VideotoriumPlayerViewController>

@end
