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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;

@property (strong, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) UIPopoverController *splitViewPopoverController;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;
@property (nonatomic) BOOL wasFullscreenBeforeOrientationChange;

@property (weak, nonatomic) UIPopoverController *infoPopoverController;

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

@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize splitViewPopoverController = _splitViewPopoverController;

@synthesize moviePlayerController = _moviePlayerController;

@synthesize timer = _timer;

@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;
@synthesize wasFullscreenBeforeOrientationChange = _wasFullscreenBeforeOrientationChange;

@synthesize infoPopoverController = _infoPopoverController;

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if (self.moviePlayerController.loadState == MPMovieLoadStatePlayable) {
        [self.activityIndicator stopAnimating];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.splitViewController.delegate = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
}

- (void)setRecordingID:(NSString *)recordingID
{
    self.titleLabel.text = @"Videotorium";
    self.infoButton.enabled = NO;
    [self.splitViewPopoverController dismissPopoverAnimated:YES];
    if (self.moviePlayerController != nil) {
        [self.moviePlayerController stop];
        [self.moviePlayerController.view removeFromSuperview];
        self.moviePlayerController = nil;
    }
    [self.activityIndicator startAnimating];
    self.recordingDetails = nil;
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordingDetails = recordingDetails;
            self.titleLabel.text = self.recordingDetails.title;
            self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:self.recordingDetails.streamURL];
            self.moviePlayerController.view.frame = self.moviePlayerView.bounds;
            self.moviePlayerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.moviePlayerView insertSubview:self.moviePlayerController.view belowSubview:self.activityIndicator];
            [self.moviePlayerController play];
            self.infoButton.enabled = YES;
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
    if (splitViewBarButtonItem) [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
    self.toolbar.items = toolbarItems;
    // If the setter was called with nil, then we only removed the old one without add anything new, and the property will be nil
    _splitViewBarButtonItem = splitViewBarButtonItem;
}

- (void)updateSlide
{
    if (self.moviePlayerController) {
        NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
        VideotoriumSlide *slideToShow = nil;
        if ([self.recordingDetails.slides count] > 0) {
            slideToShow = [self.recordingDetails.slides objectAtIndex:0];
            for (VideotoriumSlide *slide in self.recordingDetails.slides) {
                if ((slide.timestamp < currentPlaybackTime) &&
                    (slide.timestamp > slideToShow.timestamp)) {
                    slideToShow = slide;
                }
            }            
        }
        if (slideToShow) {
            self.noSlidesLabel.hidden = YES;
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
        } else {
            self.slideImageView.image = nil;
            self.noSlidesLabel.hidden = NO;
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
        self.moviePlayerController.view.frame = self.splitViewController.view.bounds;
        [self.splitViewController.view addSubview:self.moviePlayerController.view];
        [self.splitViewController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
            obj.view.hidden = TRUE;
        }];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.wasFullscreenBeforeOrientationChange) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.splitViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
        [self.splitViewController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
            obj.view.hidden = NO;
        }];
        self.moviePlayerController.view.frame = self.moviePlayerView.bounds;
        [self.moviePlayerView insertSubview:self.moviePlayerController.view belowSubview:self.activityIndicator];
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
