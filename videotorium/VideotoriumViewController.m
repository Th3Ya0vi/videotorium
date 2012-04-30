//
//  VideotoriumViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.04.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumViewController.h"
#import "VideotoriumClient.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VideotoriumViewController ()

@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;
@end

@implementation VideotoriumViewController

@synthesize moviePlayerViewController = _moviePlayerViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
}
- (IBAction)presentMovie {
    VideotoriumClient *client = [[VideotoriumClient alloc] init];
    VideotoriumRecording *recording = [client recordingWithID:@"2487"];
    self.moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:recording.streamURL];
    [self presentMoviePlayerViewControllerAnimated:self.moviePlayerViewController];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
