//
//  LocationManager.h
//  RunLive
//
//  Created by mac-0005 on 09.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^didUpdateLocation)(CLLocation * location);
typedef void(^didFailWithError)(NSError *error);
typedef void(^didChangeLocationQuality)(BOOL isAccurate);
typedef void(^didChangeAuthorization)(BOOL isGranted);

@interface LocationManager : NSObject

@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, strong) didUpdateLocation didUpdateLocation;
@property (nonatomic, strong) didFailWithError didFailWithError;
@property (nonatomic, strong) didChangeLocationQuality didChangeLocationQuality;
@property (nonatomic, strong) didChangeAuthorization didChangeAuthorization;

+ (LocationManager *)sharedInstance;

- (void)updateCurrentLocation;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)requestWhenInUseAuthorization;
- (void)requestAlwaysLocation;

@end
