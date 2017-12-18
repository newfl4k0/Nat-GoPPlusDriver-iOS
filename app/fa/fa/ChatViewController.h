//
//  ChatViewController.h
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "ViewController.h"
#import "ChatCell.h"
#import "LeftChatCell.h"

@interface ChatViewController : ViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic) BOOL isClient;
@property (strong, nonatomic) NSNumber *did;
@property (strong, nonatomic) NSString *phone;
@end
