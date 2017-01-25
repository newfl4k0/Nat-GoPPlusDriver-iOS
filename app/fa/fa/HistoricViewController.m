//
//  HistoricViewController.m
//  fa
//
//  Created by Cristina Avila on 02/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "HistoricViewController.h"


@interface HistoricViewController ()
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (weak, nonatomic) AppDelegate *app;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) StartAnnotation *annotationOrigin;
@property (strong, nonatomic) EndAnnotation *annotationDestiny;
@end

@implementation HistoricViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.dataArray = [[NSMutableArray alloc] init];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 800, 200)];
    
    @try {
        NSArray *services = [self.app.dataLibrary getArray:@"vc-services"];
        
        if ([services count] > 0) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(es_historial == %@)", @"SI"];
            NSArray *filterArray = [services filteredArrayUsingPredicate:predicate];
            self.dataArray = [NSMutableArray arrayWithArray:filterArray];
        } else {
            [self showAlert:@"Historial" :@"Actualmente no tienes ningún servicio en historial. Para actualizar ve a Configuración>Iniciar sincronización manual"];
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [self showAlert:@"Historial" :@"Ocurrió un error al mostrar los servicios. Intenta nuevamente"];
    }
    
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
    
    [cell.data setText: dataString];
    [cell.status setText:data[@"status"]];
    
    
    [self setMapRegion:21.119894 :-101.674890];
    
    [dataString appendString:data[@"origen"]];
    [dataString appendString:@"\n"];
    [dataString appendString:data[@"destino"]];
    [dataString appendString:@"\n"];
    [dataString appendString:data[@"fecha_despacho"]];
    
    [cell.data setText: dataString];
    [cell.status setText:data[@"estatus"]];
 
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 350.0;
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

- (void)setMapRegion:(float)lat :(float)lng {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta  = 0.05;
    span.longitudeDelta = 0.05;
    
    CLLocationCoordinate2D location =  CLLocationCoordinate2DMake(21.119894, -101.674890);
    
    region.span   = span;
    region.center = location;
    
    [self.mapView setRegion:region animated:TRUE];
    [self.mapView regionThatFits:region];
    [self removePin];
    [self setPin:21.2222 :-101.674890];
    [self setPin2:21.3333 :-101.674890];
}

- (void)setPin:(float)lat :(float)lng {
    if (self.annotationOrigin == nil) {
        self.annotationOrigin = [[StartAnnotation alloc] initWithTitle:@"Origen" Location:CLLocationCoordinate2DMake(lat, lng)];
        [self.mapView addAnnotation:self.annotationOrigin];
    }
}

- (void)setPin2:(float)lat :(float)lng {
    if (self.annotationDestiny == nil) {
        self.annotationDestiny = [[EndAnnotation alloc] initWithTitle:@"Destino" Location:CLLocationCoordinate2DMake(lat, lng)];
        [self.mapView addAnnotation:self.annotationDestiny];
    }
}

- (void)removePin {
    if (self.annotationOrigin != nil) {
        [self.mapView removeAnnotation:self.annotationOrigin];
    }
    
    if (self.annotationDestiny != nil) {
        [self.mapView removeAnnotation:self.annotationDestiny];
    }
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
