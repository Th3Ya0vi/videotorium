//
//  VideotoriumMoviePlayerViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VideotoriumMoviePlayerViewController : UIViewController

@property (strong, nonatomic) UIGestureRecognizer *gestureRecognizer;

@property (strong, nonatomic) NSURL *streamURL;
@property (nonatomic) BOOL shouldAutoplay;

@property(nonatomic) NSTimeInterval currentPlaybackTime;
@property(nonatomic, readonly) NSTimeInterval duration;
@property(nonatomic, readonly) MPMovieLoadState loadState;

- (void)prepareToPlay;
- (void)play;
- (void)stop;

@end
