//
//  VideotoriumSearchResultsViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumSearchViewController.h"
#import "VideotoriumClient.h"
#import "VideotoriumRecording.h"
#import "VideotoriumPlayerViewController.h"
#import "VideotoriumRecordingCell.h"

#define LAST_SEARCH_KEY @"lastSearchString"

@interface VideotoriumSearchViewController ()

@property (nonatomic, strong) NSArray *recordings; // array of VideotoriumRecording objects
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noRecordingsFoundLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorConnectingLabel;

@end

@implementation VideotoriumSearchViewController

@synthesize searchString = _searchString;
@synthesize recordings = _recordings;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize activityIndicator = _activityIndicator;
@synthesize noRecordingsFoundLabel = _noRecordingsFoundLabel;
@synthesize errorConnectingLabel = _errorConnectingLabel;

- (void)setSearchString:(NSString *)searchString
{
    _searchString = searchString;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:searchString forKey:LAST_SEARCH_KEY];
    [defaults synchronize];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.noRecordingsFoundLabel.alpha = 0;
                         self.errorConnectingLabel.alpha = 0;
                         self.tableView.alpha = 0;
                         self.activityIndicator.alpha = 1;
                     }];
    [self.activityIndicator startAnimating];
    dispatch_queue_t getSearchResultsQueue = dispatch_queue_create("get search results queue", NULL);
    dispatch_async(getSearchResultsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        NSError *error;
        NSArray *recordings = [client recordingsMatchingString:searchString error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            // If the searchString hasn't changed while we were networking
            if ([self.searchString isEqualToString:searchString]) {
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
            }
        });
    });
    dispatch_release(getSearchResultsQueue);
}

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.noRecordingsFoundLabel.alpha = 0;
    self.errorConnectingLabel.alpha = 0;
    self.tableView.alpha = 0;
    self.activityIndicator.alpha = 0;
#ifndef SCREENSHOTMODE
    if (!self.searchString) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastSearchString = [defaults stringForKey:LAST_SEARCH_KEY];
        if (lastSearchString) {
            self.searchBar.text = lastSearchString;
            [self searchBarSearchButtonClicked:self.searchBar];
        }
    }
#endif
#ifdef SCREENSHOTMODE
    self.searchBar.placeholder = @"";
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURL:) name:@"openURL" object:nil];
    
    self.noRecordingsFoundLabel.text = NSLocalizedString(@"noRecordings", nil);
    self.errorConnectingLabel.text = NSLocalizedString(@"errorConnecting", nil);
    self.searchBar.placeholder = NSLocalizedString(@"search", nil);
    self.navigationItem.title = NSLocalizedString(@"search", nil);
}

- (void)openURL:(NSNotification *)notification {
    VideotoriumPlayerViewController *detailViewController = [[self.splitViewController viewControllers] lastObject];
    detailViewController.shouldAutoplay = YES;
    detailViewController.recordingID = [notification.userInfo objectForKey:@"recording"];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setSearchBar:nil];
    [self setActivityIndicator:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNoRecordingsFoundLabel:nil];
    [self setErrorConnectingLabel:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier hasPrefix:@"Show matching slides"]) {
        VideotoriumSlidesTableViewController *destination = segue.destinationViewController;
        VideotoriumRecordingCell *cell = sender;
        VideotoriumRecording *recording = [self.recordings objectAtIndex:cell.tag];
        destination.slides = recording.matchingSlides;
        destination.delegate = self;
        destination.navigationItem.title = NSLocalizedString(@"matchingSlides", nil);
    }
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
    CGSize textSize = [recording.title sizeWithFont:[UIFont systemFontOfSize:12]];
    if (textSize.width < 190) {
        CellIdentifier = @"Recording Cell Oneliner";
    }
    if ([recording.matchingSlides count]) {
        CellIdentifier = [CellIdentifier stringByAppendingString:@" With Matching Slides"];
    }
    
    VideotoriumRecordingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.tag = indexPath.row;
    cell.title.text = recording.title;
    cell.event.text = recording.eventName;
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

#pragma mark - Slide table view delegate

- (void)userSelectedSlide:(VideotoriumSlide *)slide
{
    VideotoriumPlayerViewController *detailViewController = [[self.splitViewController viewControllers] objectAtIndex:1];
    [detailViewController seekToSlideWithID:slide.ID];
    [detailViewController dismissSplitViewPopover];
}

#pragma mark - Search bar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([searchBar.text length] >= 3) {
        self.searchString = searchBar.text;
        [searchBar resignFirstResponder];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"queryTooShort", nil) message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

@end
