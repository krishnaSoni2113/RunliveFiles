//
//  SessionViewController.h
//  RunLive
//
//  Created by mac-0005 on 11/8/16.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClipView.h"
#import "WheelRotationGesture.h"


@interface SessionViewController : SuperViewController<SPTAuthViewDelegate,MPMediaPickerControllerDelegate,AVSpeechSynthesizerDelegate,UIGestureRecognizerDelegate,CAAnimationDelegate,WheelRotationGestureDelegate>
{
    IBOutlet UIButton *btnSolo,*btnTeam,*btnGhost,*btnFindSession;
    IBOutlet UILabel *lblDistance,*lblMKM;
    IBOutlet UILabel *lblSolo,*lblTeam,*lblGhost;
    
    //Speedometer
    IBOutlet ClipView *objClip;
    IBOutlet UIView *viewmeter;
    IBOutlet NSLayoutConstraint *cnViewMeterTopSpace,*cnBtnSoloTopSpace;    
    IBOutlet UIImageView *imgRotation;
    WheelRotationGesture *objRotateGesture;
    
}

@end
