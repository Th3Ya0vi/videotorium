//
//  VideotoriumViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumPlayerViewController.h"
#import "VideotoriumClient.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideotoriumPlayerViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;

@end

@implementation VideotoriumPlayerViewController

@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerController = _moviePlayerController;
@synthesize timer = _timer;
@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];

    VideotoriumClient *client = [[VideotoriumClient alloc] init];
    client.videotoriumBaseURL = @"http://localhost/";
    self.recordingDetails = [client detailsWithID:@"2487"];
    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recordingDetails.streamURL];
    self.slideImageView = [[UIImageView alloc] init];
    self.slideImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self layout];
    [self.view addSubview:self.moviePlayerController.view];    
    [self.view addSubview:self.slideImageView];    \
    [self.moviePlayerController play];
}

- (void)layout {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, width/2, height/2)];
        [self.slideImageView setFrame:CGRectMake(width/2, 0, width/2, height/2)];
    } else {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, width, height/2)];
        [self.slideImageView setFrame:CGRectMake(0, height/2, width, height/2)];        
    }
}

- (void)updateSlide
{
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    VideotoriumSlide *slideToShow = nil;
    for (VideotoriumSlide *slide in self.recordingDetails.slides) {
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
    [self layout];
}

@end
