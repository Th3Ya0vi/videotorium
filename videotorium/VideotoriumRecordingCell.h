//
//  VideotoriumSearchResultsCell.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideotoriumRecordingCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *indexPicture;
@property (nonatomic, strong) IBOutlet UILabel *title;
@property (nonatomic, strong) IBOutlet UILabel *event;
@property (nonatomic, strong) IBOutlet UILabel *date;

@end
