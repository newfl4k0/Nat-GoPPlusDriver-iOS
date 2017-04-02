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
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIButton *navBackButton;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.dataArray = [[NSMutableArray alloc] init];
    
    [self.table setDataSource:self];
    [self.table setDelegate:self];
    [self.messageInput setDelegate:self];
    
    [self updateChatArray];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self updateChatArray];
    }];
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                                                                            resizingMode:UIImageResizingModeStretch] forBarMetrics:UIBarMetricsDefault];
    
    if (self.isClient == YES) {
        [self.navBackButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    }
}

- (void)updateChatArray {
    if (self.isClient == YES) {
        NSDictionary *parameters = @{
                                     @"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                     @"did": self.did
                                     };
        
        NSLog(@"GET chat cliente %@", parameters);
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"chat-client"]
                   parameters: parameters
                      progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSDictionary *data = (NSDictionary *) responseObject;
                          self.dataArray = [NSMutableArray arrayWithArray:data[@"data"]];
                          [self.table reloadData];
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          NSLog(@"Error %@", error);
                      }];
    } else {
        NSDictionary *parameters = @{@"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]]};
        NSLog(@"GET chat base %@", parameters);
        [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"chat-base"]
                   parameters: parameters
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSDictionary *data = (NSDictionary *) responseObject;
                          self.dataArray = [NSMutableArray arrayWithArray:data[@"data"]];
                          [self.table reloadData];
                      } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          NSLog(@"Error %@", error);
                      }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doToggleMenu:(id)sender {
    if (self.isClient) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else  {
        [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
         toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self.timer invalidate];
    self.timer = nil;
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
    
    if (self.messageInput.text.length >0) {
        if (self.isClient == YES) {
            
            NSDictionary *parameters = @{
                                         @"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                         @"message": self.messageInput.text,
                                         @"did": self.did
                                         };
            
            NSLog(@"Debe enviar chat cliente %@", parameters);
            
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"chat-send-client"]
                        parameters:parameters progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self.table reloadData];
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               NSLog(@"Error %@", error);
                           }];
        } else {
            NSDictionary *parameters = @{
                                         @"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                         @"message": self.messageInput.text
                                         };
            
            NSLog(@"Debe enviar chat base %@", parameters);
            
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"chat-send-base"]
                        parameters:parameters progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self.table reloadData];
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               NSLog(@"Error %@", error);
                           }];
        }
        
        self.messageInput.text = @"";
    }
    
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
    BOOL isMe = [[data objectForKey:@"es_conductor"] boolValue];
    
    if (isMe == YES) {
        ChatCell *cell = (ChatCell *) [self.table dequeueReusableCellWithIdentifier:@"ChatCell"];
        
        cell.message.lineBreakMode = NSLineBreakByWordWrapping;
        cell.message.numberOfLines = 0;
        
        [cell.message setText:[data objectForKey:@"mensaje"]];
        [cell.date setText:[data objectForKey:@"fecha"]];
        
        return cell;
    } else {
        LeftChatCell *cell = (LeftChatCell *) [self.table dequeueReusableCellWithIdentifier:@"LeftCell"];
        
        cell.message.lineBreakMode = NSLineBreakByWordWrapping;
        cell.message.numberOfLines = 0;
        
        [cell.message setText:[data objectForKey:@"mensaje"]];
        [cell.date setText:[data objectForKey:@"fecha"]];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = [self.dataArray objectAtIndex:indexPath.row];
    NSString *text     = data[@"mensaje"];
    NSString *textDate = data[@"fecha"];

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
