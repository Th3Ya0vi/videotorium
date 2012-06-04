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

@end

@implementation VideotoriumSearchViewController

@synthesize searchString = _searchString;
@synthesize recordings = _recordings;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize activityIndicator = _activityIndicator;

- (void)setSearchString:(NSString *)searchString
{
    if (![_searchString isEqualToString:searchString]) {
        _searchString = searchString;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:searchString forKey:LAST_SEARCH_KEY];
        [defaults synchronize];

        self.recordings = [NSArray array];
        [self.activityIndicator startAnimating];
        dispatch_queue_t getSearchResultsQueue = dispatch_queue_create("get search results queue", NULL);
        dispatch_async(getSearchResultsQueue, ^{
            VideotoriumClient *client = [[VideotoriumClient alloc] init];
            NSArray *recordings = [client recordingsMatchingString:searchString];
            dispatch_async(dispatch_get_main_queue(), ^{
                // If the searchString hasn't changed while we were networking
                if ([self.searchString isEqualToString:searchString]) {
                    self.recordings = recordings;
                    [self.activityIndicator stopAnimating];
                    if ([recordings count] == 0) {
                        [defaults removeObjectForKey:LAST_SEARCH_KEY];
                        [defaults synchronize];
                        NSString *message = [NSString stringWithFormat:@"No results for '%@'.", searchString];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No recordings found"
                                                                        message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        
                    }
                }
            });
        });
        dispatch_release(getSearchResultsQueue);
    }
}

- (void)setRecordings:(NSArray *)recordings
{
    if (![_recordings isEqualToArray:recordings]) {
        _recordings = recordings;
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURL:) name:@"openURL" object:nil];
}

- (void)openURL:(NSNotification *)notification {
    VideotoriumPlayerViewController *detailViewController = [[self.splitViewController viewControllers] lastObject];
    detailViewController.shouldAutoplay = YES;
    detailViewController.recordingID = [notification.userInfo objectForKey:@"recording"];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setSearchBar:nil];
    [self setActivityIndicator:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    static NSString *CellIdentifier = @"Recording Cell";
    VideotoriumRecordingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    cell.title.text = recording.title;
    cell.indexPicture.image = [UIImage imageNamed:@"videotorium_logo.png"];
    dispatch_queue_t getIndexPictureQueue = dispatch_queue_create("get index picture queue", NULL);
    dispatch_async(getIndexPictureQueue, ^{
        NSData *imageData = [NSData dataWithContentsOfURL:recording.indexPictureURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Only set the picture if the text is still the same (it could have been reused since)
            if ([cell.title.text isEqualToString:recording.title]) {
                cell.indexPicture.image = [UIImage imageWithData:imageData];                
            }
        });
    });
    dispatch_release(getIndexPictureQueue);
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideotoriumPlayerViewController *detailViewController = [[self.splitViewController viewControllers] lastObject];
    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    detailViewController.shouldAutoplay = YES;
    detailViewController.recordingID = recording.ID;
}

#pragma mark - Search bar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchString = searchBar.text;
    [searchBar resignFirstResponder];
}

@end
