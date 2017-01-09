//
//  HistoricViewController.m
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "HistoricViewController.h"
#import "AppDelegate.h"
#import "HistorialCell.h"

@interface HistoricViewController ()
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) NSMutableArray *dataArray;
@end

@implementation HistoricViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataArray = [[NSMutableArray alloc] init];
    
    [self.dataArray addObjectsFromArray:@[@{ @"lat": @"0", @"lng": @"0", @"status": @"Finalizado", @"start": @"De: Calle Fresno #123 Colonia Centro", @"end": @"A: Plaza Mayor", @"time": @"09 Dic 2017 10:10 am"},
                                          @{ @"lat": @"0", @"lng": @"0", @"status": @"Finalizado", @"start": @"De: Calle Fresno #123 Colonia Centro", @"end": @"A: Plaza Mayor", @"time": @"09 Dic 2017 10:10 am"},
                                          @{ @"lat": @"0", @"lng": @"0", @"status": @"Rechazado", @"start": @"De: Calle Fresno #123 Colonia Centro", @"end": @"A: Plaza Mayor", @"time": @"09 Dic 2017 10:10 am"}]];
    
    [self.table setDelegate:self];
    [self.table setDataSource:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate*) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HistorialCell *cell = (HistorialCell *) [self.table dequeueReusableCellWithIdentifier:@"HistorialCell" forIndexPath:indexPath];
    
    NSDictionary *data = (NSDictionary *)[_dataArray objectAtIndex:indexPath.row];
    
    NSMutableString *dataString = [NSMutableString stringWithCapacity:1000];
    [dataString appendString:data[@"start"]];
    [dataString appendString:@"\n"];
    [dataString appendString:data[@"end"]];
    [dataString appendString:@"\n"];
    [dataString appendString:data[@"time"]];
    
    [cell.data setText: dataString];
    [cell.status setText:data[@"status"]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 350.0;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
