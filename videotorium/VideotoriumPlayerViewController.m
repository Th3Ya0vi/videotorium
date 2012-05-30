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
@property (nonatomic, strong) UIImageView *slideImageView;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;

@end

@implementation VideotoriumPlayerViewController

@synthesize recordingID = _recordingID;

@synthesize moviePlayerController = _moviePlayerController;
@synthesize slideImageView = _slideImageView;

@synthesize timer = _timer;
@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
//    self.recordingID = @"2487";
}

- (void)setRecordingID:(NSString *)recordingID
{
    if (self.moviePlayerController != nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
    }
    if (self.slideImageView != nil) {
        [self.slideImageView removeFromSuperview];
        self.slideImageView = nil;
    }
    self.recordingDetails = nil;
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordingDetails = recordingDetails;
            self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recordingDetails.streamURL];
            self.slideImageView = [[UIImageView alloc] init];
            self.slideImageView.contentMode = UIViewContentModeScaleAspectFit;
            [self layout];
            [self.view addSubview:self.moviePlayerController.view];    
            [self.view addSubview:self.slideImageView];
            [self.moviePlayerController play];        
        });
    });
    dispatch_release(getDetailsQueue);
}

- (void)layout {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, width, height/2)];
        [self.slideImageView setFrame:CGRectMake(0, height/2, width, height/2)];
    } else {
        [self.moviePlayerController.view setFrame:CGRectMake(0, 0, width, height/2)];
        [self.slideImageView setFrame:CGRectMake(0, height/2, width, height/2)];        
    }
}

- (void)updateSlide
{
    if (self.moviePlayerController == nil) return;
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    VideotoriumSlide *slideToShow = nil;
    for (VideotoriumSlide *slide in self.recordingDetails.slides) {
        if ((slide.timestamp < currentPlaybackTime) &&
            (slide.timestamp > slideToShow.timestamp)) {
            slideToShow = slide;
        }
    }
    if (![slideToShow isEqual:self.currentSlide]) {
        self.currentSlide = slideToShow;
        dispatch_queue_t downloadSlideQueue = dispatch_queue_create("download slide queue", NULL);
        dispatch_async(downloadSlideQueue, ^{
            NSData *imageData = [NSData dataWithContentsOfURL:self.currentSlide.URL];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.currentSlide == slideToShow) {
	                self.slideImageView.image = [UIImage imageWithData:imageData];
                }
            });
        });
        dispatch_release(downloadSlideQueue);
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
