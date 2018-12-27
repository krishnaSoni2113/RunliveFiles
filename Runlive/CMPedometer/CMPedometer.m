//
//  CMPedometer.m
//  Pedometer
//
//  Created by mac-0005 on 23/03/18.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import "CMPedometer.h"

@interface CMPedometer()

@property (nonatomic, strong) CMPedometer *pedometer;

@end

static CMPedometer *sharedInstance = nil;

static NSString *const CMPedometerDelegate = @"CMPedometerDelegate";

@implementation CMPedometer
{
    NSMutableDictionary *dicDelegate;
}


+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CMPedometer alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        if (!self.pedometer) {
            self.pedometer = [CMPedometer new];
        }
    }
    return self;
}

- (void)setPedometerDelegate:(id<CMPedometerDelegate>)delegate;
{
    if (!dicDelegate)
        dicDelegate = [NSMutableDictionary new];
    
    [dicDelegate setValue:delegate forKey:CMPedometerDelegate];
}

- (void)startPedometer
{
    // start live tracking
    [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error)
    {
        
        id pedometerDelegate = [dicDelegate valueForKey:CMPedometerDelegate];
        
        if (pedometerDelegate)
            [pedometerDelegate udpatePedometerData:pedometerData];
    }];
}

-(void)stopPedometer
{
    [self.pedometer stopPedometerUpdates];
}

@end
