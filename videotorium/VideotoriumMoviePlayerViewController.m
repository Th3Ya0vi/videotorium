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
@property (strong, nonatomic) UIView *tapView;

@end

@implementation VideotoriumMoviePlayerViewController

- (void)setGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    _gestureRecognizer = gestureRecognizer;
    if (self.tapView) {
        [self.tapView removeFromSuperview];
        self.tapView = nil;
    }
    if (gestureRecognizer) {
        self.tapView = [[UIView alloc] initWithFrame:self.view.frame];
        self.tapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.tapView addGestureRecognizer:gestureRecognizer];
        [self.view addSubview:self.tapView];
    }
}


- (void)setStreamURL:(NSURL *)streamURL
{
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:streamURL];
    player.shouldAutoplay = self.shouldAutoplay;
    player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    player.view.frame = self.view.bounds;
    [self.view addSubview:player.view];
    _moviePlayerController = player;
    self.gestureRecognizer = self.gestureRecognizer;
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

- (void)turnOffControls {
    self.moviePlayerController.controlStyle = MPMovieControlStyleNone;
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

- (MPMoviePlaybackState)playbackState
{
    return self.moviePlayerController.playbackState;
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

- (void)pause
{
    [self.moviePlayerController pause];
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
