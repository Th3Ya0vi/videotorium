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

#define kLastSearchKey @"lastSearchString"

@interface VideotoriumSearchViewController ()

@property (nonatomic, strong) NSArray *recordings; // array of VideotoriumRecording objects
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noRecordingsFoundLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorConnectingLabel;
@property (strong, nonatomic) NSIndexPath *indexPathForTheSelectedRecording;

@end

@implementation VideotoriumSearchViewController

- (void)setSearchString:(NSString *)searchString
{
    _searchString = searchString;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:searchString forKey:kLastSearchKey];
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
        NSString *lastSearchString = [defaults stringForKey:kLastSearchKey];
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
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)openURL:(NSNotification *)notification {
    id <VideotoriumPlayerViewController> playerViewController = [self playerViewController];
    playerViewController.recordingID = [notification.userInfo objectForKey:@"recording"];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show slides"]) {
        VideotoriumSlidesTableViewController *destination = segue.destinationViewController;
        VideotoriumRecordingCell *cell = sender;
        VideotoriumRecording *recording = [self.recordings objectAtIndex:cell.tag];
        destination.slides = recording.matchingSlides;
        destination.delegate = self;
        destination.navigationItem.title = NSLocalizedString(@"matchingSlides", nil);
    }
}

- (id<VideotoriumPlayerViewController>)playerViewController
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [self.splitViewController.viewControllers objectAtIndex:1];
    } else {
        id<VideotoriumPlayerViewController> player = [self.storyboard instantiateViewControllerWithIdentifier:@"player"];
        [self presentViewController:(UIViewController *)player animated:YES completion:^{}];
        return player;
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
    if (![recording.matchingSlides count]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
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
    id <VideotoriumPlayerViewController> playerViewController = [self playerViewController];
    
    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    if (![playerViewController.recordingID isEqualToString:recording.ID]) {
        playerViewController.recordingID = recording.ID;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    self.indexPathForTheSelectedRecording = indexPath;
    [self performSegueWithIdentifier:@"Show slides" sender:cell];
}


#pragma mark - Slide table view delegate

- (void)userSelectedSlide:(VideotoriumSlide *)slide
{
    id <VideotoriumPlayerViewController> playerViewController = [self playerViewController];
    VideotoriumRecording *recording = [self.recordings objectAtIndex:self.indexPathForTheSelectedRecording.row];
    if (![playerViewController.recordingID isEqualToString:recording.ID]) {
        playerViewController.recordingID = recording.ID;
    }   
    [playerViewController seekToSlideWithID:slide.ID];
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
