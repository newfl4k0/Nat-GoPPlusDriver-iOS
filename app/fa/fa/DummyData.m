//
//  DummyData.m
//  fa
//
//  Created by Cristina Avila on 04/01/17.
//  Copyright © 2017 Cristina Avila. All rights reserved.
//

#import "DummyData.h"

@implementation DummyData

- (NSDictionary*)doLoginWithUser:(NSString*)user withPassword:(NSString*)password {
    return @{ @"status": @YES, @"message": @"Bienvenido", @"sessionId": @1001 };
}

- (NSDictionary*)doLogoutWithSessionId:(NSInteger*)sessionId {
    return @{ @"status": @YES, @"message": @"Sesión terminada" };
}

- (NSDictionary*)getActiveService:(NSInteger*)sessionId {
    return @{ @"status": @NO,
              @"message": @"No tienes un servicio activo",
              @"data": @{}
            };
}

- (NSDictionary*)getNextServices:(NSInteger*)sessionId {
    return @{ @"status": @YES,
              @"message": @"Tienes 2 servicios proximos",
              @"data": @[]
            };
}

- (NSDictionary*)getLastServices:(NSInteger*)sessionId {
    return @{ @"status": @YES,
              @"message": @"Tienes 3 servicios en historial",
              @"data": @[]
            };
}

- (NSDictionary*)getServerStatus:(NSInteger*)sessionId {
    return @{ @"status": @YES,
              @"message": @"Ultima actualización de información fue hace 4min, proxima actualización 15:30 05 enero 2017"
            };
}

- (NSDictionary*)syncServerDatabase:(NSInteger*)sessionId {
    return @{ @"status": @YES,
              @"message": @"Actualizado"
              };
}




@end
