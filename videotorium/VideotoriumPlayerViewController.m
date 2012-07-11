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
#import <QuartzCore/QuartzCore.h>

@interface VideotoriumPlayerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *slideImageView;
@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noSlidesLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryVideoNotSupportedLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *slideActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIView *slideView;
@property (weak, nonatomic) IBOutlet UIButton *seekToThisSlideButton;
@property (weak, nonatomic) IBOutlet UIButton *followVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UILabel *slideNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForSlideWithoutButtons;
@property (weak, nonatomic) IBOutlet UIView *viewForSlideWithVisibleButtons;
@property (weak, nonatomic) IBOutlet UIView *introductoryTextContainerView;
@property (weak, nonatomic) IBOutlet UILabel *introductoryTextLabel;


@property (strong, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) UIPopoverController *splitViewPopoverController;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;
@property (nonatomic, strong) VideotoriumSlide *currentSlide;
@property (nonatomic, strong) VideotoriumSlide *slideToShow;
@property (nonatomic) BOOL wasFullscreenBeforeOrientationChange;

@property (weak, nonatomic) UIPopoverController *infoAndSlidesPopoverController;
@property (nonatomic) BOOL slideIsFullscreen;
@property (nonatomic) BOOL slideZoomingInProgress;

@property (nonatomic) BOOL slidesFollowVideo;

@property (strong, nonatomic) UIView *blackView;

@property (nonatomic) BOOL seekingInProgress;

@property (nonatomic) BOOL userSwipedSlides;

@end

@implementation VideotoriumPlayerViewController

@synthesize recordingID = _recordingID;

@synthesize slideImageView = _slideImageView;
@synthesize moviePlayerView = _moviePlayerView;
@synthesize toolbar = _toolbar;
@synthesize activityIndicator = _activityIndicator;
@synthesize noSlidesLabel = _noSlidesLabel;
@synthesize titleLabel = _titleLabel;
@synthesize secondaryVideoNotSupportedLabel = _secondaryVideoNotSupportedLabel;
@synthesize infoButton = _infoButton;
@synthesize slideActivityIndicator = _slideActivityIndicator;
@synthesize slideContainerView = _slideContainerView;
@synthesize slideView = _slideView;
@synthesize seekToThisSlideButton = _seekToThisSlideButton;
@synthesize followVideoButton = _followVideoButton;
@synthesize retryButton = _retryButton;
@synthesize slideNumberLabel = _slideNumberLabel;
@synthesize viewForSlideWithoutButtons = _viewForSlideWithoutButtons;
@synthesize viewForSlideWithVisibleButtons = _viewForSlideWithVisibleButtons;
@synthesize introductoryTextContainerView = _introductoryTextContainerView;
@synthesize introductoryTextLabel = _introductoryTextLabel;

@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize splitViewPopoverController = _splitViewPopoverController;

@synthesize moviePlayerController = _moviePlayerController;

@synthesize timer = _timer;

@synthesize recordingDetails = _recordingDetails;
@synthesize currentSlide = _currentSlide;
@synthesize slideToShow = _slideToShow;
@synthesize wasFullscreenBeforeOrientationChange = _wasFullscreenBeforeOrientationChange;

@synthesize infoAndSlidesPopoverController = _infoAndSlidesPopoverController;

@synthesize slideIsFullscreen = _slideIsFullscreen;
@synthesize slideZoomingInProgress = _slideZoomingInProgress;
@synthesize slidesFollowVideo = _slidesFollowVideo;

@synthesize shouldAutoplay = _shouldAutoplay;

@synthesize blackView = _blackView;

@synthesize userSwipedSlides = _userSwipedSlides;
@synthesize seekingInProgress = _seekingInProgress;


- (void)viewDidAppear:(BOOL)animated
{
    if (!self.recordingID) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = CGRectMake(0, 0, 1024, 1024);
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor grayColor] CGColor], nil];
        [self.introductoryTextContainerView.layer insertSublayer:gradient atIndex:0];
        [UIView animateWithDuration:1 animations:^{
            self.introductoryTextContainerView.alpha = 1;
        }];
    }
}

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
        [UIView animateWithDuration:0.2 animations:^{
            self.retryButton.alpha = 1;
        }];
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    self.seekingInProgress = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.splitViewController.delegate = self;
    if ([self.splitViewController respondsToSelector:@selector(setPresentsWithGesture:)]) {
        self.splitViewController.presentsWithGesture = NO;        
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    UISwipeGestureRecognizer *swipeRightGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeRightGR.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRightGR.delegate = self;
    UISwipeGestureRecognizer *swipeLeftGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeLeftGR.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swipeUpGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeUpGR.direction = UISwipeGestureRecognizerDirectionUp;
    UISwipeGestureRecognizer *swipeDownGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeDownGR.direction = UISwipeGestureRecognizerDirectionDown;
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.slideImageView addGestureRecognizer:pinchGR];
    [self.slideImageView addGestureRecognizer:swipeLeftGR];
    [self.slideImageView addGestureRecognizer:swipeRightGR];
    [self.slideImageView addGestureRecognizer:swipeUpGR];
    [self.slideImageView addGestureRecognizer:swipeDownGR];
    [self.slideImageView addGestureRecognizer:tapGR];
    
    self.seekToThisSlideButton.alpha = 0;
    self.followVideoButton.alpha = 0;
    self.slideNumberLabel.alpha = 0;
    self.retryButton.alpha = 0;
    self.introductoryTextContainerView.alpha = 0;

#ifndef SCREENSHOTMODE
    if (!self.recordingID) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastRecordingID = [defaults stringForKey:kLastRecordingID];
        self.shouldAutoplay = NO;
        if (lastRecordingID) {
            self.recordingID = lastRecordingID;
        }
    }
#endif

#ifdef SCREENSHOTMODE
    self.introductoryTextContainerView = nil;
    self.titleLabel.text = @"";
#endif
    
    
    [self.retryButton setTitle:NSLocalizedString(@"failedToLoadRetry", nil) forState:UIControlStateNormal];
    self.secondaryVideoNotSupportedLabel.text = NSLocalizedString(@"secondaryVideoNotSupported", nil);
    self.noSlidesLabel.text = NSLocalizedString(@"noSlides", nil);
    [self.followVideoButton setTitle:NSLocalizedString(@"followVideo", nil) forState:UIControlStateNormal];
    [self.seekToThisSlideButton setTitle:NSLocalizedString(@"seekToThisSlide", nil) forState:UIControlStateNormal];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextLandscape", nil);
    } else {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextPortrait", nil);
    }
}

- (void)setRecordingID:(NSString *)recordingID
{
    _recordingID = recordingID;
    
    self.titleLabel.text = @"";
    self.infoButton.enabled = NO;
    self.slidesFollowVideo = YES;
    self.userSwipedSlides = NO;
    self.seekingInProgress = NO;
    [self slideToNormal];
    self.retryButton.alpha = 0;
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
    
    [UIView animateWithDuration:0.2 animations:^{
        self.introductoryTextContainerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.introductoryTextContainerView removeFromSuperview];
        self.introductoryTextContainerView = nil;
        self.introductoryTextLabel = nil;
    }];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:recordingID forKey:@"lastRecordingID"];
    [defaults synchronize];
    
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        NSError *error;
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            // If the recordingID was changed meanwhile, this recording is not needed anymore
            if (![recordingID isEqualToString:_recordingID]) return;
            if (error || !recordingDetails || !recordingDetails.streamURL) {
                [self.activityIndicator stopAnimating];
                [UIView animateWithDuration:0.2 animations:^{
                    self.retryButton.alpha = 1;
                }];
            } else {
                self.recordingDetails = recordingDetails;
                self.slideImageView.image = nil;
                if ([self.recordingDetails.slides count] == 0) {
                    if (self.recordingDetails.secondaryStreamURL) {
                        self.secondaryVideoNotSupportedLabel.hidden = NO;
                    } else {
                        self.noSlidesLabel.alpha = 1;
                        self.noSlidesLabel.hidden = NO;
                        [UIView animateWithDuration:2 delay:10 options:UIViewAnimationCurveLinear animations:^{
                            self.noSlidesLabel.alpha = 0;
                        } completion:^(BOOL finished) {}];
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

- (void)dismissSplitViewPopover
{
    [self.splitViewPopoverController dismissPopoverAnimated:YES];
}

- (void)seekToSlideWithID:(NSString *)ID
{
    if (self.moviePlayerController.loadState == MPMovieLoadStateUnknown) {
        [self performSelector:@selector(seekToSlideWithID:) withObject:ID afterDelay:1];
    } else {
        [self.recordingDetails.slides enumerateObjectsUsingBlock:^(VideotoriumSlide *slide, NSUInteger idx, BOOL *stop) {
            if ([slide.ID isEqualToString:ID]) {
                *stop = YES;
                NSTimeInterval seekTime = slide.timestamp;
                if (seekTime > self.moviePlayerController.duration - 10) {
                    seekTime = self.moviePlayerController.duration - 10;
                }
                self.moviePlayerController.currentPlaybackTime = seekTime;
                [self.moviePlayerController play];
                self.slideToShow = slide;
                self.seekingInProgress = YES;
                self.slidesFollowVideo = YES;
            }
        }];        
    }
}

- (void)updateSlide
{
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    if ([self.recordingDetails.slides count] > 0) {
        if (self.slidesFollowVideo) {
            if (self.seekToThisSlideButton.alpha == 1) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.seekToThisSlideButton.alpha = 0;
                    self.followVideoButton.alpha = 0;
                    self.slideNumberLabel.alpha = 0;
                    self.slideImageView.transform = CGAffineTransformIdentity;
                    self.slideImageView.frame = self.viewForSlideWithoutButtons.frame;
                }];
            }
            if (!self.seekingInProgress) {
                // Assuming that the slides are ordered by their timestamp
                // Starting from the end find the first one which has earlier timestamp than the current playback time
                NSUInteger index = [self.recordingDetails.slides indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    VideotoriumSlide *slide = (VideotoriumSlide *)obj;
                    return (slide.timestamp < currentPlaybackTime);
                }];
                // If there are no slides earlier than the current time, show the first slide anyway
                if (index == NSNotFound) index = 0;
                self.slideToShow = [self.recordingDetails.slides objectAtIndex:index];
            }
        } else {
            if (self.seekToThisSlideButton.alpha == 0) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.seekToThisSlideButton.alpha = 1;
                    self.followVideoButton.alpha = 1;
                    self.slideNumberLabel.alpha = 1;
                    self.slideImageView.transform = CGAffineTransformIdentity;
                    self.slideImageView.frame = self.viewForSlideWithVisibleButtons.frame;
                }];
            }
            
        }
        if (![self.slideToShow isEqual:self.currentSlide]) {
            BOOL slideFromLeft = self.currentSlide.timestamp > self.slideToShow.timestamp;
            BOOL dissolve = !self.userSwipedSlides;
            self.userSwipedSlides = NO;
            self.currentSlide = self.slideToShow;
            self.slideView.userInteractionEnabled = NO;
            NSTimeInterval firstAnimationDuration = 0.2;
            if (dissolve) firstAnimationDuration = 0;
            NSString *currentRecordingID = self.recordingID;
            [UIView animateWithDuration:firstAnimationDuration
                             animations:^{
                                 if (!dissolve) {
                                     if (slideFromLeft) {
                                         self.slideImageView.transform = CGAffineTransformMakeTranslation(self.slideImageView.bounds.size.width, 0);                            
                                     } else {
                                         self.slideImageView.transform = CGAffineTransformMakeTranslation(-self.slideImageView.bounds.size.width, 0);                            
                                     }
                                 }
                             } completion:^(BOOL finished) {
                                 if (![currentRecordingID isEqualToString:self.recordingID]) return;
                                 dispatch_queue_t downloadSlideQueue = dispatch_queue_create("download slide queue", NULL);
                                 dispatch_async(downloadSlideQueue, ^{
                                     NSData *imageData = [NSData dataWithContentsOfURL:self.currentSlide.imageURL];
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (![currentRecordingID isEqualToString:self.recordingID]) return;
                                         if (self.currentSlide == self.slideToShow) {
                                             self.slideNumberLabel.text = [NSString stringWithFormat:@"%d", [self.recordingDetails.slides indexOfObject:self.currentSlide] + 1];
                                             UIImage *newImage = [UIImage imageWithData:imageData];
                                             if (dissolve) {
                                                 [UIView transitionWithView:self.slideImageView duration:0.2
                                                                    options:UIViewAnimationOptionTransitionCrossDissolve
                                                                 animations:^{
                                                                     self.slideImageView.image = newImage;
                                                                 }
                                                                 completion:^(BOOL finished) {
                                                                     if (![currentRecordingID isEqualToString:self.recordingID]) return;
                                                                     self.slideView.userInteractionEnabled = YES;
                                                                 }];
                                             } else {
                                                 self.slideImageView.image = newImage;
                                                 if (slideFromLeft) {
                                                     self.slideImageView.transform = CGAffineTransformMakeTranslation(-self.slideImageView.bounds.size.width, 0);                            
                                                 } else {
                                                     self.slideImageView.transform = CGAffineTransformMakeTranslation(self.slideImageView.bounds.size.width, 0);                            
                                                 }
                                                 [UIView animateWithDuration:0.2
                                                                  animations:^{
                                                                      self.slideImageView.transform = CGAffineTransformIdentity;

                                                                  }
                                                                  completion:^(BOOL finished) {
                                                                      if (![currentRecordingID isEqualToString:self.recordingID]) return;
                                                                      self.slideView.userInteractionEnabled = YES;
                                                                  }];
                                             }
                                         }
                                     });
                                 });
                                 dispatch_release(downloadSlideQueue);
                             }];
        }
        if (self.seekingInProgress) {
            if (self.currentSlide.timestamp < self.moviePlayerController.currentPlaybackTime) {
                self.seekingInProgress = NO;
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
    [self setSecondaryVideoNotSupportedLabel:nil];
    [self setSlideContainerView:nil];
    [self setSlideView:nil];
    [self setSeekToThisSlideButton:nil];
    [self setFollowVideoButton:nil];
    [self setRetryButton:nil];
    [self setSlideNumberLabel:nil];
    [self setViewForSlideWithoutButtons:nil];
    [self setViewForSlideWithVisibleButtons:nil];
    [self setIntroductoryTextContainerView:nil];
    [self setIntroductoryTextLabel:nil];
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
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextLandscape", nil);
    } else {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextPortrait", nil);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.infoAndSlidesPopoverController) {
        // dismiss and recreate the info popover, otherwise it screws up the passthrough views
        [self.infoAndSlidesPopoverController dismissPopoverAnimated:YES];
        [self performSegueWithIdentifier:@"Info Popover" sender:self.infoButton];
    }
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
        destination.delegate = self;
    }
}

- (IBAction)retryButtonPressed:(id)sender {
    self.recordingID = self.recordingID;
}

#pragma mark - Videotorium recording info view delegate

-(void)userSelectedRecordingWithURL:(NSURL *)recordingURL {
    [self.infoAndSlidesPopoverController dismissPopoverAnimated:YES];
    self.recordingID = [VideotoriumClient IDOfRecordingWithURL:recordingURL];
}

#pragma mark - Split view controller delegate

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = NSLocalizedString(@"recordings", nil);
    self.splitViewBarButtonItem = barButtonItem;
    self.splitViewPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.splitViewBarButtonItem = nil;
}


#pragma mark - Handling gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (void)slideToNormal {
    if (self.slideIsFullscreen && !self.slideZoomingInProgress) {
        self.slideZoomingInProgress = YES;
        CGRect originalRectInSuperview = [self.view convertRect:self.slideContainerView.frame toView:self.view.superview];
        [UIView animateWithDuration:0.3 animations:^{
            self.slideView.frame = originalRectInSuperview;
            self.blackView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.slideContainerView addSubview:self.slideView];
            self.slideView.frame = self.slideContainerView.bounds;
            [self.blackView removeFromSuperview];
            self.blackView = nil;
            self.slideIsFullscreen = NO;
            self.slideZoomingInProgress = NO;
        }];
    }
}

- (void)slideToFullscreen {
    if (!self.slideIsFullscreen && !self.slideZoomingInProgress) {
        self.slideZoomingInProgress = YES;
        self.blackView = [[UIView alloc] initWithFrame:CGRectMake(-256, 0, 1280, 1024)];
        self.blackView.backgroundColor = [UIColor blackColor];
        self.blackView.alpha = 0;
        CGRect rectInSuperview = [self.view convertRect:self.slideContainerView.frame toView:self.view.superview];
        [self.view.superview addSubview:self.blackView];
        [self.view.superview addSubview:self.slideView];
        self.slideView.frame = rectInSuperview;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.slideView.frame = self.view.superview.bounds;
                             self.blackView.alpha = 1;
                         } completion:^(BOOL finished) {
                             self.slideIsFullscreen = YES;
                             self.slideZoomingInProgress = NO;
                         }];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if ([self.recordingDetails.slides count]) {
        if (sender.state == UIGestureRecognizerStateChanged) {
            if (sender.scale > 1) {
                [self slideToFullscreen];
            }
            if (sender.scale < 1) {
                [self slideToNormal];
            }
        }        
    }
}

- (IBAction)seekVideoToCurrentSlide {
    [self seekToSlideWithID:self.currentSlide.ID];
}

- (IBAction)makeSlidesFollowVideo {
    self.slidesFollowVideo = YES;
    self.userSwipedSlides = YES;
    [self updateSlide];
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)sender {
    if ([self.recordingDetails.slides count]) {
        self.seekingInProgress = NO;
        NSUInteger indexOfCurrentSlide = [self.recordingDetails.slides indexOfObject:self.currentSlide];
        if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
            self.userSwipedSlides = YES;
            if (indexOfCurrentSlide > 0) {
                self.slidesFollowVideo = NO;
                self.slideToShow = [self.recordingDetails.slides objectAtIndex:(indexOfCurrentSlide - 1)];
                [self updateSlide];
            } else {
                CGAffineTransform transform = self.slideImageView.transform;
                [UIView animateWithDuration:0.1 animations:^{
                    self.slideImageView.transform = CGAffineTransformTranslate(transform, self.slideImageView.bounds.size.width/4 , 0);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        self.slideImageView.transform = transform;
                    }];
                }];
            }
        }
        if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
            self.userSwipedSlides = YES;
            if (indexOfCurrentSlide < [self.recordingDetails.slides count] - 1) {
                self.slidesFollowVideo = NO;
                self.slideToShow = [self.recordingDetails.slides objectAtIndex:(indexOfCurrentSlide + 1)];
                [self updateSlide];
            } else {
                CGAffineTransform transform = self.slideImageView.transform;
                [UIView animateWithDuration:0.1 animations:^{
                    self.slideImageView.transform = CGAffineTransformTranslate(transform, -self.slideImageView.bounds.size.width/4 , 0);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        self.slideImageView.transform = transform;
                    }];
                }];
            }
        }
        if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
            self.slidesFollowVideo = NO;
            [self updateSlide];
        }
        if (sender.direction == UISwipeGestureRecognizerDirectionDown) {
            self.slidesFollowVideo = YES;
            [self updateSlide];
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (!self.slidesFollowVideo) {
            [self seekToSlideWithID:self.currentSlide.ID];
        }
    }
}


@end
