//
//  CMPedometer.h
//  Pedometer
//
//  Created by mac-0005 on 23/03/18.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreMotion;


@protocol CMPedometerDelegate
-(void)udpatePedometerData:(CMPedometerData *)pedometeData;
@end

@interface CMPedometer : NSObject

- (void)setPedometerDelegate:(id<CMPedometerDelegate>)delegate;

+ (id)sharedInstance;

-(void)startPedometer;
-(void)stopPedometer;

@end
