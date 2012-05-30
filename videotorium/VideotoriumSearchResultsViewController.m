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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    
    cell.textLabel.text = [[self.recordings objectAtIndex:indexPath.row] title];
    return cell;
}

@end
