//
//  WheelRotationGesture.h
//  Runlive
//
//  Created by mac-0005 on 17/02/18.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@protocol WheelRotationGestureDelegate <UIGestureRecognizerDelegate>

-(void)autoCicrleFillDidStop:(BOOL)isStop;

-(void)autoCicrleFillDidStart:(BOOL)isStart;

@end

@interface WheelRotationGesture : UIGestureRecognizer<CAAnimationDelegate>
{
    BOOL touchesMoved;
    
    
    CGPoint lastPoint;
    NSTimeInterval lastTouchTimeStamp;
    
    
    CATransform3D currentTransform;
    NSInteger turnDirection;
}

@property(strong,nonatomic) UIViewController *parentView;
@property NSInteger rotationDirection;

@property double currentAngle;
@property double angularSpeed;

@property (nonatomic, weak) id <WheelRotationGestureDelegate> gestureDelegate; //define MyClassDelegate as delegate

@end
