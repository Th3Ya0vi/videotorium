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
        
-(void)userSelectedRecordingWithURL:(NSURL *)recordingURL;

@end

@interface VideotoriumRecordingInfoViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, copy) VideotoriumRecordingDetails *recording;
@property (nonatomic, weak) UIPopoverController *popoverController;
@property (nonatomic, weak) id <VideotoriumRecordingInfoViewDelegate> delegate;

@end
