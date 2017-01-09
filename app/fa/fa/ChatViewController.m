//
//  ChatViewController.m
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "ChatViewController.h"
#import "AppDelegate.h"

@interface ChatViewController ()
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (strong, nonatomic) NSMutableArray *dataArray;
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dataArray = [[NSMutableArray alloc] init];
    [self.dataArray addObjectsFromArray:@[@{ @"message": @"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim.!", @"date": @"10:10 am", @"isMe": @YES },
                                          @{ @"message": @"Everyone needs to look at this answer, because it works. Perhaps clearer documentation is needed for this method and attributed strings in general; it's not obvious where you need to look.", @"date": @"10:10 am", @"isMe": @NO },
                                          @{ @"message": @"Hola 2", @"date": @"10:10 am", @"isMe": @YES }
                                          ]];
    
    [self.table setDataSource:self];
    [self.table setDelegate:self];
    [self.messageInput setDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Keyboard

- (void)moveView:(NSDictionary *)userInfo up:(BOOL)up {
    CGRect keyboardEndFrame;
    UIViewAnimationCurve animationCurve;
    NSTimeInterval animationDuration;
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    int y = keyboardFrame.size.height * (up ? -1 : 1);
    self.view.frame = CGRectOffset(self.view.frame, 0, y);
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self moveView:[notification userInfo] up:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self moveView:[notification userInfo] up:NO];
}

//Touch table view and hide keyboard
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.messageInput isFirstResponder]) {
        [self.messageInput resignFirstResponder];
    }
}

#pragma mark - Text Field

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.messageInput resignFirstResponder];
    return NO;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.dataArray objectAtIndex:indexPath.row];
    BOOL isMe = [[data objectForKey:@"isMe"] boolValue];
    
    if (isMe == YES) {
        ChatCell *cell = (ChatCell *) [self.table dequeueReusableCellWithIdentifier:@"ChatCell"];
        
        cell.message.lineBreakMode = NSLineBreakByWordWrapping;
        cell.message.numberOfLines = 0;
        
        [cell.message setText:[data objectForKey:@"message"]];
        [cell.date setText:[data objectForKey:@"date"]];
        
        return cell;
    } else {
        LeftChatCell *cell = (LeftChatCell *) [self.table dequeueReusableCellWithIdentifier:@"LeftCell"];
        
        cell.message.lineBreakMode = NSLineBreakByWordWrapping;
        cell.message.numberOfLines = 0;
        
        [cell.message setText:[data objectForKey:@"message"]];
        [cell.date setText:[data objectForKey:@"date"]];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.dataArray objectAtIndex:indexPath.row];
    
    NSString *text     = data[@"message"];
    NSString *textDate = data[@"date"];
    
    // typical textLabel.frame = {{10, 30}, {260, 22}}
    const CGFloat TEXT_LABEL_WIDTH = 260;
    CGSize constraint = CGSizeMake(TEXT_LABEL_WIDTH, CGFLOAT_MAX);
    
    CGRect size = [text boundingRectWithSize:constraint
                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                     context:nil];
    
    CGRect sizeDate = [textDate boundingRectWithSize:constraint
                                             options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]}
                                             context:nil];
    
    
    const CGFloat CELL_CONTENT_MARGIN = 22;
    return MAX(CELL_CONTENT_MARGIN + size.size.height + sizeDate.size.height, 64);
}


@end
