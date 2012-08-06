//
//  VideotoriumMoviePlayerViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import "VideotoriumMoviePlayerViewController.h"

@interface VideotoriumMoviePlayerViewController ()

@property (strong, nonatomic) MPMoviePlayerController *moviePlayerController;
@property (nonatomic) BOOL wasFullscreenBeforeOrientationChange;
@property (strong, nonatomic) UIView *blackView;

@end

@implementation VideotoriumMoviePlayerViewController

- (void)setStreamURL:(NSURL *)streamURL
{
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:streamURL];
    player.shouldAutoplay = self.shouldAutoplay;
    player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    player.view.frame = self.view.bounds;
    [self.view addSubview:player.view];
    _moviePlayerController = player;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setShouldAutoplay:(BOOL)shouldAutoplay
{
    _shouldAutoplay = shouldAutoplay;
    if (self.moviePlayerController) {
        self.moviePlayerController.shouldAutoplay = shouldAutoplay;
    }
}

- (NSTimeInterval)currentPlaybackTime
{
    return self.moviePlayerController.currentPlaybackTime;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    self.moviePlayerController.currentPlaybackTime = currentPlaybackTime;
}

- (NSTimeInterval)duration
{
    return self.moviePlayerController.duration;
}

- (MPMovieLoadState)loadState
{
    return self.moviePlayerController.loadState;
}

- (void)prepareToPlay
{
    [self.moviePlayerController prepareToPlay];
}

- (void)play
{
    [self.moviePlayerController play];
}

- (void)stop
{
    [self.moviePlayerController stop];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.wasFullscreenBeforeOrientationChange = self.moviePlayerController.fullscreen;
    if (self.wasFullscreenBeforeOrientationChange) {
        self.moviePlayerController.fullscreen = NO;
        self.moviePlayerController.controlStyle = MPMovieControlStyleNone;
        UIView *rootView = self.view.window.rootViewController.view;
        self.blackView = [[UIView alloc] initWithFrame:CGRectMake(-256, 0, 1280, 1024)];
        self.blackView.backgroundColor = [UIColor blackColor];
        [rootView addSubview:self.blackView];
        self.moviePlayerController.view.frame = rootView.bounds;
        [rootView addSubview:self.moviePlayerController.view];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.wasFullscreenBeforeOrientationChange) {
        self.moviePlayerController.view.frame = self.view.bounds;
        [self.view addSubview:self.moviePlayerController.view];
        [self.blackView removeFromSuperview];
        self.blackView = nil;
        self.moviePlayerController.controlStyle = MPMovieControlStyleDefault;
        self.moviePlayerController.fullscreen = YES;
    }
}

@end
