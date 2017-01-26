//
//  NextViewController.m
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "NextViewController.h"

@interface NextViewController () 
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) AppDelegate *app;
@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.dataArray = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventHandler:) name:@"eventReload" object:nil];
    
    @try {
        NSArray *services = [self.app.dataLibrary getArray:@"vc-services"];
        
        if ([services count] > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(estatus == %@)", @"Pre-asignado"];
            NSArray *filterArray = [services filteredArrayUsingPredicate:predicate];
            self.dataArray = [NSMutableArray arrayWithArray:filterArray];
        } else {
            [self showAlert:@"Próximos Servicios" :@"Actualmente no tienes ningún servicio pre-asignado. Para actualizar ve a Configuración>Iniciar sincronización manual"];
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [self showAlert:@"Próximos Servicios" :@"Ocurrió un error al mostrar los servicios. Intenta nuevamente"];
    }
    
    [self.table setDelegate:self];
    [self.table setDataSource:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventReload" object:nil];
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate *) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", indexPath);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NextTableViewCell *cell = (NextTableViewCell *) [self.table dequeueReusableCellWithIdentifier:@"nextCell" forIndexPath:indexPath];
    NSDictionary *data = (NSDictionary *)[_dataArray objectAtIndex:indexPath.row];
    
    [cell initAppAndService:self.app :[data[@"id"] intValue] :[data[@"lat_origen"] floatValue] :[data[@"lng_origen"] floatValue] :[data[@"lat_des"] floatValue] :[data[@"lng_des"] floatValue]];
    [cell.startLabel setText: data[@"origen"]];
    [cell.endLabel setText:data[@"destino"]];
    [cell.dateLabel setText:data[@"fecha_despacho"]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 150.0;
}

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

- (void)eventHandler: (NSNotification *) notification {
    [self.table reloadData];
}

@end
