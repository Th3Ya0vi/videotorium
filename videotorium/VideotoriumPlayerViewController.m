//
//  VideotoriumViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumPlayerViewController.h"
#import "VideotoriumClient.h"
#import "VideotoriumRecordingInfoViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerView.h"

@interface VideotoriumPlayerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *slideImageView;
@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noSlidesLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *slideActivityIndicator;

@property (strong, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) UIPopoverController *splitViewPopoverController;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;
@property (nonatomic) BOOL wasFullscreenBeforeOrientationChange;

@property (weak, nonatomic) UIPopoverController *infoPopoverController;

@property (nonatomic, strong) AVPlayerView *secondaryVideoView;
@property (nonatomic) BOOL seekingInProgress;

@end

@implementation VideotoriumPlayerViewController

@synthesize recordingID = _recordingID;

@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerView = _moviePlayerView;
@synthesize toolbar = _toolbar;
@synthesize activityIndicator = _activityIndicator;
@synthesize noSlidesLabel = _noSlidesLabel;
@synthesize titleLabel = _titleLabel;
@synthesize infoButton = _infoButton;
@synthesize slideActivityIndicator = _slideActivityIndicator;

@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize splitViewPopoverController = _splitViewPopoverController;

@synthesize moviePlayerController = _moviePlayerController;

@synthesize timer = _timer;

@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;
@synthesize wasFullscreenBeforeOrientationChange = _wasFullscreenBeforeOrientationChange;

@synthesize infoPopoverController = _infoPopoverController;

@synthesize shouldAutoplay = _shouldAutoplay;

@synthesize secondaryVideoView = _secondaryVideoView;
@synthesize seekingInProgress = _seekingInProgress;

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if (self.moviePlayerController.loadState == MPMovieLoadStatePlayable) {
        [self.activityIndicator stopAnimating];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        self.moviePlayerController.view.alpha = 1;
        [UIView commitAnimations];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"videotorium-gradient.png"]forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    self.splitViewController.delegate = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:@"memoryWarning" object:nil];

#ifndef SCREENSHOTMODE
    if (!self.recordingID) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastRecordingID = [defaults stringForKey:@"lastRecordingID"];
        self.shouldAutoplay = NO;
        if (lastRecordingID) {
            self.recordingID = lastRecordingID;
        } else {
            self.recordingID = @"4055";
        }
    }
#endif
#ifdef SCREENSHOTMODE
    self.toolbar.items = [NSArray array];
#endif
}

- (void)setRecordingID:(NSString *)recordingID
{
    _recordingID = recordingID;
    
    self.titleLabel.text = @"";
    self.infoButton.enabled = NO;
    [self.splitViewPopoverController dismissPopoverAnimated:YES];
    if (self.moviePlayerController != nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
    }
    [self.activityIndicator startAnimating];
    self.recordingDetails = nil;
    [self.infoPopoverController dismissPopoverAnimated:YES];
    self.noSlidesLabel.hidden = YES;
    self.slideImageView.image = nil;
    [self.secondaryVideoView removeFromSuperview];
    self.secondaryVideoView = nil;
    self.seekingInProgress = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:recordingID forKey:@"lastRecordingID"];
    [defaults synchronize];
    
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        NSError *error;
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self.activityIndicator stopAnimating];
                self.titleLabel.text = @"Error connecting to videotorium";
            } else {
                self.recordingDetails = recordingDetails;
                self.slideImageView.image = nil;
                if ([self.recordingDetails.slides count] == 0) {
                    if (self.recordingDetails.secondaryStreamURL) {
                        self.secondaryVideoView = [[AVPlayerView alloc] initWithFrame:self.slideImageView.bounds];
                        self.secondaryVideoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                        AVPlayer *player = [AVPlayer playerWithURL:recordingDetails.secondaryStreamURL];
                        self.secondaryVideoView.player = player;
                        [self.slideImageView insertSubview:self.secondaryVideoView belowSubview:self.slideActivityIndicator];
                    } else {
                        self.noSlidesLabel.hidden = NO;
                    }
                }
                self.titleLabel.text = self.recordingDetails.title;
                self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recordingDetails.streamURL];
                self.moviePlayerController.view.frame = self.moviePlayerView.bounds;
                self.moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                self.moviePlayerController.view.alpha = 0;
                [self.moviePlayerView insertSubview:self.moviePlayerController.view belowSubview:self.activityIndicator];
                self.moviePlayerController.shouldAutoplay = self.shouldAutoplay;
                [self.moviePlayerController prepareToPlay];
                self.infoButton.enabled = YES;
            }
        });
    });
    dispatch_release(getDetailsQueue);
}

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    // If there was a bar button, we remove it
    if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem];
    // We add the new button to the bar (if there is a new button)
    if (splitViewBarButtonItem) {
        splitViewBarButtonItem.style = UIBarButtonItemStylePlain;
        [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
    }
    self.toolbar.items = toolbarItems;
    // If the setter was called with nil, then we only removed the old one without add anything new, and the property will be nil
    _splitViewBarButtonItem = splitViewBarButtonItem;
}

- (void)memoryWarning:(NSNotification *)notification
{
    [self.secondaryVideoView removeFromSuperview];
    self.secondaryVideoView = nil;
}

- (void)updateSlide
{
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    if ([self.recordingDetails.slides count] > 0) {
        // Assuming that the slides are ordered by their timestamp
        // Starting from the end find the first one which has earlier timestamp than the current playback time
        NSUInteger index = [self.recordingDetails.slides indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            VideotoriumSlide *slide = (VideotoriumSlide *)obj;
            return (slide.timestamp < currentPlaybackTime);
        }];
        // If there are no slides earlier than the current time, show the first slide anyway
        if (index == NSNotFound) index = 0;
        VideotoriumSlide *slideToShow = [self.recordingDetails.slides objectAtIndex:index];
        if (![slideToShow isEqual:self.currentSlide]) {
            self.currentSlide = slideToShow;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            self.slideImageView.alpha = 0;
            [UIView commitAnimations];
            dispatch_queue_t downloadSlideQueue = dispatch_queue_create("download slide queue", NULL);
            dispatch_async(downloadSlideQueue, ^{
                NSData *imageData = [NSData dataWithContentsOfURL:self.currentSlide.URL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.currentSlide == slideToShow) {
                        self.slideImageView.image = [UIImage imageWithData:imageData];
                        [UIView beginAnimations:nil context:nil];
                        [UIView setAnimationDuration:0.2];
                        self.slideImageView.alpha = 1;
                        [UIView commitAnimations];
                    }
                });
            });
            dispatch_release(downloadSlideQueue);
        }                    
    } else if (self.secondaryVideoView) {
        if (self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) {
            [self.secondaryVideoView.player play];
        } else {
            [self.secondaryVideoView.player pause];
        }
        if (!self.seekingInProgress) {
            if (self.secondaryVideoView.player.status == AVPlayerStatusReadyToPlay) {
                Float64 seconds = CMTimeGetSeconds(self.secondaryVideoView.player.currentTime);
                Float64 tolerance = 1;
                if (self.moviePlayerController.playbackState != MPMoviePlaybackStatePlaying) {
                    // If we are not playing, trying to get close to the current playback time would take too much time
                    tolerance = 20;
                }
                if (fabs(seconds - currentPlaybackTime) > tolerance) {
                    NSLog(@"Seconds: %f, current playback time: %f", seconds, currentPlaybackTime);
                    CMTime time = CMTimeMakeWithSeconds(currentPlaybackTime, 600);
                    self.seekingInProgress = YES;
                    [self.slideActivityIndicator startAnimating];
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    self.secondaryVideoView.alpha = 0.5;
                    [UIView commitAnimations];
                    NSLog(@"Seeking to %f", currentPlaybackTime);
                    [self.secondaryVideoView.player seekToTime:time
                                             completionHandler:^(BOOL finished) {
                                                 self.seekingInProgress = NO;
                                                 if (finished) {
                                                     NSLog(@"Seeking to %f was succesful, actual time: %f", currentPlaybackTime, CMTimeGetSeconds(self.secondaryVideoView.player.currentTime));
                                                 } else {
                                                     NSLog(@"Seeking to %f failed.", currentPlaybackTime);                               
                                                 }
                                             }];
                } else {
                    [self.slideActivityIndicator stopAnimating];
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.2];
                    self.secondaryVideoView.alpha = 1;
                    [UIView commitAnimations];
                }
            }
        }            
    }
}

- (void)viewDidUnload
{
    [self.timer invalidate];
    self.toolbar = nil;
    self.slideImageView = nil;
    self.moviePlayerView = nil;
    self.activityIndicator = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNoSlidesLabel:nil];
    [self setTitleLabel:nil];
    [self setInfoButton:nil];
    [self setSlideActivityIndicator:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration
{
    self.wasFullscreenBeforeOrientationChange = self.moviePlayerController.fullscreen;
    if (self.wasFullscreenBeforeOrientationChange) {
        self.moviePlayerController.fullscreen = NO;
        self.moviePlayerController.controlStyle = MPMovieControlStyleNone;
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.moviePlayerController.view.frame = self.splitViewController.view.bounds;
        UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(-256, 0, 1024, 1024)];
        blackView.backgroundColor = [UIColor blackColor];
        [self.splitViewController.view addSubview:blackView];
        [self.splitViewController.view addSubview:self.moviePlayerController.view];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.wasFullscreenBeforeOrientationChange) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.splitViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
        self.moviePlayerController.view.frame = self.moviePlayerView.bounds;
        [self.moviePlayerView insertSubview:self.moviePlayerController.view belowSubview:self.activityIndicator];
        [[self.splitViewController.view.subviews lastObject] removeFromSuperview];
        self.moviePlayerController.controlStyle = MPMovieControlStyleDefault;
        self.moviePlayerController.fullscreen = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Info Popover"]) {
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        VideotoriumRecordingInfoViewController *destination = popoverSegue.destinationViewController;
        self.infoPopoverController = popoverSegue.popoverController;
        destination.recording = self.recordingDetails;
        destination.popoverController = self.infoPopoverController;
    }
}

#pragma mark - Split view controller delegate

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Search";
    self.splitViewBarButtonItem = barButtonItem;
    self.splitViewPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.splitViewBarButtonItem = nil;
}

@end
