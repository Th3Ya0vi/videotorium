//
//  VideotoriumSlidesTableViewController.m
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.07..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import "VideotoriumSlidesTableViewController.h"
#import "VideotoriumSlideCell.h"

@interface VideotoriumSlidesTableViewController ()

@end

@implementation VideotoriumSlidesTableViewController

@synthesize slides = _slides;
@synthesize resultsOnSlides = _resultsOnSlides;
@synthesize popoverController = _myPopoverController;
@synthesize delegate = _delegate;

- (void)viewDidAppear:(BOOL)animated
{
    self.popoverController.passthroughViews = [NSArray array];
}

- (void)setSlides:(NSArray *)slides
{
    _slides = slides;
    // Reset the resultsOnSlides IDs to avoid having IDs which we don't have slides for
    self.resultsOnSlides = self.resultsOnSlides;
}

- (void)setResultsOnSlides:(NSArray *)resultsOnSlides
{
    // Predicate to filter only those IDs which we actually have in the slides array
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *ID = (NSString *)evaluatedObject;
        NSUInteger index = [self.slides indexOfObjectPassingTest:^BOOL(VideotoriumSlide *slide, NSUInteger idx, BOOL *stop) {
            return ([slide.ID isEqualToString:ID]);
        }];
        return (index != NSNotFound);
    }];
    _resultsOnSlides = [resultsOnSlides filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)scrollToSlide:(VideotoriumSlide *)slide animated:(BOOL)animated
{
    NSUInteger index = [self.slides indexOfObject:slide];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (NSUInteger)slideIndexForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index; 
    if (indexPath.section == 0) {
        NSString *ID = [self.resultsOnSlides objectAtIndex:indexPath.row];
        index = [self.slides indexOfObjectPassingTest:^BOOL(VideotoriumSlide *slide, NSUInteger idx, BOOL *stop) {
            return ([slide.ID isEqualToString:ID]); 
        }];
    } else {
        index = indexPath.row;
    }
    return index;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.resultsOnSlides count] == 0) {
        return nil;
    }
    if (section == 0) {
        return @"Search text found on slides";   
    } else {
        return @"All slides";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.resultsOnSlides count];   
    } else {
        return [self.slides count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideotoriumSlide *slide = [self.slides objectAtIndex:[self slideIndexForIndexPath:indexPath]];

    static NSString *CellIdentifier = @"Slide Cell";
    VideotoriumSlideCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.slideImageView.alpha = 0;
    cell.tag = indexPath.row;
    dispatch_queue_t getSlideThumbnailQueue = dispatch_queue_create("get slide thumbnail", NULL);
    dispatch_async(getSlideThumbnailQueue, ^{
        NSData *imageData = [NSData dataWithContentsOfURL:slide.thumbnailURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Only set the picture if the tag is still the same (it could have been reused since)
            if (cell.tag == indexPath.row) {
                cell.slideImageView.image = [UIImage imageWithData:imageData];
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     cell.slideImageView.alpha = 1;
                                 }];
            }
        });
    });
    dispatch_release(getSlideThumbnailQueue);

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideotoriumSlide *slide = [self.slides objectAtIndex:[self slideIndexForIndexPath:indexPath]];
    [self.delegate userSelectedSlide:slide];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
