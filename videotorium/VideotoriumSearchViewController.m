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
#import "VideotoriumSearchResultsCell.h"

@interface VideotoriumSearchViewController ()

@property (nonatomic, strong) NSArray *recordings; // array of VideotoriumRecording objects
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation VideotoriumSearchViewController

@synthesize searchString = _searchString;
@synthesize recordings = _recordings;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;

- (void)setSearchString:(NSString *)searchString
{
    if (![_searchString isEqualToString:searchString]) {
        _searchString = searchString;
        dispatch_queue_t getSearchResultsQueue = dispatch_queue_create("get search results queue", NULL);
        dispatch_async(getSearchResultsQueue, ^{
            VideotoriumClient *client = [[VideotoriumClient alloc] init];
            NSArray *recordings = [client recordingsMatchingString:searchString];
            dispatch_async(dispatch_get_main_queue(), ^{
                // If the searchString hasn't changed while we were networking
                if ([self.searchString isEqualToString:searchString]) {
                    self.recordings = recordings;
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
    
    self.searchBar.text = @"networkshop";
    [self searchBarSearchButtonClicked:self.searchBar];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setSearchBar:nil];
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
    static NSString *CellIdentifier = @"Recording Title And Picture";
    VideotoriumSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
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
    detailViewController.recordingID = recording.ID;
}

#pragma mark - Search bar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchString = searchBar.text;
    [searchBar resignFirstResponder];
}

@end
