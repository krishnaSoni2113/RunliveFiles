//
//  WheelRotationGesture.m
//  Runlive
//
//  Created by mac-0005 on 17/02/18.
//

#import "WheelRotationGesture.h"


#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface WheelRotationGesture ()

@property (strong, nonatomic) id target;
@property (nonatomic) SEL action;

@end

@implementation WheelRotationGesture
@synthesize angularSpeed,currentAngle;

- (id)initWithTarget:(id)target action:(SEL)action
{
    if (self = [super initWithTarget:target action:action]) {
        self.target = target;
        self.action = action;
    }
    
    return self;
}

-(UIImageView *)getGestureSuperView
{
    UIImageView *imgRotaion = (UIImageView *)self.view;
    return imgRotaion;
}

#pragma mark - math functions

-(double)DistanceBetweenTwoPoints:(CGPoint)point1 :(CGPoint)point2
{
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy );
}


-(double)angleBetweenThreePoints:(CGPoint)x :(CGPoint)y :(CGPoint)z
{
    double a,b,c;
    
    b = [self DistanceBetweenTwoPoints:x :y];
    a = [self DistanceBetweenTwoPoints:y :z];
    c = [self DistanceBetweenTwoPoints:z :x];
    
    
    double value = (a*a +b*b - c*c)/(2*a*b);
    
    
    return acos(value);
}

-(double)crossProduct:(CGPoint)p1 :(CGPoint)p2 :(CGPoint)p3
{
    CGFloat a1 = p1.x - p2.x;
    CGFloat b1 = p1.y - p2.y;
    
    CGFloat a2 = p3.x - p2.x;
    CGFloat b2 = p3.y - p2.y;
    
    CGFloat slope = a1*b2 - a2*b1;
    
    if (slope < 0)
    {
        return -1;
    }
    else if (slope > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
    
}

-(void)spin:(double)delta
{
    currentAngle = currentAngle + delta;
    CATransform3D transform = CATransform3DMakeRotation(currentAngle, 0, 0, 1);
    
    UIImageView *imgRot = [self getGestureSuperView];
    
    [imgRot.layer setTransform:transform];
}


#pragma mark - UITouch delegate methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [super setState:UIGestureRecognizerStateBegan];

    
    touchesMoved = FALSE;

    //when the wheel is manually stopped
    UIImageView *imgRot = [self getGestureSuperView];
    
    if ([imgRot.layer animationForKey:@"transform.rotation.z"])
    {
        CALayer *presentation = (CALayer*)[imgRot.layer presentationLayer];
        
        currentTransform = [presentation transform];
        
        double angle = [[presentation valueForKeyPath:@"transform.rotation.z"] doubleValue];
        
        currentAngle = angle;
        
        [imgRot.layer removeAnimationForKey:@"transform.rotation.z"];
        
        [imgRot.layer setTransform:currentTransform];
        
    }
    
//    UITouch *touch = [[event allTouches] anyObject];
    UITouch *touch = [touches anyObject];
    
    lastPoint = [touch locationInView:self.parentView.view];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [super setState:UIGestureRecognizerStateChanged];

    
    touchesMoved = TRUE;
    
//    UITouch *touch = [[event allTouches] anyObject];
    UITouch *touch = [touches anyObject];
    
    // get the touch location
    CGPoint currentPoint = [touch locationInView:self.parentView.view];
    
    double theta = [self angleBetweenThreePoints: currentPoint :CGPointMake(160,230):lastPoint];
    
    double sign = [self crossProduct:currentPoint:lastPoint: CGPointMake(160,230)];
    
    
    NSTimeInterval deltaTime = event.timestamp - lastTouchTimeStamp;
    
    angularSpeed = DEGREES_TO_RADIANS(theta)/deltaTime;
    
    turnDirection = sign;
    self.rotationDirection = turnDirection;
    
    
    [self spin:sign*theta];
    
    // update the last point
    
    lastPoint = currentPoint;
    
    lastTouchTimeStamp = event.timestamp;
    
    if ([self.target respondsToSelector:self.action])
        [self.target performSelector:self.action withObject:self];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [super setState:UIGestureRecognizerStateEnded];
    
//    UITouch *touch = [[event allTouches] anyObject];
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.parentView.view];
    
    
    if (touchesMoved)
    {
        double deltaAngle = [self angleBetweenThreePoints:currentPoint:CGPointMake(160,230) :lastPoint];
        
        [self spin:deltaAngle];
        
        turnDirection = [self crossProduct:currentPoint:lastPoint: CGPointMake(160,230) ];
        
        if (angularSpeed > 0.01 && turnDirection != 0)
        {
            [self runSpinAnimation];
        }
        else
        {
            [self.gestureDelegate autoCicrleFillDidStop:YES];
            angularSpeed = 0;
        }
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [super setState:UIGestureRecognizerStateCancelled];
}

#pragma mark - Spin Animation

- (void)runSpinAnimation
{
    CAKeyframeAnimation* animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.duration = 1; //adjust accordingly
    
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    
    animation.calculationMode = kCAAnimationLinear;
    NSMutableArray *keyFrameValues = [[NSMutableArray alloc] init];
    
    // Start the animation with the current angle of the wheel
        
    double angleAtTheInstant = currentAngle;
    double angleTravelled = DEGREES_TO_RADIANS(720)*angularSpeed; // Angle travelled in 1st second
    
    
    
    for (int i = 0; i < 10; i ++)
    {
        [keyFrameValues addObject: [NSNumber numberWithDouble:angleAtTheInstant]];
        angleAtTheInstant = angleAtTheInstant + angleTravelled*turnDirection;
        angleTravelled = angleTravelled*0.8;
    }
    
    animation.values = keyFrameValues;
    
    animation.keyTimes = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.1],
                          [NSNumber numberWithFloat:0.2],
                          [NSNumber numberWithFloat:0.3],
                          [NSNumber numberWithFloat:0.4],
                          [NSNumber numberWithFloat:0.5],
                          [NSNumber numberWithFloat:0.6],
                          [NSNumber numberWithFloat:0.7],
                          [NSNumber numberWithFloat:0.8],
                          [NSNumber numberWithFloat:1.0], nil];
    
    
    
    animation.delegate = self;
    
    UIImageView *imgRot = [self getGestureSuperView];
    [imgRot.layer addAnimation:animation forKey:@"transform.rotation.z"];
    
    [self.gestureDelegate autoCicrleFillDidStart:YES];
}

#pragma mark CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    [self.gestureDelegate autoCicrleFillDidStop:YES];
    angularSpeed = 0;
}

@end
