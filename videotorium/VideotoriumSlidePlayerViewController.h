//
//  VideotoriumSliderPlayerViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import <UIKit/UIKit.h>
#import "VideotoriumMoviePlayerViewController.h"

@protocol VideotoriumSlidesPlayerDelegate <NSObject>

@optional
- (void)slidesStoppedFollowingVideo;

@end


@interface VideotoriumSlidePlayerViewController : UIViewController <UIGestureRecognizerDelegate>

@property (weak, nonatomic) VideotoriumMoviePlayerViewController *moviePlayer;
@property (strong, nonatomic) NSArray *slides;
@property (strong, nonatomic) UIGestureRecognizer *gestureRecognizer;
@property (nonatomic) BOOL fullscreenDisabled;
@property (weak, nonatomic) id <VideotoriumSlidesPlayerDelegate> delegate;

- (void)seekToSlideWithID:(NSString *)ID;
- (void)moviePlayerPlaybackStateDidChange;


@end
