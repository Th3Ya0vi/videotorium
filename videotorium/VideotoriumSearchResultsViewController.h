//
//  VideotoriumSearchResultsViewController.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideotoriumSearchResultsViewController : UITableViewController

@property (nonatomic, copy) NSArray *recordings; // array of VideotoriumRecording objects

@end