//
//  VideotoriumViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumPlayerViewControllerPad.h"
#import "VideotoriumClient.h"
#import "VideotoriumMoviePlayerViewController.h"
#import "VideotoriumSlidePlayerViewController.h"
#import <QuartzCore/QuartzCore.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPMediaItem.h>


@interface VideotoriumPlayerViewControllerPad ()

@property (weak, nonatomic) IBOutlet UIView *moviePlayerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UIView *introductoryTextContainerView;
@property (weak, nonatomic) IBOutlet UILabel *introductoryTextLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForVideoWithNoSlides;
@property (weak, nonatomic) IBOutlet UIView *viewForVideoWithSlides;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;

@property (strong, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) UIPopoverController *splitViewPopoverController;

@property (nonatomic, strong) VideotoriumMoviePlayerViewController *moviePlayer;
@property (nonatomic, strong) VideotoriumSlidePlayerViewController *slidePlayer;

@property (nonatomic, strong) VideotoriumRecordingDetails *recordingDetails;

@property (weak, nonatomic) UIPopoverController *infoPopoverController;
@property (strong, nonatomic) UIPopoverController *actionPopover;

@end

@implementation VideotoriumPlayerViewControllerPad

@synthesize recordingID = _recordingID;

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender {
    if (self.actionPopover.popoverVisible) {
        [self.actionPopover dismissPopoverAnimated:YES];
    } else {
        NSMutableArray *activityItems = [NSMutableArray arrayWithArray:@[self.recordingDetails.title, self.recordingDetails.URL]];
        if (self.recordingDetails.indexPicture) {
            [activityItems addObject:self.recordingDetails.indexPicture];
        }
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        avc.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint];
        self.actionPopover = [[UIPopoverController alloc] initWithContentViewController:avc];
        [self.actionPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

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
    [self.slidePlayer moviePlayerPlaybackStateDidChange];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.splitViewController.delegate = self;
    if ([self.splitViewController respondsToSelector:@selector(setPresentsWithGesture:)]) {
        self.splitViewController.presentsWithGesture = NO;        
    }
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
    self.introductoryTextContainerView.alpha = 0;

#ifdef SCREENSHOTMODE
    self.introductoryTextContainerView = nil;
    self.titleLabel.text = @"";
#endif
    
    
    [self.retryButton setTitle:NSLocalizedString(@"failedToLoadRetry", nil) forState:UIControlStateNormal];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextLandscape", nil);
    } else {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextPortrait", nil);
    }
    
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    if (![UIActivityViewController class]) {
        [toolbarItems removeObject:self.actionButton];
    }
    self.toolbar.items = toolbarItems;
}

- (void)seekToSlideWithID:(NSString *)ID
{
    if (self.slidePlayer) {
        [self.slidePlayer seekToSlideWithID:ID];
        [self.splitViewPopoverController dismissPopoverAnimated:YES];
        [self.actionPopover dismissPopoverAnimated:YES];
    } else {
        [self performSelector:@selector(seekToSlideWithID:) withObject:ID afterDelay:0.5];
    }
}

- (void)seekToPosition:(NSNumber *)position
{
    if (self.moviePlayer.loadState == MPMovieLoadStateUnknown) {
        [self performSelector:@selector(seekToPosition:) withObject:position afterDelay:0.5];
    } else {
        self.moviePlayer.currentPlaybackTime = [position floatValue];
    }
}

- (void)setRecordingID:(NSString *)recordingID
{
    [self setRecordingID:recordingID autoplay:YES];
}

- (void)setRecordingID:(NSString *)recordingID autoplay:(BOOL)shouldAutoplay
{

    _recordingID = recordingID;
    
    self.titleLabel.text = @"";
    self.infoButton.enabled = NO;
    self.actionButton.enabled = NO;
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
    [self.infoPopoverController dismissPopoverAnimated:YES];
    [self.actionPopover dismissPopoverAnimated:YES];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.introductoryTextContainerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.introductoryTextContainerView removeFromSuperview];
        self.introductoryTextContainerView = nil;
        self.introductoryTextLabel = nil;
    }];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:recordingID forKey:kLastRecordingID];
    [defaults synchronize];
    
    dispatch_queue_t getDetailsQueue = dispatch_queue_create("get details queue", NULL);
    dispatch_async(getDetailsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        NSError *error;
        VideotoriumRecordingDetails *recordingDetails = [client detailsWithID:recordingID error:&error];
        dispatch_queue_t getIndexPictureQueue = dispatch_queue_create("get index picture", NULL);
        dispatch_async(getIndexPictureQueue, ^{
            NSData *imageData = [NSData dataWithContentsOfURL:recordingDetails.indexPictureURL];
            if (imageData) {
	            recordingDetails.indexPicture = [UIImage imageWithData:imageData];
            };
        });
        dispatch_release(getIndexPictureQueue);
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
                self.titleLabel.text = self.recordingDetails.title;
                self.moviePlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"moviePlayer"];
                self.moviePlayer.streamURL = self.recordingDetails.streamURL;
                self.moviePlayer.view.frame = self.moviePlayerView.bounds;
                self.moviePlayerView.alpha = 0;
                [self addChildViewController:self.moviePlayer];
                [self.moviePlayerView addSubview:self.moviePlayer.view];
                self.moviePlayer.shouldAutoplay = shouldAutoplay;
                [self.moviePlayer prepareToPlay];
                self.infoButton.enabled = YES;
                self.actionButton.enabled = YES;
                if ([self.recordingDetails.slides count]) {
                    self.moviePlayerView.frame = self.viewForVideoWithSlides.frame;
                    self.slidePlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"slidePlayer"];
                    self.slidePlayer.slides = self.recordingDetails.slides;
                    self.slidePlayer.moviePlayer = self.moviePlayer;
                    [self addChildViewController:self.slidePlayer];
                    self.slidePlayer.view.frame = self.slideContainerView.bounds;
                    [self.slideContainerView addSubview:self.slidePlayer.view];
                } else {
                    self.moviePlayerView.frame = self.viewForVideoWithNoSlides.frame;
                }
                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                NSError *setCategoryError = nil;
                BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
                if (!success) { NSLog(@"%@", setCategoryError); }
                [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                NSDictionary *songInfo = @{
                    MPMediaItemPropertyTitle: recordingDetails.title,
                    MPMediaItemPropertyArtist: recordingDetails.presenter,
                    MPMediaItemPropertyArtwork: [[MPMediaItemArtwork alloc] initWithImage: [UIImage imageNamed:@"videotorium-albumart"]]
                };
                center.nowPlayingInfo = songInfo;

            }
        });
    });
    dispatch_release(getDetailsQueue);
    [self.splitViewPopoverController dismissPopoverAnimated:YES];
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

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextLandscape", nil);
    } else {
        self.introductoryTextLabel.text = NSLocalizedString(@"introductoryTextPortrait", nil);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.infoPopoverController) {
        // dismiss and recreate the info popover, otherwise it screws up the passthrough views
        [self.infoPopoverController dismissPopoverAnimated:YES];
        [self performSegueWithIdentifier:@"Info Popover" sender:self.infoButton];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Fix the frames of the video and the slide container views to occupy exactly half of the available area
    CGRect area = self.viewForVideoWithNoSlides.frame;
    self.viewForVideoWithSlides.frame = CGRectMake(area.origin.x, area.origin.y, area.size.width, area.size.height/2);
    self.slideContainerView.frame = CGRectMake(area.origin.x, area.origin.y + area.size.height/2, area.size.width, area.size.height/2);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Info Popover"]) {
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        VideotoriumRecordingInfoViewController *destination = popoverSegue.destinationViewController;
        self.infoPopoverController = popoverSegue.popoverController;
        destination.recording = self.recordingDetails;
        destination.infoPopoverController = self.infoPopoverController;
        destination.delegate = self;
        [self.actionPopover dismissPopoverAnimated:YES];
    }
}

- (IBAction)retryButtonPressed:(id)sender {
    self.recordingID = self.recordingID;
}

#pragma mark - Videotorium recording info view delegate

-(void)userSelectedRecordingWithURL:(NSURL *)recordingURL {
    [self.infoPopoverController dismissPopoverAnimated:YES];
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

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeRemoteControlPlay) {
        [self.moviePlayer play];
    }
    if (event.subtype == UIEventSubtypeRemoteControlPause) {
        [self.moviePlayer pause];
    }
    if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
        if (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
	        [self.moviePlayer pause];
        } else {
            [self.moviePlayer play];
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


@end
