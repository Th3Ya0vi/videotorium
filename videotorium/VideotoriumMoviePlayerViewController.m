//
//  VideotoriumMoviePlayerViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import "VideotoriumMoviePlayerViewController.h"

@interface VideotoriumMoviePlayerViewController ()

@end

@implementation VideotoriumMoviePlayerViewController

- (void)setStreamURL:(NSURL *)streamURL
{
    _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:streamURL];
    _moviePlayerController.shouldAutoplay = self.shouldAutoplay;
    _moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _moviePlayerController.view.frame = self.view.bounds;
    [self.view addSubview:_moviePlayerController.view];
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

@end
