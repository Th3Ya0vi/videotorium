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

@property (weak, nonatomic) IBOutlet UIImageView *slideImageView;
@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UINavigationBar *titleBar;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;

@end

@implementation VideotoriumPlayerViewController

@synthesize recordingID = _recordingID;

@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerView = _moviePlayerView;
@synthesize titleBar = _titleBar;

@synthesize moviePlayerController = _moviePlayerController;

@synthesize timer = _timer;

@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
}

- (void)setRecordingID:(NSString *)recordingID
{
    if (self.moviePlayerController != nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
    }
    self.recordingDetails = nil;
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordingDetails = recordingDetails;
            self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recordingDetails.streamURL];
            self.moviePlayerController.view.frame = self.moviePlayerView.frame;
            [self.moviePlayerView addSubview:self.moviePlayerController.view];
            [self.moviePlayerController play];        
        });
    });
    dispatch_release(getDetailsQueue);
}

- (void)updateSlide
{
    if (self.moviePlayerController) {
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
}

- (void)viewDidUnload
{
    [self.timer invalidate];
    self.titleBar = nil;
    self.slideImageView = nil;
    self.moviePlayerView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.moviePlayerController) {
        self.moviePlayerController.view.frame = self.moviePlayerView.frame;        
    }
}

@end
