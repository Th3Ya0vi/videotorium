//
//  VideotoriumSearchResultsViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideotoriumSlidesTableViewController.h"

@interface VideotoriumSearchViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, VideotoriumSlidesTableDelegate>

@property (nonatomic, copy) NSString *searchString;

@end
