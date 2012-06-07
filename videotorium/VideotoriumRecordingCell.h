//
//  VideotoriumSearchResultsCell.h
//  videotorium
//
//  Created by Zsombor Nagy on 2012.05.30..
//  Copyright (c) 2012 zsombornagy.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideotoriumRecordingCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *indexPicture;
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *event;
@property (nonatomic, weak) IBOutlet UILabel *date;

@end
