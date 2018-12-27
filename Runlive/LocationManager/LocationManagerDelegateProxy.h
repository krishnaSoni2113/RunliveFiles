//
//  LocationManagerDelegateProxy.h
//  RunLive
//
//  Created by mac-0005 on 09.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^didChangeAuthorizationWithStatus)(CLAuthorizationStatus status);
typedef void(^didUpdateLocations)(NSArray<CLLocation *> *locations);
typedef void(^didFailWithError)(NSError *error);

@interface LocationManagerDelegateProxy : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) didUpdateLocations didUpdateLocations;
@property (nonatomic, strong) didFailWithError didFailWithError;
@property (nonatomic, strong) didChangeAuthorizationWithStatus didChangeAuthorization;

@end
