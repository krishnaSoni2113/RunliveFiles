//
//  MotionManager.h
//  RunLive
//
//  Created by mac-0005 on 11.03.2018.
//  Copyright © 2018 mac-0005. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^didUpdateMotionStatus)(int status);

@interface MotionManager : NSObject

@property (nonatomic, strong) CMMotionActivity * __nullable currentActivity;

@property (nonatomic, strong) didUpdateMotionStatus _Nullable didUpdateMotionStatus;

- (void)requestPermission;
- (void)checkMotionManagerStatus:(void (^_Nonnull)(BOOL isDenied, BOOL notDetermined))completion;
- (void)startMotionDetection;
- (void)stopMotionDetection;

@end
