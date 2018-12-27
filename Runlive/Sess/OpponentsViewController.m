//
//  OpponentsViewController.m
//  RunLive
//
//  Created by mac-0005 on 11/15/16.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import "OpponentsViewController.h"
#import "OpponentCell.h"
#import "TeamMatchedCell.h"
#import "TeamMatchedHeader.h"
#import "RunningViewController.h"



@interface OpponentsViewController ()

@end

@implementation OpponentsViewController
{
    NSTimer *timer;
    int seconds;
    
    NSMutableArray *arrTeamFirst,*arrTeamSecond;
    AVPlayer *player;
    float currentPlayingTime;
    BOOL isAllowToGoOnSearchScreen,isTimerStarted;
    NSString *strMyTeamType;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isTimerStarted = NO;
    arrTeamFirst = [NSMutableArray new];
    arrTeamSecond = [NSMutableArray new];
    
    lblTitle.text = self.isSolo ? @"OPPONENTS" : @"TEAMS MATCHED";
    [tblPlayer registerNib:[UINib nibWithNibName:@"OpponentCell" bundle:nil] forCellReuseIdentifier:@"OpponentCell"];
    [tblPlayer registerNib:[UINib nibWithNibName:@"TeamMatchedCell" bundle:nil] forCellReuseIdentifier:@"TeamMatchedCell"];
    
    viewQuit.layer.cornerRadius = btnYes.layer.cornerRadius = btnNoWay.layer.cornerRadius = 3;
    
    currentPlayingTime = 0;
    // Video setup for count down...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"Counting" ofType:@"mp4"];
        NSURL *movieURL = [NSURL fileURLWithPath:moviePath] ;
        player = [AVPlayer playerWithURL:movieURL]; //
        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        AVPlayerLayer *avLayer = [AVPlayerLayer layer];
        [avLayer setPlayer:player];
        [avLayer setFrame:CGRectMake(0, 0, viewVideo.frame.size.width,viewVideo.frame.size.height)];
        [avLayer setBackgroundColor:[UIColor clearColor].CGColor];
        [avLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        player.muted = NO;
        [viewVideo.layer addSublayer:avLayer];
    });
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[player currentItem]];
    });
    

    
    [UIApplication applicationDidEnterBackground:^{
        // When ente in background mode
        if ([[appDelegate getTopMostViewController] isKindOfClass:[OpponentsViewController class]])
        {
            if (player.rate > 0 && player)
            {
                // Playing
                currentPlayingTime = CMTimeGetSeconds(player.currentItem.currentTime);
                [player pause];
            }
        }
    }];
    
    [UIApplication applicationDidBecomeActive:^{
        
        if ([[appDelegate getTopMostViewController] isKindOfClass:[OpponentsViewController class]])
        {
            if (player)
            {
                [player seekToTime:CMTimeMakeWithSeconds(currentPlayingTime, 60000)];
                [player play];
            }
        }
    }];
    
    
//    NSLog(@"Searching player list ============ >>>>>> %@",self.dicSesionPlayerFromFind);
    
    [self GetTeamPlayerForSession:self.dicSesionPlayerFromFind];
    
    // Resubcribe if MQTT connection was break from server............
    appDelegate.configureResubscribeOnMQTT = ^(BOOL isSubscribe)
    {
        if (appDelegate.objMQTTClient.connected && [[appDelegate getTopMostViewController] isKindOfClass:[OpponentsViewController class]] && self.strSessionIDFromSearch)
        {
            // Subscribe Session On MQTT
            [appDelegate MQTTSubscribeWithTopic:self.strSessionIDFromSearch];
        }
    };
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [appDelegate keepAppInIdleMode:YES];
    [self addMQTTNotificationObserver];

    viewQuitContainer.hidden = YES;
    isAllowToGoOnSearchScreen = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [appDelegate keepAppInIdleMode:NO];
}


#pragma mark - MQTT Function

-(void)addMQTTNotificationObserver
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MQTTPlayer:) name:CMQTTOpponentSearchingPlayer object:nil];
    });
}

-(void)removeMQTTOpponentNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CMQTTOpponentSearchingPlayer object:nil];
}


-(void)MQTTPlayer:(NSNotification *)notification
{
    NSDictionary *dicMQTT = [notification userInfo];
    
    if(![dicMQTT isKindOfClass:[NSDictionary class]] || ![dicMQTT objectForKey:@"invitation"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([[appDelegate getTopMostViewController] isKindOfClass:[OpponentsViewController class]])
        {
//            NSLog(@"Opponent view controller============>>>>>>>>>> %@",dicMQTT);
            if ([[dicMQTT numberForJson:@"session_status"] isEqual:@2])
            {
                // Move on Running screen........
                [self moveOnRunningScreen];
            }
            else
            {
                self.dicSesionPlayerFromFind = dicMQTT;
                [self GetTeamPlayerForSession:self.dicSesionPlayerFromFind];
            }
        }
    });
}

#pragma mark - API Related Functions
-(void)GetTeamPlayerForSession:(NSDictionary *)dicUsers
{
    
    if (!isTimerStarted)
    {
        NSLog(@"Time Started for opponent ======= >>>> ");
        isTimerStarted = YES;
        [self startTimeHere:dicUsers];
    }
    
    
    NSDictionary *dicInvite = [dicUsers valueForKey:@"invitation"];
    if (self.isSolo)
    {
        [arrTeamFirst removeAllObjects];
        [arrTeamFirst addObjectsFromArray:[dicInvite valueForKey:@"solo"]];
        strMyTeamType = @"solo";
    }
    else
    {
        [arrTeamFirst removeAllObjects];
        [arrTeamSecond removeAllObjects];
        [arrTeamFirst addObjectsFromArray:[dicInvite valueForKey:@"team_red"]];
        
        if ([arrTeamFirst filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user_id == %@", appDelegate.loginUser.user_id]].count > 0)
            strMyTeamType = @"team_red";

        [arrTeamSecond addObjectsFromArray:[dicInvite valueForKey:@"team_blue"]];
        if ([arrTeamSecond filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user_id == %@", appDelegate.loginUser.user_id]].count > 0)
            strMyTeamType = @"team_blue";
    }
    
    [tblPlayer reloadData];

    // if Session type is Solo - Required minmum 2 player including login user.
    // if Session type is Team - Required minmum 2 player in each team.
    if ((self.isSolo && arrTeamFirst.count < 2) || (!self.isSolo && (arrTeamFirst.count < 2 || arrTeamSecond.count < 2)))
    {
        NSArray *arrLogin = [arrTeamFirst filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"user_id == %@", appDelegate.loginUser.user_id]];

        [self StopTimer];
        
        arrLogin.count > 0 ? [self moveOnSearchScreen] : dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self moveOnSearchScreen];
        });
    }
}

#pragma mark - Timer Functions
-(void)startTimeHere:(NSDictionary *)dicData
{
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
   // dateFormatter.dateFormat = CDateFormater;
//    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//    [dateFormatter setTimeZone:gmt];
    //double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    
    NSDate *date = [self convertDateFromString:[dicData stringValueForJSON:@"run_time"] isGMT:YES formate:CDateFormater];
    double sessionStartTimeStamp = [date timeIntervalSince1970];
    
    double difTimeStamp = currentTimestamp - sessionStartTimeStamp;
    
    [self StopTimer];

    NSLog(@"difTimeStamp ======= >> %f",difTimeStamp);
    
    if(difTimeStamp < 0)
        seconds = 10;
    else
    {
        seconds = 10 - difTimeStamp;
    }
    
    [self StopTimer];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeTick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

-(void)timeTick:(NSTimer *)timer1
{
//    NSLog(@"Opponent Timer ========== >>> %d",seconds);
    
    // Cheking user availibility...
        NSMutableDictionary *dicData = [NSMutableDictionary new];
        [dicData setObject:@"9" forKey:@"user_available_status"];
        [dicData setObject:appDelegate.loginUser.user_id forKey:@"user_id"];
        [dicData setObject:strMyTeamType  forKey:@"type"];
        [dicData setObject:self.strSessionIDFromSearch forKey:@"session_id"];
        [dicData setObject:[NSString stringWithFormat:@"%d",seconds] forKey:@"time_checking_Opponent_screen"];
        [appDelegate MQTTNotifyToServerForUserAvailability:dicData Topic:self.strSessionIDFromSearch];

    
    if (seconds < 0)
    {
        if(seconds == -1)
        {
            viewQuitContainer.hidden = YES;
            viewVideo.hidden = NO;
            [player play];
        }
        
        switch (seconds)
        {
            case -1:
            {
                currentPlayingTime = 1;
            }
                break;
            case -2:
            {
                currentPlayingTime = 2;
            }
                break;
            case -3:
            {
                currentPlayingTime = 3;
            }
                break;
            case -4:
            {
                currentPlayingTime = 4;
            }
                break;
            case -5:
            {
                [self StopTimer];
            }
                break;
            default:
                break;
        }
        
    }
    else
    {
        viewVideo.hidden = YES;
        lblTimer.text = [NSString stringWithFormat:@"%d",seconds];
    }
    
    seconds--;
}

-(void)StopTimer
{
    [timer invalidate];
    timer = nil;
}


#pragma mark - Table View Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isSolo)
        return 1;
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isSolo)
        return arrTeamFirst.count;
    
    return section == 0 ? arrTeamFirst.count : arrTeamSecond.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSolo)
    {
        NSString *identifier = @"OpponentCell";
        OpponentCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil)
            cell = [[OpponentCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSDictionary *dicSoloPlayer =arrTeamFirst[indexPath.row];
        cell.imgVeriefiedUser.hidden = [[dicSoloPlayer numberForJson:@"celebrity"] isEqual:@0];
        
        cell.lblUserName.text = [dicSoloPlayer stringValueForJSON:@"user_name"];
        [cell.imgUser setImageWithURL:[appDelegate resizeImage:@"90" Height:nil imageURL:[dicSoloPlayer stringValueForJSON:@"picture"]] placeholderImage:nil options:SDWebImageRetryFailed usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

        if ([[dicSoloPlayer valueForKey:@"run"] isKindOfClass:[NSDictionary class]] && [dicSoloPlayer objectForKey:@"run"])
        {
            NSDictionary *dicRun = [dicSoloPlayer valueForKey:@"run"];
            cell.lblRuns.text = [dicRun stringValueForJSON:@"total_runs"].intValue == 1 ? [NSString stringWithFormat:@"%@ Run",[dicRun stringValueForJSON:@"total_runs"]] : [NSString stringWithFormat:@"%@ Runs",[dicRun stringValueForJSON:@"total_runs"]];
            cell.imgRank.image = [appDelegate GetImageWithUserPosition:[dicRun stringValueForJSON:@"rank_icon_type"].intValue];
        }
        return cell;
    }
    else
    {
        NSString *identifier = @"TeamMatchedCell";
        TeamMatchedCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (cell == nil)
            cell = [[TeamMatchedCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSDictionary *dicTeam = indexPath.section == 0 ? arrTeamFirst[indexPath.row] : arrTeamSecond[indexPath.row];

        cell.imgTeamTag.image = indexPath.section == 0 ?  [UIImage imageNamed:@"ic_team_red"] : [UIImage imageNamed:@"ic_team_blue"];
        
        cell.imgVeriefiedUser.hidden = [[dicTeam numberForJson:@"celebrity"] isEqual:@0];
        cell.lblUserName.text = [dicTeam stringValueForJSON:@"user_name"];
        [cell.imgUser setImageWithURL:[appDelegate resizeImage:@"90" Height:nil imageURL:[dicTeam stringValueForJSON:@"picture"]] placeholderImage:nil options:SDWebImageRetryFailed usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

        if ([[dicTeam valueForKey:@"run"] isKindOfClass:[NSDictionary class]] && [dicTeam objectForKey:@"run"])
        {
            NSDictionary *dicRun = [dicTeam valueForKey:@"run"];
            cell.lblRuns.text = [dicRun stringValueForJSON:@"total_runs"].intValue == 1 ? [NSString stringWithFormat:@"%@ Run",[dicRun stringValueForJSON:@"total_runs"]] : [NSString stringWithFormat:@"%@ Runs",[dicRun stringValueForJSON:@"total_runs"]];
            cell.imgRank.image = [appDelegate GetImageWithUserPosition:[dicRun stringValueForJSON:@"rank_icon_type"].intValue];
        }

        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(!self.isSolo)
    {
        TeamMatchedHeader *viewHeader = [TeamMatchedHeader viewFromXib];
        
        if (section == 0)
        {
            viewHeader.lblTeamName.textColor = CRGB(255, 72, 93);
            viewHeader.lblTeamName.text = @"TEAM RED";
            viewHeader.imgTag.image = [UIImage imageNamed:@"ic_team_red"];
        }
        else
        {
            viewHeader.lblTeamName.textColor = CRGB(61, 205, 252    );
            viewHeader.lblTeamName.text = @"TEAM BLUE";
            viewHeader.imgTag.image = [UIImage imageNamed:@"ic_team_blue"];
        }
        
        return viewHeader;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(!self.isSolo)
        return 40;
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


#pragma mark - Move On search screen

-(void)moveOnSearchScreen
{
    if (!isAllowToGoOnSearchScreen)
        return;
    
    isAllowToGoOnSearchScreen = NO;
    
    if (!self.strSessionIDFromSearch)
        return;
    
    [appDelegate MQTTUnsubscribeWithTopic:self.strSessionIDFromSearch];
    [self.dicDataCreateSesionFromFind setObject:self.strSessionIDFromSearch forKey:@"session_id"];
    [appDelegate createLiveSession:self.dicDataCreateSesionFromFind completed:^(id responseObject, NSError *error)
     {
         [self StopTimer];
         if (responseObject && !error)
         {
             NSDictionary *dicRes = [responseObject valueForKey:CJsonData];
             
             NSLog(@"Opponent  New Session ID ======= >> %@",[dicRes stringValueForJSON:@"_id"]);
             
             if (self.configureRecreateSession)
                 self.configureRecreateSession([dicRes stringValueForJSON:@"_id"],dicRes);
             
             [self removeMQTTOpponentNotificationObserver];
             [self.navigationController popViewControllerAnimated:YES];
         }
         else
         {
             [self StopTimer];
             [self.navigationController popToRootViewControllerAnimated:YES];
         }
     }];
}

#pragma mark - Move On Runnig Screen screen
-(void)moveOnRunningScreen
{
    [timer invalidate];
    timer = nil;
    
    [player pause];
    [self StopTimer];
    
    viewVideo.hidden = YES;
    player = nil;
    
    if (!isAllowToGoOnSearchScreen)
        return;
    
    isAllowToGoOnSearchScreen = NO;
    
    [appDelegate MQTTUnsubscribeWithTopic:self.strSessionIDFromSearch];
    
    appDelegate.window.rootViewController = appDelegate.objSuperRunning;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeMQTTOpponentNotificationObserver];
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        if (appDelegate.configureRunningSessionStart)
            appDelegate.configureRunningSessionStart(self.strSessionIDFromSearch,nil);
    });
}

#pragma mark - Action Event

-(IBAction)btnBackCLK:(id)sender
{
    viewQuitContainer.hidden = NO;
    
    [btnNoWay touchUpInsideClicked:^{
        viewQuitContainer.hidden = YES;
    }];
    
    [btnYes touchUpInsideClicked:^{
        if (!self.strSessionIDFromSearch)
            return;
        
        [self StopTimer];
        
        [appDelegate MQTTUnsubscribeWithTopic:self.strSessionIDFromSearch];
        [appDelegate QuitJoinedLiveRunSession:self.strSessionIDFromSearch completed:^(id responseObject, NSError *error)
        {
            [self StopTimer];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    NSLog(@"playerItemDidReachEnd ============= >>>>>>");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moveOnRunningScreen];
    });
}

@end
