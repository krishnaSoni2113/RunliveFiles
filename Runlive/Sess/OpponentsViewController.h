//
//  OpponentsViewController.h
//  RunLive
//
//  Created by mac-0005 on 11/15/16.
//  Copyright © 2016 mac-0005. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^recreateSession)(NSString *strSessionId,NSDictionary *dicRes);

@interface OpponentsViewController : SuperViewController<AVAudioSessionDelegate>
{
    IBOutlet UILabel *lblTitle,*lblTimer;
    
    IBOutlet UITableView *tblPlayer;
    IBOutlet UIView *viewVideo;
    IBOutlet UIView *viewQuitContainer,*viewQuit;
    IBOutlet UIButton *btnNoWay,*btnYes;
}

@property(strong,nonatomic) recreateSession configureRecreateSession;

@property(atomic,assign) BOOL isSolo;
@property(strong,nonatomic) NSString *strSessionIDFromSearch;

// This dictionary contain Session create related data...
@property(strong,nonatomic) NSDictionary *dicDataCreateSesionFromFind;

// This dictionary contain Find player data...
@property(strong,nonatomic) NSDictionary *dicSesionPlayerFromFind;



@end
