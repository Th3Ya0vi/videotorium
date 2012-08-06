//
//  VideotoriumSlidesTableViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.06.07..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideotoriumSlide.h"

@protocol VideotoriumSlidesTableDelegate <NSObject>

- (void)userSelectedSlide:(VideotoriumSlide *)slide;

@end


@interface VideotoriumSlidesTableViewController : UITableViewController

@property (copy, nonatomic) NSArray *slides; // array of VideotoriumSlide objects
@property (weak, nonatomic) id <VideotoriumSlidesTableDelegate> delegate;

- (void)scrollToSlide:(VideotoriumSlide *)slide animated:(BOOL)animated;

@end
