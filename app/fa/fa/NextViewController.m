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
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventHandler:) name:@"eventReload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSpinnerMain:) name:@"eventShowSpinner" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopSpinnerMain:) name:@"eventStopSpinner" object:nil];
    
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.dataArray = [[NSMutableArray alloc] init];
    
    [self.table setDelegate:self];
    [self.table setDataSource:self];
    [self.spinner stopAnimating];
    [self setTableData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventReload" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventShowSpinner" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventShowSpinner" object:nil];
}

- (IBAction)doToggleMenu:(id)sender {
    [((AppDelegate *) [UIApplication sharedApplication].delegate).drawerController
     toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)setTableData {
    @try {
        NSArray *services = [self.app.dataLibrary getArray:@"vc-services"];
        
        if ([services count] > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(estatus == %@)", @"Pre-asignado"];
            NSArray *filterArray = [services filteredArrayUsingPredicate:predicate];
            self.dataArray = [NSMutableArray arrayWithArray:filterArray];
        } else {
            [self showAlert:@"Próximos Servicios" :@"Actualmente no tienes ningún servicio pre-asignado. Para actualizar ve a Configuración>Iniciar sincronización manual"];
        }
        
        [self.table reloadData];
    } @catch (NSException *exception) {
        [self showAlert:@"Próximos Servicios" :@"Ocurrió un error al mostrar los servicios. Intenta nuevamente"];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
    
    [cell initAppAndService:self.app :[data[@"id"] intValue] :[data[@"lat_origen"] floatValue] :[data[@"lng_origen"] floatValue] :[data[@"lat_destino"] floatValue] :[data[@"lng_destino"] floatValue]];
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
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self performSelector:@selector(dissmissAlert:) withObject:errorAlert afterDelay:3.0];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (void)dissmissAlert:(UIAlertController *) alert{
    [alert dismissViewControllerAnimated:true completion:nil];
}

- (void)eventHandler: (NSNotification *) notification {
    [self.table reloadData];
}

- (void)showSpinnerMain: (NSNotification *) notification {
    [self.spinner startAnimating];
}

- (void)stopSpinnerMain: (NSNotification *) notification {
    [self.spinner stopAnimating];
}


- (IBAction)syncServices:(id)sender {
    [self.spinner startAnimating];
    
    [self.app.manager GET:[self.app.serverUrl stringByAppendingString:@"vc-services"] parameters:@{@"vc_id": [self.app.dataLibrary getString:@"vehicle_driver_id"]} progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      [self.spinner stopAnimating];
                      
                      if ([[responseObject objectForKey:@"data"] count]>0) {
                          [self.app.dataLibrary saveArray:[responseObject objectForKey:@"data"] :@"vc-services"];
                          [self showAlert:@"Próximos viajes" :@"Servicios Actualizados"];
                      } else {
                          [self.app.dataLibrary deleteKey:@"vc-services"];
                      }
                      
                      [self setTableData];
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      [self.spinner stopAnimating];
                      [self showAlert:@"Próximos viajes" :@"Error: servicio no disponible. Intenta nuevamente."];
                  }];
}

@end
