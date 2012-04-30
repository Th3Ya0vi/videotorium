//
//  VideotoriumViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumViewController.h"
#import "VideotoriumClient.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideotoriumViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation VideotoriumViewController

@synthesize movieView = _movieView;
@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerController = _moviePlayerController;
@synthesize timer = _timer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
}

- (IBAction)presentMovie {
    [self.moviePlayerController.view removeFromSuperview];
    [self.moviePlayerController stop];
    VideotoriumClient *client = [[VideotoriumClient alloc] init];
    VideotoriumRecording *recording = [client recordingWithID:@"2487"];
    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:recording.streamURL];
    [self.moviePlayerController.view setFrame:self.movieView.bounds];
    [self.movieView addSubview:self.moviePlayerController.view];
    [self.moviePlayerController play];
}

- (void)updateSlide
{
//	self.timeLabel.text = [NSString stringWithFormat:@"%d", [[NSNumber numberWithDouble:self.moviePlayerController.currentPlaybackTime] intValue]];
}

- (void)viewDidUnload
{
    [self.timer invalidate];
    [self setMovieView:nil];
    [self setSlideImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.moviePlayerController.view setFrame:self.movieView.bounds];
}

@end
