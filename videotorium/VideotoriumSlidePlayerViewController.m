//
//  VideotoriumSliderPlayerViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import "VideotoriumSlidePlayerViewController.h"
#import "VideotoriumSlide.h"

@interface VideotoriumSlidePlayerViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *slideImageView;
@property (weak, nonatomic) IBOutlet UIView *slideView;
@property (weak, nonatomic) IBOutlet UIButton *seekToThisSlideButton;
@property (weak, nonatomic) IBOutlet UIButton *followVideoButton;
@property (weak, nonatomic) IBOutlet UILabel *slideNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForSlideWithoutButtons;
@property (weak, nonatomic) IBOutlet UIView *viewForSlideWithVisibleButtons;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) VideotoriumSlide *currentSlide;
@property (nonatomic, strong) VideotoriumSlide *slideToShow;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) BOOL slideIsFullscreen;
@property (nonatomic) BOOL slideZoomingInProgress;

@property (nonatomic) BOOL seekingInProgress;
@property (nonatomic) BOOL slidesFollowVideo;

@property (nonatomic) BOOL userSwipedSlides;

@property (strong, nonatomic) UIView *blackView;

@end

@implementation VideotoriumSlidePlayerViewController

- (void)setGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    _gestureRecognizer = gestureRecognizer;
    [self.slideImageView addGestureRecognizer:gestureRecognizer];
}

- (void)setSlides:(NSArray *)slides
{
    _slides = slides;
    self.slidesFollowVideo = YES;
    self.userSwipedSlides = NO;
    self.seekingInProgress = NO;
    [self slideToNormal];
    self.slideImageView.image = nil;
}

- (void)setFullscreenDisabled:(BOOL)fullscreenDisabled
{
    _fullscreenDisabled = fullscreenDisabled;
    [self slideToNormal];
}

- (void)moviePlayerPlaybackStateDidChange
{
	self.seekingInProgress = NO;
}


- (void)viewDidLoad
{
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
    tapGR.delegate = self;
    if (self.gestureRecognizer) {
        [self.slideImageView addGestureRecognizer:self.gestureRecognizer];
    }
    [self.slideImageView addGestureRecognizer:pinchGR];
    [self.slideImageView addGestureRecognizer:swipeLeftGR];
    [self.slideImageView addGestureRecognizer:swipeRightGR];
    [self.slideImageView addGestureRecognizer:swipeUpGR];
    [self.slideImageView addGestureRecognizer:swipeDownGR];
    [self.slideImageView addGestureRecognizer:tapGR];
    self.seekToThisSlideButton.alpha = 0;
    self.followVideoButton.alpha = 0;
    self.slideNumberLabel.alpha = 0;
    
    [self.followVideoButton setTitle:NSLocalizedString(@"followVideo", nil) forState:UIControlStateNormal];
    [self.seekToThisSlideButton setTitle:NSLocalizedString(@"seekToThisSlide", nil) forState:UIControlStateNormal];

}


- (void)viewDidAppear:(BOOL)animated
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateSlide) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.timer invalidate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)startAnimatingActivityIndicator {
    [self.activityIndicator startAnimating];
}

- (void)seekToSlideWithID:(NSString *)ID
{
    if (self.moviePlayer.loadState == MPMovieLoadStateUnknown) {
        [self performSelector:@selector(seekToSlideWithID:) withObject:ID afterDelay:1];
    } else {
        [self.slides enumerateObjectsUsingBlock:^(VideotoriumSlide *slide, NSUInteger idx, BOOL *stop) {
            if ([slide.ID isEqualToString:ID]) {
                *stop = YES;
                NSTimeInterval seekTime = slide.timestamp;
                if (seekTime > self.moviePlayer.duration - 10) {
                    seekTime = self.moviePlayer.duration - 10;
                }
                self.moviePlayer.currentPlaybackTime = seekTime;
                [self.moviePlayer play];
                self.slideToShow = slide;
                self.seekingInProgress = YES;
                self.slidesFollowVideo = YES;
            }
        }];
    }
}

- (void)updateSlide
{
    NSTimeInterval currentPlaybackTime = self.moviePlayer.currentPlaybackTime;
    if ([self.slides count] > 0) {
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
                NSUInteger index = [self.slides indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    VideotoriumSlide *slide = (VideotoriumSlide *)obj;
                    return (slide.timestamp < currentPlaybackTime);
                }];
                // If there are no slides earlier than the current time, show the first slide anyway
                if (index == NSNotFound) index = 0;
                self.slideToShow = [self.slides objectAtIndex:index];
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
                                 dispatch_queue_t downloadSlideQueue = dispatch_queue_create("download slide queue", NULL);
                                 NSTimer *activityIndicatorStarter = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(startAnimatingActivityIndicator) userInfo:nil repeats:NO];
                                 dispatch_async(downloadSlideQueue, ^{
                                     NSData *imageData = [NSData dataWithContentsOfURL:self.currentSlide.imageURL];
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (self.currentSlide == self.slideToShow) {
                                             self.slideNumberLabel.text = [NSString stringWithFormat:@"%d", [self.slides indexOfObject:self.currentSlide] + 1];
                                             UIImage *newImage = [UIImage imageWithData:imageData];
                                             [activityIndicatorStarter invalidate];
                                             [self.activityIndicator stopAnimating];
                                             if (dissolve) {
                                                 [UIView transitionWithView:self.slideImageView duration:0.2
                                                                    options:UIViewAnimationOptionTransitionCrossDissolve
                                                                 animations:^{
                                                                     self.slideImageView.image = newImage;
                                                                 }
                                                                 completion:^(BOOL finished) {
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
            if (self.currentSlide.timestamp < self.moviePlayer.currentPlaybackTime) {
                self.seekingInProgress = NO;
            }
        }
    }
}



#pragma mark - Handling gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (void)slideToNormal {
    if (self.slideIsFullscreen && !self.slideZoomingInProgress) {
        self.slideZoomingInProgress = YES;
        UIView *rootView = self.view.window.rootViewController.view;
        CGRect originalRectInRootView = [rootView convertRect:self.view.frame fromView:self.view];
        [UIView animateWithDuration:0.3 animations:^{
            self.slideView.frame = originalRectInRootView;
            self.blackView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.view addSubview:self.slideView];
            self.slideView.frame = self.view.bounds;
            [self.blackView removeFromSuperview];
            self.blackView = nil;
            self.slideIsFullscreen = NO;
            self.slideZoomingInProgress = NO;
        }];
    }
}

- (void)slideToFullscreen {
    if (!self.slideIsFullscreen && !self.slideZoomingInProgress && !self.fullscreenDisabled) {
        self.slideZoomingInProgress = YES;
        self.blackView = [[UIView alloc] initWithFrame:CGRectMake(-256, 0, 1280, 1024)];
        self.blackView.backgroundColor = [UIColor blackColor];
        self.blackView.alpha = 0;
        UIView *rootView = self.view.window.rootViewController.view;
        CGRect rectInRootView = [rootView convertRect:self.view.frame fromView:self.view];
        [rootView addSubview:self.blackView];
        [rootView addSubview:self.slideView];
        self.slideView.frame = rectInRootView;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.slideView.frame = rootView.bounds;
                             self.blackView.alpha = 1;
                         } completion:^(BOOL finished) {
                             self.slideIsFullscreen = YES;
                             self.slideZoomingInProgress = NO;
                         }];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if ([self.slides count]) {
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
    if ([self.slides count]) {
        self.seekingInProgress = NO;
        NSUInteger indexOfCurrentSlide = [self.slides indexOfObject:self.currentSlide];
        if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
            self.userSwipedSlides = YES;
            if (indexOfCurrentSlide > 0) {
                self.slidesFollowVideo = NO;
                self.slideToShow = [self.slides objectAtIndex:(indexOfCurrentSlide - 1)];
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
            if (indexOfCurrentSlide < [self.slides count] - 1) {
                self.slidesFollowVideo = NO;
                self.slideToShow = [self.slides objectAtIndex:(indexOfCurrentSlide + 1)];
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


- (void)viewDidUnload {
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
@end
