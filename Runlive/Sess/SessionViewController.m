//
//  CreateSessionViewController.m
//  RunLive
//
//  Created by mac-0005 on 11/8/16.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import "SessionViewController.h"
#import "SelectMusicViewController.h"
#import "FindRunnerViewController.h"
#import "PremiumView.h"
#import "CreateSessionViewController.h"
#import "InAppPurchaseViewController.h"
#import "MotionManager.h"
#import "LocationManager.h"
#import "SessionCountDown.h"
#import "GhostResultViewController.h"


#define anglelimit 16.363

@interface SessionViewController () {
    NSString *strDistanceForServer;
    
    CADisplayLink *redrawTimer;
    CGFloat updatedAngle;
    NSInteger rotationDirection;
    NSTimer *rotationTimer;
    
    double rotationSpeed;
    
    BOOL isOpenPermssionView;
    BOOL isTimerRunning, isUserMovingFinger, isFromAutoRotation;
}

@property (strong, nonatomic) MotionManager *motionManager;

@end

@implementation SessionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (Is_iPhone_X) {
        cnBtnSoloTopSpace.constant = 10;
        cnViewMeterTopSpace.constant = 60;
    } else if (Is_iPhone_5) {
        cnBtnSoloTopSpace.constant = -18;
        cnViewMeterTopSpace.constant = -15;
    } else if (Is_iPhone_6_PLUS) {
        cnBtnSoloTopSpace.constant = 5;
        cnViewMeterTopSpace.constant = 10;
    } else {
        cnViewMeterTopSpace.constant = -5;
        cnBtnSoloTopSpace.constant = 0;
    }
    
    btnFindSession.layer.cornerRadius = 3;
    viewmeter.transform = Is_iPhone_5 ? CGAffineTransformMakeScale(1.08, 1.08) : CGAffineTransformMakeScale(1.2, 1.2);
    
    updatedAngle = 128.700653;
    [self setValuewithAngle:updatedAngle];
    [self btnSessionTypeCLK:btnSolo];
    
    objRotateGesture = [[WheelRotationGesture alloc] initWithTarget:self action:@selector(rotationGesture:)];
    objRotateGesture.parentView = self;
    objRotateGesture.gestureDelegate = self;
    [imgRotation addGestureRecognizer:objRotateGesture];
    
    self.motionManager = [MotionManager new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    btnFindSession.userInteractionEnabled = YES;
    
    [[LocationManager sharedInstance] updateCurrentLocation];
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    isOpenPermssionView = YES;
    appDelegate.isMusicSelected = NO;
    
    [appDelegate showTabBar];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:YES];
    
    [appDelegate MQTTDisconnetFromServer];
    [self setValuewithAngle:updatedAngle];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    btnSolo.layer.cornerRadius = CGRectGetHeight(btnSolo.frame)/2;
    btnTeam.layer.cornerRadius = CGRectGetHeight(btnTeam.frame)/2;
    btnSolo.layer.masksToBounds = btnTeam.layer.masksToBounds = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopMeterTimer];
}


#pragma mark - RotateGestureRecognizer Methods

- (void)updateCountdown
{
    [self fillInnerCircleWithAngle];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.003 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!isFromAutoRotation)
        {
            if (!isUserMovingFinger)
                [self stopMeterTimer];
            
            isUserMovingFinger = NO;
        }
        
    });
    
}

- (void)startMeterTimer {
    [self stopMeterTimer];
    redrawTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCountdown)];
    [redrawTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    isTimerRunning = YES;
}

- (void)stopMeterTimer {
    isTimerRunning = NO;
    [redrawTimer invalidate];
    rotationTimer = nil;
}

- (void)autoCicrleFillDidStop:(BOOL)isStop {
    isFromAutoRotation = NO;
    [self stopMeterTimer];
}

- (void)autoCicrleFillDidStart:(BOOL)isStart {
    isFromAutoRotation = YES;
    [self startMeterTimer];
}

- (void)rotationGesture:(id)sender {
    NSInteger direction = ((WheelRotationGesture*)sender).rotationDirection;
    rotationSpeed = ((WheelRotationGesture*)sender).angularSpeed;
    
    rotationDirection = direction;
    
    switch ([(WheelRotationGesture*)sender state])
    {
        case UIGestureRecognizerStateBegan:
        {
            // Start Timer here....
            if (rotationSpeed > 0.001)
                [self updateCountdown];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            isUserMovingFinger = YES;
            
            if (rotationSpeed > 0.001 && !isTimerRunning)
                [self updateCountdown];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            //            NSLog(@"UIGestureRecognizerStateEnded ===== ");
            break;
        }
        case UIGestureRecognizerStateCancelled:
        {
            [self stopMeterTimer];
            break;
        }
            
        default:
            break;
    }
}

- (void)fillInnerCircleWithAngle {
    double angle = 0;
    float increaseAgnglePer = 0.90;
    
    if (rotationSpeed > 0.5) {
        increaseAgnglePer = 0.2; // speed of wheel rotation when swiping
    } else {
        increaseAgnglePer = 0.3; // speed of wheel rotation when panning
    }
    
    if (rotationDirection == 1) {
        angle = 360*increaseAgnglePer/100;
    } else {
        angle = -(360*increaseAgnglePer/100);
    }
    
    updatedAngle += angle;
    
    if (updatedAngle >= 360)
        updatedAngle = 360;
    
    if (updatedAngle <= 0)
        updatedAngle = 0;
    
    [self setValuewithAngle:((float)lroundf(updatedAngle))];
}


#pragma mark - Distance Meter Related Functions

-(void)setValuewithAngle:(CGFloat)angle //360 formate {
    [objClip updateAngle:angle];
    
    float Distance = 0;
    if (angle < 0)
    {
        float nagativeAngle = fabs(angle);
        if (nagativeAngle < anglelimit)
            Distance = 283.494;
        else {
            Distance = 180 + angle;
            Distance = Distance+180-anglelimit;
        }
    }
    else
    {
        if (angle < anglelimit)
            Distance = 0;
        else {
            Distance = angle;
            Distance = Distance-anglelimit;
        }
    }
    
    Distance = Distance/16.3636;
    
    //Possible values: 1k, 2k, 3k, 4k, 5k, 6k, 7k, 8k, 9k, 10k, 11k, 12k, 13k, 14k, 15k, 16k, 17k, 18k, 19k, 20k, 21k, 22k
    NSString *strSelectedDistance;
    if (Distance <= 0 )
        strSelectedDistance = @"0";
    else if (Distance <= 1.0 )
        strSelectedDistance = @"1";
    else if (Distance <= 2.0 )
        strSelectedDistance = @"2";
    else if (Distance <= 3.0 )
        strSelectedDistance = @"3";
    else if (Distance <= 4.0 )
        strSelectedDistance = @"4";
    else if (Distance <= 5.0 )
        strSelectedDistance = @"5";
    else if (Distance <= 6.0 )
        strSelectedDistance = @"6";
    else if (Distance <= 7.0 )
        strSelectedDistance = @"7";
    else if (Distance <= 8.0 )
        strSelectedDistance = @"8";
    else if (Distance <= 9.0 )
        strSelectedDistance = @"9";
    else if (Distance <= 10 )
        strSelectedDistance = @"10";
    else if (Distance <= 11 )
        strSelectedDistance = @"11";
    else if (Distance <= 12 )
        strSelectedDistance = @"12";
    else if (Distance <= 12.85 )
        strSelectedDistance = @"13";
    else if (Distance <= 13.35 )
        strSelectedDistance = @"14";
    else if (Distance <= 14 )
        strSelectedDistance = @"15";
    else if (Distance <= 14.75 )
        strSelectedDistance = @"15";
    else if (Distance <= 15.25 )
        strSelectedDistance = @"16";
    else if (Distance <= 16 )
        strSelectedDistance = @"17";
    else if (Distance <= 16.85 )
        strSelectedDistance = @"18";
    else if (Distance <= 17.35 )
        strSelectedDistance = @"19";
    else if (Distance <= 18.95 )
        strSelectedDistance = @"20";
    else if (Distance <= 19.653996 )
        strSelectedDistance = @"21";
    else
        strSelectedDistance = @"22";
    
    strDistanceForServer = strSelectedDistance;
    
    if ([appDelegate.loginUser.units isEqualToString:CDistanceMetric]) {
        lblMKM.text = @"km";
        lblDistance.text = strSelectedDistance;
    } else {
        lblMKM.text = @"miles";
        float miles = strSelectedDistance.floatValue / 1.60934;
        lblDistance.text = [NSString stringWithFormat:@"%.1f",miles];
    }
}


#pragma mark - ActionEvent

- (IBAction)btnSessionTypeCLK:(UIButton *)sender
{
    //    GhostResultViewController *objResult = [GhostResultViewController new];
    //    [self.navigationController pushViewController:objResult animated:YES];
    //    return;
    
    if (sender.selected)
        return;
    
    btnSolo.selected = btnTeam.selected = btnGhost.selected = NO;
    lblSolo.textColor = lblTeam.textColor = lblGhost.textColor = CRGB(120, 124, 141);
    
    switch (sender.tag)
    {
        case 0:
        {
            btnSolo.selected = YES;
            lblSolo.textColor = [UIColor whiteColor];
            [btnFindSession setTitle:@"FIND LIVE RUN" forState:UIControlStateNormal];
            break;
        }
        case 1:
        {
            btnTeam.selected = YES;
            lblTeam.textColor = [UIColor whiteColor];
            [btnFindSession setTitle:@"FIND LIVE RUN" forState:UIControlStateNormal];
            break;
        }
        case 2:
        {
            btnGhost.selected = YES;
            lblGhost.textColor = [UIColor whiteColor];
            [btnFindSession setTitle:@"START GHOST RUN" forState:UIControlStateNormal];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)btnMusicAndCreateSessionCLK:(UIButton *)sender {
    switch (sender.tag) {
        case 0:
        {
            SelectMusicViewController *objSelectMusic = [[SelectMusicViewController alloc] init];
            [self.navigationController pushViewController:objSelectMusic animated:NO];
            break;
        }
        case 1:
        {
            CreateSessionViewController *objCreateSession = [[CreateSessionViewController alloc] initWithNibName:@"CreateSessionViewController" bundle:nil];
            [self.navigationController pushViewController:objCreateSession animated:YES];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)btnFindLiveSessionsCLK:(UIButton *)sender {
    
    dispatch_async(GCDMainThread, ^{
        NSArray *arrMusic = [TblMusicList fetchAllObjects];
        
        BOOL shouldGo = YES;
        
        if (arrMusic.count > 0)
        {
            TblMusicList *objMusic = (TblMusicList *)[arrMusic objectAtIndex:0];
            
            if (!objMusic.isApple.boolValue)
            {
                SPTAuth* auth = [SPTAuth defaultInstance];
                if(![appDelegate isSpotifySessionValid:auth])
                {
                    shouldGo = NO;
                    SPTAuthViewController *authViewController = [SPTAuthViewController authenticationViewController];
                    authViewController.delegate = self;
                    authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                    authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    
                    self.modalPresentationStyle = UIModalPresentationCurrentContext;
                    self.definesPresentationContext = YES;
                    
                    [self.navigationController presentViewController:authViewController animated:NO completion:nil];
                }
            }
        }
        
        if (shouldGo)
        {
            dispatch_async(GCDMainThread, ^{
                [self gotoFindRunnersScreen];
            });
        }
        
    });
}

#pragma mark - Spotify Delegates

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didFailToLogin:(NSError *)error
{
    NSLog(@"*** Failed to log in: %@", error);
    [self customAlertViewWithOneButton:@"" Message:@"Something went wrong with the spotify connection." ButtonText:@"OK" Animation:YES completed:^{
        dispatch_async(GCDMainThread, ^{
            [self gotoFindRunnersScreen];
        });
    }];
}

- (void)authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController
{
    NSLog(@"%@",@"Login cancelled.");
    
    dispatch_async(GCDMainThread, ^{
        [self gotoFindRunnersScreen];
    });
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didLoginWithSession:(SPTSession *)session
{
    dispatch_async(GCDMainThread, ^{
        [self gotoFindRunnersScreen];
    });
}

#pragma mark - Permission Related Methods

-(void)checkMotionPermissionView {
    // Show Motion Permission View here...
    MotionPermissionView *objMotion = [MotionPermissionView initPermissionView];
    [appDelegate.window addSubview:objMotion];
    
    [objMotion.btnMotionGoForIt touchUpInsideClicked:^{
        
        if (![CUserDefaults objectForKey:CMMotionManagerStatus])
        {
            [appDelegate initializeMotionDetector];
            
            dispatch_async(GCDMainThread, ^{
                [objMotion.btnMotionNotNow sendActionsForControlEvents:UIControlEventTouchUpInside];
            });
        }
        else
        {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }];
    
    [objMotion.btnMotionNotNow touchUpInsideClicked:^{
        [objMotion removeFromSuperview];
    }];
}

- (void)checkGPSPermissionView {
    
    // Show GPS Permission View here...
    GPSPermissionView *objPermission = [GPSPermissionView initPermissionView];
    [appDelegate.window addSubview:objPermission];
    
    [objPermission.btnGPSGoForIt touchUpInsideClicked:^{
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
        {
            [appDelegate initialSetUpForLocaitonMananger];
            
            appDelegate.configureGpsPermissionStatus = ^(BOOL isAllow) {
                [objPermission.btnGPSNotNow sendActionsForControlEvents:UIControlEventTouchUpInside];
            };
        } else {
            // Open settings screen from the app
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [objPermission.btnGPSNotNow sendActionsForControlEvents:UIControlEventTouchUpInside];
            });
        }
        
        
    }];
    
    [objPermission.btnGPSNotNow touchUpInsideClicked:^{
        dispatch_async(GCDMainThread, ^{
            [objPermission hideWithAnimation:^{
                [objPermission removeFromSuperview];
            }];
        });
    }];
}

-(void)checkMicrophonePermissionView:(BOOL)isSetting
{
    // Show Motion Permission View here...
    
    VoiceChatPermissionView *objVoiceChat = [VoiceChatPermissionView initPermissionView];
    [appDelegate.window addSubview:objVoiceChat];
    
    [objVoiceChat.btnVoiceChatGotForIt touchUpInsideClicked:^{
        
        if (isSetting)
        {
            // Open settings screen from the app
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [objVoiceChat.btnVoiceChatNotNow sendActionsForControlEvents:UIControlEventTouchUpInside];
            });
        } else {
            [objVoiceChat askForMicroPhonePermission];
            
            __weak typeof (objVoiceChat) weakObjVoiceChat = objVoiceChat;
            objVoiceChat.configurationVoiceChatPermissionAcceptReject = ^(BOOL isGranted)
            {
                dispatch_async(GCDMainThread, ^{
                    [weakObjVoiceChat.btnVoiceChatNotNow sendActionsForControlEvents:UIControlEventTouchUpInside];
                });
            };
        }
    }];
    
    [objVoiceChat.btnVoiceChatNotNow touchUpInsideClicked:^{
        [objVoiceChat hideWithAnimation:^{
            isOpenPermssionView = NO;
            [objVoiceChat removeFromSuperview];
        }];
    }];
}

- (void)checkAudioService {
    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionUndetermined && isOpenPermssionView && appDelegate.loginUser.isVoiceChatEnable.boolValue)
    {
        // Show MicroPhone permission view
        dispatch_async(GCDMainThread, ^{
            [self checkMicrophonePermissionView:NO];
        });
        
        return;
    }
    
    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionDenied && isOpenPermssionView && appDelegate.loginUser.isVoiceChatEnable.boolValue)
    {
        // Show Setting screen here...
        dispatch_async(GCDMainThread, ^{
            [self checkMicrophonePermissionView:YES];
        });
        
        return;
    }
    [self checkCurrentSessionDistance];
}

- (void)checkCurrentSessionDistance {
    if (strDistanceForServer.intValue < 1) {
        [self customAlertViewWithOneButton:@""
                                   Message:@"Please select minimum 1 km distance."
                                ButtonText:@"OK"
                                 Animation:YES
                                 completed:nil
         ];
    } else {
        dispatch_async(GCDMainThread, ^{
            
            if (btnGhost.selected)
            {
                if ([appDelegate checkInternetReachability])
                {
                    [self getSessionForGhostMode];
                }
                else
                {
                    [self customAlertViewWithTwoButton:@"" Message:CMessageAlertGhostOffline ButtonFirstText:@"Ok" ButtonSecondText:@"Cancel" Animation:YES completed:^(int index) {
                        if (index == 0)
                        {
                            [self getSessionForGhostMode];
                        }
                    }];
                }
            }
            else
                [self createLiveRunningSession];
        });
    }
}

- (void)createLiveRunningSession {
    
    // Get Runnig distance
    int sessionDistance = [appDelegate convertKMToMeter:strDistanceForServer IsKM:NO].intValue;
    
    // Create request paramter dictionary here.....
    NSMutableDictionary *dicData = [NSMutableDictionary new];
    [dicData addObject:[NSString stringWithFormat:@"%d",sessionDistance] forKey:@"distance"];
    
    [dicData addObject:appDelegate.loginUser.user_id
                forKey:@"user_id"];
    [dicData addObject:btnSolo.selected ? @"solo":@"team"
                forKey:@"run_type"];
    [dicData setDouble:[LocationManager sharedInstance].currentLocation.coordinate.latitude
                forKey:@"latitude"];
    [dicData setDouble:[LocationManager sharedInstance].currentLocation.coordinate.longitude
                forKey:@"longitude"];
    
    
    // Connect MQTT With server....
    [appDelegate MQTTInitialSetup];
    
    btnFindSession.userInteractionEnabled = NO;
    [appDelegate createLiveSession:dicData completed:^(id responseObject, NSError *error)
     {
         btnFindSession.userInteractionEnabled = YES;
         if (responseObject && !error)
         {
             NSDictionary *dicRes = [responseObject valueForKey:CJsonData];
             FindRunnerViewController *objFind = [[FindRunnerViewController alloc] init];
             objFind.isSoloFind = btnSolo.selected;
             objFind.strSessoinId = [dicRes stringValueForJSON:@"_id"];
             objFind.dicSessionData = dicData;
             objFind.dicSessionPlayer = dicRes;
             [self.navigationController pushViewController:objFind animated:YES];
         }
     }];
    
}


#pragma mark - Ghost session related functions
- (void)syncGhostSessionOnServer {
    [appDelegate syncGhostSessionToServer:^(id responseObject, NSError *error) {
        if (error && !responseObject)
        {
            [self customAlertViewWithTwoButton:@"" Message:CMessageErrorGhostSyncing ButtonFirstText:@"Yes" ButtonSecondText:@"NO" Animation:YES completed:^(int index) {
                if (index == 0)
                {
                    // Retry here
                    [self syncGhostSessionOnServer];
                }
            }];
        }
    }];
}

-(void)getSessionForGhostMode
{
    NSArray *arrUnsyncedSession = [TblGhostRunningSession fetch:[NSPredicate predicateWithFormat:@"isCompletedSession == %@ && isSynced == %@", @1, @0] sortedBy:nil];
    if (arrUnsyncedSession.count > 0)
    {
        [self customAlertViewWithTwoButton:@"" Message:CMessageGhostUnsync ButtonFirstText:@"Sync" ButtonSecondText:@"Cancel" Animation:YES completed:^(int index) {
            if (index == 0)
            {
                // Sync here
                [self syncGhostSessionOnServer];
            }
        }];
        
        return;
    }
    
    int selectedDistance = [appDelegate convertKMToMeter:strDistanceForServer IsKM:NO].intValue;
    
    NSArray *arrGhostSession = [TblGhostBestSessionList fetch:[NSPredicate predicateWithFormat:@"searchDistance == %d",selectedDistance] sortedBy:nil];
    if (arrGhostSession.count > 0)
    {
        TblGhostBestSessionList *objBestGhost = arrGhostSession[0];
        [self startRunningForGhostMode:objBestGhost];
    }
    else
    {
        [self customAlertViewWithTwoButton:@"" Message:CMessageGhostFirstSession ButtonFirstText:@"Yes" ButtonSecondText:@"NO" Animation:YES completed:^(int index) {
            if (index == 0)
            {
                [self startRunningForGhostMode:nil];
            }
        }];
    }
}

- (void)startRunningForGhostMode:(TblGhostBestSessionList *)objBeshGhost
{
    
    NSMutableDictionary *dicGhostData = [NSMutableDictionary new];
    TblGhostRunningSession *objGhostRun = [self createGhostRunningObject];
    
    if (objGhostRun)    // Create current ghost object and store here for running screen....
        [dicGhostData setObject:objGhostRun forKey:CGhostRunSession];
    
    if (objBeshGhost)
    {
        // Get best ghost session and store here for running screen...
        [dicGhostData setObject:objBeshGhost forKey:CGhostBestSession];
        objGhostRun.ghost_session_id = objBeshGhost.session_id; // Get ghost id from latest ghost session....
    }
    else    // If user recording his first ghost session that time ghost id is not there...
        objGhostRun.ghost_session_id = @"";
    
    btnFindSession.userInteractionEnabled = NO;
    SessionCountDown *objSessioCount = [SessionCountDown viewFromXib];
    objSessioCount.dicGhostModeData = dicGhostData;
    [objSessioCount removeFromSuperview];
    [appDelegate.window addSubview:objSessioCount];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        btnFindSession.userInteractionEnabled = YES;
    });
}

- (TblGhostRunningSession *)createGhostRunningObject
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CGhostDateFormater;
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString *strRunDate =  [dateFormatter stringFromDate:[NSDate date]];
    
    int selectedDistance = [appDelegate convertKMToMeter:strDistanceForServer IsKM:NO].intValue;
    
    TblGhostRunningSession *objRunningGhost = [TblGhostRunningSession findOrCreate:@{@"distance":@"selectedDistance",@"timestamp":[NSNumber numberWithDouble:currentTimestamp]}];
    objRunningGhost.timestamp = [NSNumber numberWithDouble:currentTimestamp];
    objRunningGhost.distance = [NSNumber numberWithInt:selectedDistance];
    objRunningGhost.isSynced = @NO;
    objRunningGhost.isCompletedSession = @0;
    objRunningGhost.run_time = strRunDate;
    objRunningGhost.time = strRunDate;
    objRunningGhost.user_name = appDelegate.loginUser.user_name;
    objRunningGhost.user_id = appDelegate.loginUser.user_id;
    objRunningGhost.picture = appDelegate.loginUser.user_thumb_image;
    
    objRunningGhost.name = @"Ghost Run";
    objRunningGhost.run_type = @"ghost";
    objRunningGhost.latitude = [NSString stringWithFormat:@"%f",[LocationManager sharedInstance].currentLocation.coordinate.latitude];
    objRunningGhost.longitude = [NSString stringWithFormat:@"%f",[LocationManager sharedInstance].currentLocation.coordinate.longitude];
    objRunningGhost.locality = @"";
    objRunningGhost.sub_locality = @"";
    objRunningGhost.performance = @"";
    objRunningGhost.rank = @"";
    objRunningGhost.total_distance = @"";
    
    
    NSMutableDictionary *dicRunning = [NSMutableDictionary new];
    [dicRunning setObject:@"0" forKey:@"average_bpm"];
    [dicRunning setObject:@"0" forKey:@"average_speed"];
    [dicRunning setObject:[NSString stringWithFormat:@"%f",[LocationManager sharedInstance].currentLocation.coordinate.latitude] forKey:@"latitude"];
    [dicRunning setObject:[NSString stringWithFormat:@"%f",[LocationManager sharedInstance].currentLocation.coordinate.longitude] forKey:@"longitude"];
    [dicRunning setObject:@"0" forKey:@"position"];
    [dicRunning setObject:@"0" forKey:@"publish_status"];
    [dicRunning setObject:@"1" forKey:@"running_status"];
    [dicRunning setObject:@"1" forKey:@"sound_alert"];
    [dicRunning setObject:@"0" forKey:@"total_calories"];
    [dicRunning setObject:@"0" forKey:@"total_distance"];
    [dicRunning setObject:@"00:00:00" forKey:@"total_time"];
    [dicRunning setObject:@"00:00:00" forKey:@"time"];
    [dicRunning setObject:appDelegate.loginUser.user_id forKey:@"user_id"];
    [dicRunning setObject:@"0" forKey:@"publishTimeforIndex"];
    
    objRunningGhost.running = @[dicRunning];
    
    NSMutableDictionary *dicComplete = [NSMutableDictionary new];
    [dicComplete setObject:@"0" forKey:@"average_bpm"];
    [dicComplete setObject:@"0" forKey:@"average_speed"];
    [dicComplete setObject:@"0" forKey:@"feedback_status"];
    [dicComplete setObject:@"0" forKey:@"points"];
    [dicComplete setObject:@"0" forKey:@"position"];
    [dicComplete setObject:@"0" forKey:@"rank"];
    [dicComplete setObject:@"0" forKey:@"run_completed_type"];
    [dicComplete setObject:@"0" forKey:@"feedback_status"];
    [dicComplete setObject:@"0" forKey:@"running_status"];
    [dicComplete setObject:@"0" forKey:@"sound_alert"];
    [dicComplete setObject:@"0" forKey:@"total_calories"];
    [dicComplete setObject:@"0" forKey:@"total_distance"];
    [dicComplete setObject:@"00:00:00" forKey:@"total_time"];
    objRunningGhost.completed = dicComplete;
    
    [[Store sharedInstance].mainManagedObjectContext save];
    
    return objRunningGhost;
}


- (void)gotoFindRunnersScreen {
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        dispatch_async(GCDMainThread, ^{
            [self checkGPSPermissionView];
        });
        
        return;
    }
    __weak __typeof(self) weakSelf = self;
    
    [self.motionManager checkMotionManagerStatus:^(BOOL isDenied, BOOL notDetermined) {
        if ((isDenied && !IS_IPHONE_SIMULATOR) || (notDetermined && !IS_IPHONE_SIMULATOR)) {
            dispatch_async(GCDMainThread, ^{
                [weakSelf checkMotionPermissionView];
            });
        } else {
            [weakSelf checkAudioService];
        }
    }];
}

@end
