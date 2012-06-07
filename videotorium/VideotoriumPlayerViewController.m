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

@interface VideotoriumPlayerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *slideImageView;
@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noSlidesLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryVideoNotSupportedLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *slidesButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *slideActivityIndicator;

@property (strong, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) UIPopoverController *splitViewPopoverController;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;
@property (nonatomic) BOOL wasFullscreenBeforeOrientationChange;

@property (weak, nonatomic) UIPopoverController *infoAndSlidesPopoverController;

@end

@implementation VideotoriumPlayerViewController

@synthesize recordingID = _recordingID;
@synthesize resultsOnSlides = _resultsOnSlides;

@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerView = _moviePlayerView;
@synthesize toolbar = _toolbar;
@synthesize activityIndicator = _activityIndicator;
@synthesize noSlidesLabel = _noSlidesLabel;
@synthesize titleLabel = _titleLabel;
@synthesize secondaryVideoNotSupportedLabel = _secondaryVideoNotSupportedLabel;
@synthesize infoButton = _infoButton;
@synthesize slidesButton = _slidesButton;
@synthesize slideActivityIndicator = _slideActivityIndicator;

@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize splitViewPopoverController = _splitViewPopoverController;

@synthesize moviePlayerController = _moviePlayerController;

@synthesize timer = _timer;

@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;
@synthesize wasFullscreenBeforeOrientationChange = _wasFullscreenBeforeOrientationChange;

@synthesize infoAndSlidesPopoverController = _infoAndSlidesPopoverController;

@synthesize shouldAutoplay = _shouldAutoplay;

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if (self.moviePlayerController.loadState == MPMovieLoadStatePlayable) {
        [self.activityIndicator stopAnimating];
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.moviePlayerController.view.alpha = 1;
                         }];        
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
    if ([notification.userInfo objectForKey:@"error"]) {
        [self.activityIndicator stopAnimating];
        self.titleLabel.text = @"Failed to play the video stream";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"videotorium-gradient.png"]forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    self.splitViewController.delegate = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
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
    self.slidesButton.enabled = YES;
    [self.splitViewPopoverController dismissPopoverAnimated:YES];
    if (self.moviePlayerController != nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
    }
    [self.activityIndicator startAnimating];
    self.recordingDetails = nil;
    [self.infoAndSlidesPopoverController dismissPopoverAnimated:YES];
    self.noSlidesLabel.hidden = YES;
    self.secondaryVideoNotSupportedLabel.hidden = YES;
    self.slideImageView.image = nil;
    
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
                        self.secondaryVideoNotSupportedLabel.hidden = NO;
                    } else {
                        self.noSlidesLabel.hidden = NO;
                    }
                } else {
                    self.slidesButton.enabled = YES;
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
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.slideImageView.alpha = 0;
                             }];
            dispatch_queue_t downloadSlideQueue = dispatch_queue_create("download slide queue", NULL);
            dispatch_async(downloadSlideQueue, ^{
                NSData *imageData = [NSData dataWithContentsOfURL:self.currentSlide.imageURL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.currentSlide == slideToShow) {
                        self.slideImageView.image = [UIImage imageWithData:imageData];
                        [UIView animateWithDuration:0.2
                                         animations:^{
                                             self.slideImageView.alpha = 1;
                                         }];
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
    self.toolbar = nil;
    self.slideImageView = nil;
    self.moviePlayerView = nil;
    self.activityIndicator = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNoSlidesLabel:nil];
    [self setTitleLabel:nil];
    [self setInfoButton:nil];
    [self setSlideActivityIndicator:nil];
    [self setSecondaryVideoNotSupportedLabel:nil];
    [self setSlidesButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration
{
    [self.infoAndSlidesPopoverController dismissPopoverAnimated:YES];
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
        self.infoAndSlidesPopoverController = popoverSegue.popoverController;
        destination.recording = self.recordingDetails;
        destination.popoverController = self.infoAndSlidesPopoverController;
    }
    if ([segue.identifier isEqualToString:@"Slides Popover"]) {
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        VideotoriumSlidesTableViewController *destination = popoverSegue.destinationViewController;
        self.infoAndSlidesPopoverController = popoverSegue.popoverController;
        destination.delegate = self;
        destination.slides = self.recordingDetails.slides;
        destination.resultsOnSlides = self.resultsOnSlides;
        [destination scrollToSlide:self.currentSlide animated:NO];
        destination.popoverController = self.infoAndSlidesPopoverController;
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


#pragma mark - Videotorium slide table delegate

- (void)userSelectedSlide:(VideotoriumSlide *)slide {
    self.moviePlayerController.currentPlaybackTime = slide.timestamp;
    [self.moviePlayerController play];
    [self.infoAndSlidesPopoverController dismissPopoverAnimated:YES];
}

@end
