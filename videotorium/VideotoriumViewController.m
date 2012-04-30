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
@property (nonatomic, strong) VideotoriumRecording *recording;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;

@end

@implementation VideotoriumViewController

@synthesize movieView = _movieView;
@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerController = _moviePlayerController;
@synthesize timer = _timer;
@synthesize recording = _recording;
@synthesize currentSlide = _currentSlide;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];

    VideotoriumClient *client = [[VideotoriumClient alloc] init];
    self.recording = [client recordingWithID:@"2487"];
}

- (IBAction)presentMovie {
    [self.moviePlayerController.view removeFromSuperview];
    [self.moviePlayerController stop];

    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recording.streamURL];
    
    [self.moviePlayerController.view setFrame:self.movieView.bounds];
    [self.movieView addSubview:self.moviePlayerController.view];
    [self.moviePlayerController play];
}

- (void)updateSlide
{
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    VideotoriumSlide *slideToShow = nil;
    for (VideotoriumSlide *slide in self.recording.slides) {
        if ((slide.timestamp < currentPlaybackTime) &&
            (slide.timestamp > slideToShow.timestamp)) {
            slideToShow = slide;
        }
    }
    if (slideToShow != nil) {
        if (![slideToShow isEqual:self.currentSlide]) {
            self.currentSlide = slideToShow;
            self.slideImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.currentSlide.URL]];
        }
    }
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
