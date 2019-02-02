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
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIButton *navBackButton;
@property (weak, nonatomic) UIImage *clientImage;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (strong, nonatomic) NSDictionary *clientData;
@property (nonatomic) BOOL shouldUpdate;
@property int keyboardsize;
@property int last_keyboardsize;
@property BOOL alreadyHidden;
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.dataArray = [[NSMutableArray alloc] init];
    self.shouldUpdate = YES;
    self.keyboardsize = 0;
    self.last_keyboardsize = 0;
    self.alreadyHidden = NO;
    
    [self.table setDataSource:self];
    [self.table setDelegate:self];
    [self.messageInput setDelegate:self];
    [self updateChatArray];
    [self addKeyBoardToolbar:self.messageInput];
    
    [self.navigationBar setBackgroundImage:[[UIImage imageNamed:@"bgnavbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch] forBarMetrics:UIBarMetricsDefault];

    if (self.isClient == YES) {
        [self.navBackButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
        self.clientImage = [UIImage imageNamed:@"avatar.png"];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.shouldUpdate = NO;
}

- (void)closeView: (NSNotification *) notification {
    [self.navBackButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)updateChatArray {
    if (self.shouldUpdate) {
        if (self.isClient == YES) {
            NSDictionary *parameters = @{
                                         @"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                         @"did": self.did
                                         };
            
            [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"chat-client"]
                       parameters: parameters
                          progress:nil
                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                              NSDictionary *data = (NSDictionary *) responseObject;
                              self.dataArray = [NSMutableArray arrayWithArray:data[@"data"]];
                              
                              if ([data objectForKey:@"clientData"] != nil) {
                                  self.clientData = [data objectForKey:@"clientData"];
                              }
                              
                              [self.table reloadData];
                              
                              if (self.dataArray.count > 0) {
                                  [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                              }
                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                              NSLog(@"Error %@", error);
                          }];
        } else {
            NSDictionary *parameters = @{@"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]]};
            [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"chat-base"]
                       parameters: parameters
                         progress:nil
                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                              NSDictionary *data = (NSDictionary *) responseObject;
                              self.dataArray = [NSMutableArray arrayWithArray:data[@"data"]];
                              [self.table reloadData];
                              
                              if (self.dataArray.count > 0) {
                                  [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                              }
                              
                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                              NSLog(@"Error %@", error);
                          }];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self updateChatArray];
        });
    }
}


- (IBAction)doCall:(id)sender {
    if (self.isClient) {
        
        if (self.phone != nil && [self.phone isEqualToString:@""] == NO) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel:" stringByAppendingString:self.phone]]];
        } else {
            if (self.clientData != nil) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel:" stringByAppendingString: [self.clientData objectForKey:@"phone"]]]];
            }
        }
    } else {
        NSArray *data = [self.app.dataLibrary getArray:@"settings"];
        
        for (NSDictionary *key in data) {
            if ([[key objectForKey:@"k"] isEqualToString:@"telefonoBase"]) {
                NSString *phoneNumber = @"tel:";
                phoneNumber = [phoneNumber stringByAppendingString: [key objectForKey:@"v"]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
                
                break; //Force and close loop
            }
        }
    }
}


- (IBAction)doToggleMenu:(id)sender {
    [self hideKeyboard];
    
    if (self.isClient) {
        self.shouldUpdate = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    } else  {
        [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
         toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
}

#pragma mark - Keyboard

- (void)hideKeyboard {
    if ([self.messageInput isFirstResponder]) {
        [self.messageInput resignFirstResponder];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self animateTextField:textField up:YES];
    });
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:textField up:NO];
}

-(void)animateTextField:(UITextField*)textField up:(BOOL)up {
    
    int movementDistance = -300;
    
    if (self.keyboardsize != 0) {
        movementDistance = self.keyboardsize * -1;
    }
    
    int movement = (up ? movementDistance : -movementDistance);
    
    if (up) {
        self.last_keyboardsize = movement;
    } else {
        if (self.last_keyboardsize != 0) {
            movement = self.last_keyboardsize * -1;
        }
        
        self.last_keyboardsize = 0;
    }
    
    [self setViewPosition:movement];
}

- (void)setViewPosition:(int) movement {
    const float movementDuration = 0.3f;
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)logNotification:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    int height = MIN(keyboardSize.height,keyboardSize.width);
    
    if (height != 0) {
        self.keyboardsize = height;
        
        int new_height = height;
        int last_height = self.last_keyboardsize * -1;
        
        if (self.last_keyboardsize!=0 && (last_height != new_height)) {
            int diff = new_height - last_height;

            if (diff > 0) {
                self.last_keyboardsize = (last_height + diff) * -1;
            } else {
                self.last_keyboardsize = (last_height - (diff * -1) ) * -1;
            }
            
            [self setViewPosition:(diff * -1)];
        }
    }
}

#pragma mark - Text Field

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.messageInput resignFirstResponder];
    
    if ([self isTextValid:self.messageInput.text] && [self.messageInput.text isEqualToString:@""] == NO) {
        if (self.isClient == YES) {
            NSDictionary *parameters = @{
                                         @"user_id": [NSNumber numberWithInteger:[self.app.dataLibrary getInteger:@"driver_id"]],
                                         @"message": self.messageInput.text,
                                         @"did": self.did
                                         };
            
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
            
            [self.app.manager POST:[self.app.serverUrl stringByAppendingString:@"chat-send-base"]
                        parameters:parameters progress:nil
                           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               [self.table reloadData];
                           } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               NSLog(@"Error %@", error);
                           }];
        }
        
        self.messageInput.text = @"";
    } else {
        [self showAlert:@"Chat" :@"Verifica tu mensaje. No puede ser un mensaje vacío y solo se permiten números, letras, espacios y los siguientes caracteres especiales ,.:?¡¿!"];
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
        [cell.image setImage:[self.app.dataLibrary getDriverImage]];
        
        cell.image.layer.cornerRadius = cell.image.frame.size.width / 2;
        cell.image.clipsToBounds = YES;
        
        [cell.message setText:[data objectForKey:@"mensaje"]];
        [cell.date setText:[data objectForKey:@"fecha"]];
        
        return cell;
    } else {
        LeftChatCell *cell = (LeftChatCell *) [self.table dequeueReusableCellWithIdentifier:@"LeftCell"];
        
        cell.message.lineBreakMode = NSLineBreakByWordWrapping;
        cell.message.numberOfLines = 0;
        
        [cell.message setText:[data objectForKey:@"mensaje"]];
        [cell.date setText:[data objectForKey:@"fecha"]];
        
        if (self.isClient && self.clientData != nil) {
            [cell.image setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self.clientData objectForKey:@"image"]]]]];
            cell.image.layer.cornerRadius = cell.image.frame.size.width / 2;
            cell.image.clipsToBounds = YES;
        }
        
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
    return MAX(CELL_CONTENT_MARGIN + size.size.height + sizeDate.size.height, 100);
}

- (void) setClientName : (UIImage *)image {
    self.clientImage = image;
}


//Alerts
- (void)showAlert:(NSString *)title :(NSString *)message {
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
    
    [errorAlert addAction:ok];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

- (BOOL)isTextValid:(NSString *) textToValidate {
    NSString *pattern = @"^([A-Z\u00E0-\u00FCa-z\u00E0-\u00FC0-9 .,:?!¿¡])*$";
    NSError  *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matches = [regex matchesInString:textToValidate options:0 range: NSMakeRange(0, [textToValidate length])];
    
    return [matches count] > 0;
}

- (void)addKeyBoardToolbar:(UITextField *)textfield {
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"OK" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)],
                           nil];
    [numberToolbar sizeToFit];
    textfield.inputAccessoryView = numberToolbar;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Prevent crashing undo bug – see note below.
    if (range.length + range.location > textField.text.length) {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 200;
}

@end
