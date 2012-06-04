//
//  VideotoriumRecordingInfoViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.01..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecordingInfoViewController.h"

@interface VideotoriumRecordingInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *presenterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@end

@implementation VideotoriumRecordingInfoViewController
@synthesize presenterLabel = _presenterLabel;
@synthesize dateLabel = _dateLabel;
@synthesize descriptionTextView = _descriptionTextView;

@synthesize recording = _recording;
@synthesize popoverController = _myPopoverController;

- (void)viewDidAppear:(BOOL)animated
{
    self.popoverController.passthroughViews = [NSArray array];
    [self.descriptionTextView flashScrollIndicators];
}

- (void)setRecording:(VideotoriumRecordingDetails *)recording
{
    if (![_recording isEqual:recording]) {
        self.presenterLabel.text = recording.presenter;
        self.dateLabel.text = recording.dateString;
        self.descriptionTextView.text = recording.descriptionText;
        _recording = recording;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [self setPresenterLabel:nil];
    [self setDateLabel:nil];
    [self setDescriptionTextView:nil];
    [super viewDidUnload];
}

- (IBAction)openInSafari:(id)sender {
    [[UIApplication sharedApplication] openURL:self.recording.URL];
}

@end
