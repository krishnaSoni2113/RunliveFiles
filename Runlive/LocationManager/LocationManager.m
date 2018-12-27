//
//  LocationManager.m
//  RunLive
//
//  Created by mac-0005 on 09.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import "LocationManager.h"
#import "LocationManagerDelegateProxy.h"

@interface LocationManager()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) LocationManagerDelegateProxy *locationManagerDelegateProxy;
@property (nonatomic, assign) BOOL isCurrentLocationTracking;
@end

@implementation LocationManager

+ (LocationManager *)sharedInstance {
    static LocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.locationManagerDelegateProxy = [LocationManagerDelegateProxy new];
        self.locationManager = [self configuredLocationManager];
        self.locationManager.delegate = self.locationManagerDelegateProxy;
        [self setupLocationManagerCallbacks];
    }
    return self;
}

- (CLLocationManager *)configuredLocationManager {
    CLLocationManager *locationManager = [CLLocationManager new];
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.allowsBackgroundLocationUpdates = YES;
    locationManager.distanceFilter = 5;
    
    return locationManager;
}

- (void)setupLocationManagerCallbacks {
    __weak __typeof(self) weakSelf = self;
    
    self.locationManagerDelegateProxy.didUpdateLocations = ^(NSArray<CLLocation *> *locations) {
        if (weakSelf.isCurrentLocationTracking) {
            weakSelf.isCurrentLocationTracking = NO;
            weakSelf.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        }
        
        if (locations.lastObject) {
            weakSelf.currentLocation = locations.lastObject;
            [CUserDefaults setDouble:locations.lastObject.coordinate.latitude forKey:CCurrentLatitude];
            [CUserDefaults setDouble:locations.lastObject.coordinate.longitude forKey:CCurrentLongitude];
            [CUserDefaults synchronize];
        }
        
        if (weakSelf.didUpdateLocation && [weakSelf isAccurateLocation:locations.lastObject]) {
            weakSelf.didUpdateLocation(locations.lastObject);
        }
    };
    
    self.locationManagerDelegateProxy.didFailWithError = ^(NSError *error) {
        if (weakSelf.isCurrentLocationTracking) {
            weakSelf.isCurrentLocationTracking = NO;
        }
        if (weakSelf.didFailWithError) {
            weakSelf.didFailWithError(error);
        }
    };
    
    self.locationManagerDelegateProxy.didChangeAuthorization = ^(CLAuthorizationStatus status) {
        if (weakSelf.didChangeAuthorization) {
            BOOL granted = (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                            status == kCLAuthorizationStatusAuthorizedAlways);
            weakSelf.didChangeAuthorization(granted);
        }
        
    };
}

- (BOOL)isAccurateLocation:(nullable CLLocation *)location {
    if (self.isCurrentLocationTracking) {
        self.isCurrentLocationTracking = NO;
        return YES;
    }
    if (location) {
        NSTimeInterval locationTimeStamp = -location.timestamp.timeIntervalSinceNow;
        if (locationTimeStamp > 10) {
            return NO;
        }
        
        if (location.horizontalAccuracy < 0 || location.horizontalAccuracy > 70) {
            if (self.didChangeLocationQuality)
                self.didChangeLocationQuality(NO);
            return NO;
        } else if (self.didChangeLocationQuality) {
            self.didChangeLocationQuality(YES);
        }
        
        return YES;
    } else {
        return NO;
    }
}

- (void)updateCurrentLocation {
    self.isCurrentLocationTracking = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager requestLocation];
}

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void)requestWhenInUseAuthorization {
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)requestAlwaysLocation {
    [self.locationManager requestAlwaysAuthorization];
}

@end
