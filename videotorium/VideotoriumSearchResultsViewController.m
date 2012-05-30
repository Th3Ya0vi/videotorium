//
//  VideotoriumSearchResultsViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumSearchResultsViewController.h"
#import "VideotoriumClient.h"
#import "VideotoriumRecording.h"
#import "VideotoriumPlayerViewController.h"

@interface VideotoriumSearchResultsViewController ()

@end

@implementation VideotoriumSearchResultsViewController

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
    
    VideotoriumClient *client = [[VideotoriumClient alloc] init];
    NSArray *recordings = [client recordingsMatchingString:@"cucc"];
    self.recordings = recordings;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    VideotoriumRecording *recording = [self.recordings objectAtIndex:indexPath.row];
    cell.textLabel.text = recording.title;
    NSData *imageData = [NSData dataWithContentsOfURL:recording.indexPictureURL];
    cell.imageView.image = [UIImage imageWithData:imageData];

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
