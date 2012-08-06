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

- (void)viewDidLoad {
    [self.openInSafariButton setTitle:NSLocalizedString(@"openInSafari", nil) forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.infoPopoverController.passthroughViews = [NSArray array];
}

- (void)setRecording:(VideotoriumRecordingDetails *)recording
{
    if (![_recording isEqual:recording]) {
        self.webView.scalesPageToFit = YES;
        self.webView.delegate = self;
        NSString *strippedHTML = recording.response;
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<body>" withString:@"<body style=\"background-image: none\">"];
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"header\">" withString:@"<div id=\"header\" style=\"display: none\">"];
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"menu\">" withString:@"<div id=\"menu\" style=\"display: none\">"];
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div class=\"player\">" withString:@"<div class=\"player\" style=\"display: none\">"];
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"footer\">" withString:@"<div id=\"footer\" style=\"display: none\">"];
        strippedHTML = [strippedHTML stringByReplacingOccurrencesOfString:@"<div id=\"footerbg\">" withString:@"<div id=\"footerbg\" style=\"display: none\">"];
        [self.webView loadHTMLString:strippedHTML baseURL:recording.URL];
        _recording = recording;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [self setOpenInSafariButton:nil];
    [self setWebView:nil];
    [self setActivityIndicator:nil];
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
        [self.delegate userSelectedRecordingWithURL:request.URL];
    }
    return NO;
}

@end
