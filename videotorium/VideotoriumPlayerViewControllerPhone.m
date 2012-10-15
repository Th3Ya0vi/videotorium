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
@property (weak, nonatomic) IBOutlet UIView *viewForVideoWithNoSlides;
@property (weak, nonatomic) IBOutlet UIView *viewForVideoWithSlides;
@property (weak, nonatomic) IBOutlet UIToolbar *titleBar;
@property (weak, nonatomic) IBOutlet UIToolbar *playbackControlsBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (weak, nonatomic) IBOutlet UISlider *playbackSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentPlaybackTimeLabel;

@property (nonatomic, strong) VideotoriumMoviePlayerViewController *moviePlayer;
@property (nonatomic, strong) VideotoriumSlidePlayerViewController *slidePlayer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;

@property (nonatomic) BOOL titleBarVisible;
@property (nonatomic, strong) NSTimer *titleBarTimer;
@property (nonatomic, strong) UIView *fullscreenDisabler;
@property (nonatomic) BOOL noSlides;

@property (strong, nonatomic) NSTimer *timer;

@property (nonatomic) BOOL wasSliding;

@end

@implementation VideotoriumPlayerViewControllerPhone
@synthesize recordingID = _recordingID;

- (IBAction)donePressed:(id)sender {
    [self.titleBarTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    }];
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
    if ([notification.userInfo objectForKey:@"error"]) {
        [self.activityIndicator stopAnimating];
        [UIView animateWithDuration:0.2 animations:^{
            self.retryButton.alpha = 1;
        }];
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    if (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
        [self changeFirstButtonTo:self.pauseButton];
    } else {
        [self changeFirstButtonTo:self.playButton];
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

    self.titleBarTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(handleTapGesture:) userInfo:nil repeats:NO];
    self.fullscreenDisabler = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    [self.view addSubview:self.fullscreenDisabler];
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
    self.wasSliding = true;
    self.moviePlayer.currentPlaybackTime = self.moviePlayer.duration * sender.value;
}

- (void)adjustFullscreenDisabler {
    if (self.noSlides) {
        self.fullscreenDisabler.frame = CGRectMake(self.view.frame.size.width - 66, self.view.frame.size.height - 44, 66, 44);
    } else {
        self.fullscreenDisabler.frame = CGRectMake(self.view.frame.size.width - 66, self.view.frame.size.height/2 - 44, 66, 44);
    }
}

                                                                                                        
- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    [self.titleBarTimer invalidate];
    if (self.titleBarVisible) {
        self.titleBarVisible = NO;
        [UIView animateWithDuration:0.4 animations:^{
            self.titleBar.alpha = 0;
            self.playbackControlsBar.alpha = 0;
        }];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else {
        self.titleBarVisible = YES;
        [UIView animateWithDuration:0.4 animations:^{
            self.titleBar.alpha = 1;
            self.playbackControlsBar.alpha = 1;
        }];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.titleBarTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(handleTapGesture:) userInfo:nil repeats:NO];
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
                    [self adjustFullscreenDisabler];
                    self.moviePlayerView.frame = self.viewForVideoWithSlides.frame;
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
                    [self adjustFullscreenDisabler];
                    self.moviePlayerView.frame = self.viewForVideoWithNoSlides.frame;
                }
                if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
                    self.moviePlayerView.frame = self.view.bounds;
                }
            }
        });
    });
    dispatch_release(getDetailsQueue);
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        if (self.wasSliding) {
            self.wasSliding = false;
        } else {
            self.playbackSlider.value = self.moviePlayer.currentPlaybackTime / self.moviePlayer.duration;
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        if ([self.recordingDetails.slides count]) {
            self.moviePlayerView.frame = self.viewForVideoWithSlides.frame;
        } else {
            self.moviePlayerView.frame = self.viewForVideoWithNoSlides.frame;
        }
    } else {
        self.moviePlayerView.frame = self.view.bounds;
    }
}

@end
