//
//  VideotoriumSliderPlayerViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import <UIKit/UIKit.h>
#import "VideotoriumMoviePlayerViewController.h"

@interface VideotoriumSlidePlayerViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic) BOOL seekingInProgress;
@property (weak, nonatomic) VideotoriumMoviePlayerViewController *moviePlayer;

@property (strong, nonatomic) NSArray *slides;


- (void)seekToSlideWithID:(NSString *)ID;

@end
