//
//  VideotoriumRecordingInfoViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.01..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecordingInfoViewController.h"

@interface VideotoriumRecordingInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *presenterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *openInSafariButton;

@end

@implementation VideotoriumRecordingInfoViewController
@synthesize titleLabel = _titleLabel;
@synthesize presenterLabel = _presenterLabel;
@synthesize dateLabel = _dateLabel;
@synthesize descriptionTextView = _descriptionTextView;
@synthesize openInSafariButton = _openInSafariButton;

@synthesize recording = _recording;
@synthesize popoverController = _myPopoverController;

- (void)viewWillLayoutSubviews {
    CGFloat originalSize = self.titleLabel.frame.size.height;
    [self.titleLabel sizeToFit];
    CGFloat offset = self.titleLabel.frame.size.height - originalSize;
    NSRange range = [self.presenterLabel.text rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    if (range.location == NSNotFound) {
        offset -= self.presenterLabel.frame.size.height;
    }
    self.presenterLabel.center = CGPointMake(self.presenterLabel.center.x, self.presenterLabel.center.y + offset);
    self.dateLabel.center = CGPointMake(self.dateLabel.center.x, self.dateLabel.center.y + offset);
    CGRect descriptionFrame = self.descriptionTextView.frame;
    descriptionFrame.size.height -= offset;
    descriptionFrame.origin.y += offset;
    self.descriptionTextView.frame = descriptionFrame;
}

- (void)viewDidLoad {
    [self.openInSafariButton setTitle:NSLocalizedString(@"openInSafari", nil) forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.popoverController.passthroughViews = [NSArray array];
    [self.descriptionTextView flashScrollIndicators];
}

- (void)setRecording:(VideotoriumRecordingDetails *)recording
{
    if (![_recording isEqual:recording]) {
        self.titleLabel.text = recording.title;
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
    [self setTitleLabel:nil];
    [self setOpenInSafariButton:nil];
    [super viewDidUnload];
}

- (IBAction)openInSafari:(id)sender {
    [[UIApplication sharedApplication] openURL:self.recording.URL];
}

@end
