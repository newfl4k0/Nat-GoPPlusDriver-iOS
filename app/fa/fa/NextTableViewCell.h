//
//  NextTableViewCell.h
//  fa
//
//  Created by Cristina Avila on 03/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NextTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *mapImage;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
