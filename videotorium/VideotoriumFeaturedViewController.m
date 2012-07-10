//
//  VideotoriumSearchResultsViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumFeaturedViewController.h"
#import "VideotoriumClient.h"
#import "VideotoriumRecording.h"
#import "VideotoriumPlayerViewController.h"
#import "VideotoriumRecordingCell.h"

@interface VideotoriumFeaturedViewController ()

@property (nonatomic, strong) NSArray *recordings; // array of VideotoriumRecording objects
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noRecordingsFoundLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorConnectingLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation VideotoriumFeaturedViewController

@synthesize recordings = _recordings;
@synthesize activityIndicator = _activityIndicator;
@synthesize noRecordingsFoundLabel = _noRecordingsFoundLabel;
@synthesize errorConnectingLabel = _errorConnectingLabel;
@synthesize tableView = _tableView;

- (void)setRecordings:(NSArray *)recordings
{
    if (![_recordings isEqualToArray:recordings]) {
        _recordings = recordings;
        [self.tableView reloadData];
        if ([recordings count]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.recordings) {
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.noRecordingsFoundLabel.alpha = 0;
                             self.errorConnectingLabel.alpha = 0;
                             self.tableView.alpha = 0;
                             self.activityIndicator.alpha = 1;
                         }];
        [self.activityIndicator startAnimating];
        dispatch_queue_t getFeaturedRecordingsQueue = dispatch_queue_create("get search results queue", NULL);
        dispatch_async(getFeaturedRecordingsQueue, ^{
            VideotoriumClient *client = [[VideotoriumClient alloc] init];
            NSError *error;
            NSArray *recordings = [client featuredRecordingsWithError:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.recordings = recordings;
                [self.activityIndicator stopAnimating];
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     if ([recordings count] == 0) {
                                         if (error) {
                                             self.errorConnectingLabel.alpha = 1;
                                         } else {
                                             self.noRecordingsFoundLabel.alpha = 1;
                                         }
                                     } else {
                                         self.tableView.alpha = 1;
                                     }
                                     self.activityIndicator.alpha = 0;
                                 }];
            });
        });
        dispatch_release(getFeaturedRecordingsQueue);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.noRecordingsFoundLabel.alpha = 0;
    self.errorConnectingLabel.alpha = 0;
    self.tableView.alpha = 0;
    self.activityIndicator.alpha = 0;
    
    self.tabBarController.delegate = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.tabBarController.selectedIndex = [defaults integerForKey:kLastSelectedTab];
    
    self.noRecordingsFoundLabel.text = NSLocalizedString(@"noRecordings", nil);
    self.errorConnectingLabel.text = NSLocalizedString(@"errorConnecting", nil);
    self.navigationItem.title = NSLocalizedString(@"featured", nil);
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setActivityIndicator:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNoRecordingsFoundLabel:nil];
    [self setErrorConnectingLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.recordings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"Recording Cell";

    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    CGSize textSize = [recording.title sizeWithFont:[UIFont boldSystemFontOfSize:12]];
    if (textSize.width < 190) {
        CellIdentifier = @"Recording Cell Oneliner";
    }
    
    VideotoriumRecordingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.tag = indexPath.row;
    cell.title.text = recording.title;
    if (recording.presenter) {
        cell.subtitle.text = recording.presenter;
    } else {
        cell.subtitle.text = recording.eventName;
    }
    cell.date.text = recording.dateString;
    cell.indexPicture.alpha = 0;
    dispatch_queue_t getIndexPictureQueue = dispatch_queue_create("get index picture queue", NULL);
    dispatch_async(getIndexPictureQueue, ^{
        NSData *imageData = [NSData dataWithContentsOfURL:recording.indexPictureURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Only set the picture if the recording is still the same (it could have been reused since)
            if (cell.tag == indexPath.row) {
                cell.indexPicture.image = [UIImage imageWithData:imageData];                
                [UIView animateWithDuration:0.2 animations:^{
                    cell.indexPicture.alpha = 1;
                }];
            }
        });
    });
    dispatch_release(getIndexPictureQueue);
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideotoriumPlayerViewController *detailViewController = [[self.splitViewController viewControllers] objectAtIndex:1];
    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    if (![detailViewController.recordingID isEqualToString:recording.ID]) {
        detailViewController.shouldAutoplay = YES;        
        detailViewController.recordingID = recording.ID;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([recording.matchingSlides count] == 0) {
        [detailViewController dismissSplitViewPopover];
    }
}

#pragma mark - Tab bar controller delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:tabBarController.selectedIndex forKey:kLastSelectedTab];
    [defaults synchronize];
}


@end