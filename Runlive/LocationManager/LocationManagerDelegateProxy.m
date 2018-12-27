//
//  LocationManagerDelegateProxy.m
//  RunLive
//
//  Created by mac-0005 on 09.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import "LocationManagerDelegateProxy.h"

@implementation LocationManagerDelegateProxy

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (self.didUpdateLocations) {
        self.didUpdateLocations(locations);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.didFailWithError) {
        self.didFailWithError(error);
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (self.didChangeAuthorization) {
        self.didChangeAuthorization(status);
    }
}

@end
