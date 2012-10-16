//
//  VideotoriumRecordingInfoViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.01..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumRecordingInfoViewController.h"

@interface VideotoriumRecordingInfoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *openInSafariButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation VideotoriumRecordingInfoViewController

- (IBAction)doneButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userPressedDoneButton)]) {
        [self.delegate userPressedDoneButton];
    }
}

- (void)viewDidLoad {
    [self.openInSafariButton setTitle:NSLocalizedString(@"openInSafari", nil) forState:UIControlStateNormal];
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.infoPopoverController.passthroughViews = [NSArray array];
    [self showRecordingInWebView];
}

- (void)showRecordingInWebView {
    NSString *strippedHTML = self.recording.response;
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<body>" withString:@"<body style=\"background-image: none\">"];
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"header\">" withString:@"<div id=\"header\" style=\"display: none\">"];
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"menu\">" withString:@"<div id=\"menu\" style=\"display: none\">"];
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div class=\"player\">" withString:@"<div class=\"player\" style=\"display: none\">"];
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"footer\">" withString:@"<div id=\"footer\" style=\"display: none\">"];
    strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"footerbg\">" withString:@"<div id=\"footerbg\" style=\"display: none\">"];
    [self.webView loadHTMLString:strippedHTML baseURL:self.recording.URL];
}

- (void)setRecording:(VideotoriumRecordingDetails *)recording
{
    if (![_recording isEqual:recording]) {
        _recording = recording;
        [self showRecordingInWebView];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (IBAction)openInSafari:(id)sender {
    [[UIApplication sharedApplication] openURL:self.recording.URL];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL isEqual:self.recording.URL]) {
        return YES;
    }
    if ([[request.URL absoluteString] hasPrefix:@"http://videotorium.hu/hu/recordings/details/"]) {
        if ([self.delegate respondsToSelector:@selector(userSelectedRecordingWithURL:)]) {
            [self.delegate userSelectedRecordingWithURL:request.URL];            
        }
    }
    return NO;
}

@end
