//
//  MotionManager.m
//  RunLive
//
//  Created by mac-0005 on 11.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import "MotionManager.h"

@interface MotionManager()

@property (strong, nonatomic) CMMotionActivityManager *motionActivityManager;
@property (strong, nonatomic) NSOperationQueue *motionQueue;
@property (assign, nonatomic) BOOL isRequestPermission;
@property int motionOldActivityStatus;

@end

@implementation MotionManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.motionQueue = [NSOperationQueue new];
        self.isRequestPermission = NO;
    }
    return self;
}

- (void)requestPermission {
    self.motionActivityManager = [CMMotionActivityManager new];
    self.isRequestPermission = YES;
    [self startMotionDetection];
    [self stopMotionDetection];
}

- (void)startMotionDetection {
    if (!self.motionActivityManager) {
        self.motionActivityManager = [CMMotionActivityManager new];
    }
    __weak __typeof(self) weakSelf = self;
    
    [self.motionActivityManager
     startActivityUpdatesToQueue:self.motionQueue
     withHandler:^(CMMotionActivity * _Nullable activity) {
         if (weakSelf.isRequestPermission) {
             weakSelf.isRequestPermission = NO;
             [weakSelf stopMotionDetection];
         }
         dispatch_async(dispatch_get_main_queue(), ^{
             
             int newMotionActivity = 1;
             if (activity.walking)
                 newMotionActivity = 2;
             else if (activity.running)
                 newMotionActivity = 3;
             else if (activity.stationary)
                 newMotionActivity = 1;
             
             if (self.motionOldActivityStatus != newMotionActivity)
             {
                 if (self.didUpdateMotionStatus)
                     self.didUpdateMotionStatus(newMotionActivity);
             }
             
             self.motionOldActivityStatus = newMotionActivity;
             
             weakSelf.currentActivity = activity;
         });
     }];
}

- (void)checkMotionManagerStatus:(void (^_Nonnull)(BOOL isDenied, BOOL notDetermined))completion;{
    if (@available(iOS 11.0, *)) {
        completion(!([CMMotionActivityManager authorizationStatus] == CMAuthorizationStatusAuthorized),
                   [CMMotionActivityManager authorizationStatus] == CMAuthorizationStatusNotDetermined);
    } else {
        if (!self.motionActivityManager) {
            self.motionActivityManager = [CMMotionActivityManager new];
        }
        [self.motionActivityManager
         queryActivityStartingFromDate:[NSDate new]
         toDate:[NSDate new]
         toQueue:self.motionQueue
         withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
             BOOL isDenied = (error.code == CMErrorMotionActivityNotAuthorized ||
                              error.code == CMErrorMotionActivityNotAvailable ||
                              error.code == CMErrorMotionActivityNotEntitled);
             
             completion(isDenied, error.code == CMErrorMotionActivityNotEntitled);
         }];
    }
}

- (void)stopMotionDetection {
    if (!self.motionActivityManager) {
        [self.motionActivityManager stopActivityUpdates];
    }
}

@end
