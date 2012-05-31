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

@end

@implementation VideotoriumSearchViewController

@synthesize recordings = _recordings;

- (void)setRecordings:(NSArray *)recordings
{
    if (![_recordings isEqual:recordings]) {
        _recordings = recordings;
        [self.tableView reloadData];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;
    
    dispatch_queue_t getSearchResultsQueue = dispatch_queue_create("get search results queue", NULL);
    dispatch_async(getSearchResultsQueue, ^{
        VideotoriumClient *client = [[VideotoriumClient alloc] init];
        NSArray *recordings = [client recordingsMatchingString:@"networkshop"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordings = recordings;
        });
    });
    dispatch_release(getSearchResultsQueue);
}

- (void)viewDidUnload
{
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
            cell.indexPicture.image = [UIImage imageWithData:imageData];
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
    detailViewController.RecordingID = recording.ID;
}

@end
