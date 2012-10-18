//
//  VideotoriumPlayerViewControllerPhoneViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import <UIKit/UIKit.h>
#import "VideotoriumPlayerViewController.h"
#import "VideotoriumRecordingInfoViewController.h"
#import "VideotoriumSlidePlayerViewController.h"

@interface VideotoriumPlayerViewControllerPhone : UIViewController <VideotoriumPlayerViewController, VideotoriumRecordingInfoViewDelegate, UIScrollViewDelegate, VideotoriumSlidesPlayerDelegate>

@end
