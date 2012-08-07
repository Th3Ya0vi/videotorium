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


- (void)setSlides:(NSArray *)slides
{
    _slides = slides;
    [self.tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (void)scrollToSlide:(VideotoriumSlide *)slide animated:(BOOL)animated
{
    NSUInteger index = [self.slides indexOfObject:slide];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.slides count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideotoriumSlide *slide = [self.slides objectAtIndex:indexPath.row];

    static NSString *CellIdentifier = @"Slide Cell";
    VideotoriumSlideCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.slideImageView.alpha = 0;
    cell.tag = indexPath.row;
    dispatch_queue_t getSlideThumbnailQueue = dispatch_queue_create("get slide thumbnail", NULL);
    dispatch_async(getSlideThumbnailQueue, ^{
        NSData *imageData;
        // try to hack a bigger thumbnail
        NSString *URLString = [slide.thumbnailURL absoluteString];
        if ([URLString rangeOfString:@"150x150"].location != NSNotFound) {
            NSString *biggerString = [URLString stringByReplacingOccurrencesOfString:@"150x150" withString:@"400x400"];
            imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:biggerString]];
        }
        if (!imageData) {
            imageData = [NSData dataWithContentsOfURL:slide.thumbnailURL];
        }
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
    VideotoriumSlide *slide = [self.slides objectAtIndex:indexPath.row];
    [self.delegate userSelectedSlide:slide];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
