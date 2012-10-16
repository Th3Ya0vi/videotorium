//
//  VideotoriumRecordingInfoViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.01..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideotoriumRecordingDetails.h"

@protocol VideotoriumRecordingInfoViewDelegate <NSObject>

@optional
-(void)userSelectedRecordingWithURL:(NSURL *)recordingURL;
-(void)userPressedDoneButton;

@end

@interface VideotoriumRecordingInfoViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, copy) VideotoriumRecordingDetails *recording;
@property (nonatomic, weak) UIPopoverController *infoPopoverController;
@property (nonatomic, weak) id <VideotoriumRecordingInfoViewDelegate> delegate;

@end
