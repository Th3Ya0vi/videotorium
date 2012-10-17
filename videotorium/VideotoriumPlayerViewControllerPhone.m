//
//  VideotoriumPlayerViewControllerPhoneViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.08.06..
//
//

#import "VideotoriumPlayerViewControllerPhone.h"
#import "VideotoriumMoviePlayerViewController.h"
#import "VideotoriumSlidePlayerViewController.h"
#import "VideotoriumClient.h"

@interface VideotoriumPlayerViewControllerPhone ()

@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UIToolbar *titleBar;
@property (weak, nonatomic) IBOutlet UIToolbar *playbackControlsBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (weak, nonatomic) IBOutlet UISlider *playbackSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentPlaybackTimeLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property(nonatomic) CGPoint lastScrollViewOffset;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;

@property (nonatomic, strong) VideotoriumMoviePlayerViewController *moviePlayer;
@property (nonatomic, strong) VideotoriumSlidePlayerViewController *slidePlayer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;

@property (nonatomic) BOOL titleBarVisible;
@property (nonatomic, strong) NSTimer *titleBarTimer;
@property (nonatomic) BOOL noSlides;

@property (strong, nonatomic) NSTimer *timer;

@property (nonatomic) BOOL isSliding;

@end

@implementation VideotoriumPlayerViewControllerPhone
@synthesize recordingID = _recordingID;

- (IBAction)actionButtonPressed:(id)sender {
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[self.recordingDetails.URL] applicationActivities:nil];
    [avc setCompletionHandler:(UIActivityViewControllerCompletionHandler)^{
        [self scheduleTitleBarTimer];
        [self layoutViewsInOrientation:self.interfaceOrientation];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    }];
    [self.titleBarTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self presentViewController:avc animated:YES completion:nil];
}

- (IBAction)donePressed:(id)sender {
    [self.titleBarTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if (self.moviePlayer.loadState == MPMovieLoadStatePlayable) {
        [self.activityIndicator stopAnimating];
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.moviePlayerView.alpha = 1;
                         }];
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
    [self.titleBarTimer invalidate];
    [self showBars];
    if ([notification.userInfo objectForKey:@"error"]) {
        [self.activityIndicator stopAnimating];
        [UIView animateWithDuration:0.2 animations:^{
            self.retryButton.alpha = 1;
        }];
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    if (!self.isSliding) {
        if (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            [self changeFirstButtonTo:self.pauseButton];
        } else {
            [self changeFirstButtonTo:self.playButton];
        }        
    }
    [self.slidePlayer moviePlayerPlaybackStateDidChange];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    self.retryButton.alpha = 0;
    
    [self.retryButton setTitle:NSLocalizedString(@"failedToLoadRetry", nil) forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    self.titleBarVisible = YES;
    UIImage *image = [UIImage imageNamed:@"thumb.png"];
    [self.playbackSlider setThumbImage:image forState:UIControlStateNormal];
    NSMutableArray *items = [self.playbackControlsBar.items mutableCopy];
    [items removeObjectAtIndex:1]; // Remove pause button
    self.playbackControlsBar.items = items;
    [self scheduleTitleBarTimer];
    if (![UIActivityViewController class]) {
        items = [self.titleBar.items mutableCopy];
        [items removeObject:self.actionButton];
        self.titleBar.items = items;
    }
}

- (void)changeFirstButtonTo:(UIBarButtonItem *)button {
    NSMutableArray *items = [self.playbackControlsBar.items mutableCopy];
    [items removeObjectAtIndex:0];
    [items insertObject:button atIndex:0];
    self.playbackControlsBar.items = items;
}

- (IBAction)playButtonPressed:(id)sender {
    [self.moviePlayer play];
}
- (IBAction)pauseButtonPressed:(id)sender {
    [self.moviePlayer pause];
}
- (IBAction)sliderChanged:(UISlider *)sender {
    self.moviePlayer.currentPlaybackTime = self.moviePlayer.duration * sender.value;
}

- (IBAction)sliderTouchDown:(id)sender {
    [self.titleBarTimer invalidate];
    self.isSliding = true;
}
- (IBAction)sliderTouchUp:(id)sender {
    [self scheduleTitleBarTimer];
    self.isSliding = false;
}


- (void)scheduleTitleBarTimer {
    self.titleBarTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(handleTapGesture:) userInfo:nil repeats:NO];
}

- (void)hideBars {
    self.titleBarVisible = NO;
    [UIView animateWithDuration:0.4 animations:^{
        self.titleBar.alpha = 0;
        self.playbackControlsBar.alpha = 0;
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)showBars {
    self.titleBarVisible = YES;
    [UIView animateWithDuration:0.4 animations:^{
        self.titleBar.alpha = 1;
        self.playbackControlsBar.alpha = 1;
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    [self.titleBarTimer invalidate];
    if (self.titleBarVisible) {
        [self hideBars];
    } else {
        [self showBars];
        [self scheduleTitleBarTimer];
    }
}

- (void)seekToSlideWithID:(NSString *)ID
{
    [self.slidePlayer seekToSlideWithID:ID];
}

- (void)setRecordingID:(NSString *)recordingID
{
    [self setRecordingID:recordingID autoplay:YES];
}

- (void)layoutViewsInOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([self.recordingDetails.slides count]) {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height * 2);
            self.scrollView.scrollEnabled = YES;
            self.moviePlayerView.frame = self.view.bounds;
            self.slideContainerView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
            if (self.lastScrollViewOffset.y >= self.view.bounds.size.height / 2)
	            self.scrollView.contentOffset = CGPointMake(0, self.view.bounds.size.height);
        } else {
            self.lastScrollViewOffset = self.scrollView.contentOffset;
            self.scrollView.contentSize = self.view.bounds.size;
            self.scrollView.scrollEnabled = NO;
            self.moviePlayerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/2);
            self.slideContainerView.frame = CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, self.view.bounds.size.height/2);
        }
    } else {
        self.scrollView.contentSize = self.view.bounds.size;
        self.scrollView.scrollEnabled = NO;
        self.moviePlayerView.frame = self.view.bounds;
    }
}

- (void)setRecordingID:(NSString *)recordingID autoplay:(BOOL)shouldAutoplay
{
    
    _recordingID = recordingID;
    
    self.retryButton.alpha = 0;
    if (self.moviePlayer != nil) {
        [self.moviePlayer stop];
        [self.moviePlayer.view removeFromSuperview];
        [self.moviePlayer removeFromParentViewController];
        self.moviePlayer = nil;
    }
    if (self.slidePlayer != nil) {
        [self.slidePlayer.view removeFromSuperview];
        [self.slidePlayer removeFromParentViewController];
        self.slidePlayer = nil;
    }
    [self.activityIndicator startAnimating];
    self.recordingDetails = nil;
        
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
                self.moviePlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"moviePlayer"];
                self.moviePlayer.streamURL = self.recordingDetails.streamURL;
                [self.moviePlayer turnOffControls];
                self.moviePlayer.view.frame = self.moviePlayerView.bounds;
                self.moviePlayerView.alpha = 0;
                [self addChildViewController:self.moviePlayer];
                [self.moviePlayerView addSubview:self.moviePlayer.view];
                self.moviePlayer.shouldAutoplay = shouldAutoplay;
                [self.moviePlayer prepareToPlay];
                self.moviePlayer.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];;

                if ([self.recordingDetails.slides count]) {
                    self.noSlides = NO;
                    self.slidePlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"slidePlayer"];
                    self.slidePlayer.fullscreenDisabled = YES;
                    self.slidePlayer.slides = self.recordingDetails.slides;
                    self.slidePlayer.moviePlayer = self.moviePlayer;
                    [self addChildViewController:self.slidePlayer];
                    self.slidePlayer.view.frame = self.slideContainerView.bounds;
                    [self.slideContainerView addSubview:self.slidePlayer.view];
                    self.slidePlayer.gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];;
                } else {
                    self.noSlides = YES;
                }
                [self layoutViewsInOrientation:self.interfaceOrientation];
            }
        });
    });
    dispatch_release(getDetailsQueue);
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setScrollView:nil];
    [self setActionButton:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.timer invalidate];
}

- (void)updateSlider {
    if (self.moviePlayer && (self.moviePlayer.duration > 0)) {
        int minutes = floor(self.moviePlayer.currentPlaybackTime / 60);
        int seconds = floor(self.moviePlayer.currentPlaybackTime) - minutes * 60;
        self.currentPlaybackTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
        if (!self.isSliding) {
            self.playbackSlider.value = self.moviePlayer.currentPlaybackTime / self.moviePlayer.duration;
            
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutViewsInOrientation:toInterfaceOrientation];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Info"]) {
        VideotoriumRecordingInfoViewController *destination = segue.destinationViewController;
        destination.recording = self.recordingDetails;
        destination.delegate = self;
        [self.titleBarTimer invalidate];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
}

- (void)userPressedDoneButton {
    [self dismissModalViewControllerAnimated:YES];
    [self scheduleTitleBarTimer];
    [self layoutViewsInOrientation:self.interfaceOrientation];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
}

- (void)userSelectedRecordingWithURL:(NSURL *)recordingURL {
    [self dismissModalViewControllerAnimated:YES];
    self.recordingID = [VideotoriumClient IDOfRecordingWithURL:recordingURL];
    [self scheduleTitleBarTimer];
    [self layoutViewsInOrientation:self.interfaceOrientation];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
}

@end
