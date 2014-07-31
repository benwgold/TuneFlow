//
//  MediaPlayerVC.h
//  TuneFlow
//
//  Created by Ben Goldberger on 1/3/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "BlueCommModel.h"

static const double START_TIME_OFFSET_SECS = 10;

@interface MediaPlayerVC : UIViewController <BlueCommDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumView;

@property (strong, nonatomic) BlueCommModel *blueComm;

@property (strong, nonatomic) NSArray *songTitles;
@property (strong, nonatomic) NSArray *mediaItemPlaylist;


@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (nonatomic) NSInteger curSongIndex;

@property (nonatomic) double offset;
@property (nonatomic) bool isLead;

@property (nonatomic) double startSettingUpReturnTime;

-(void)playMusic;

//bluecomm delegate methods
-(void)transferComplete:(BOOL)successful;
-(NSData *)getFirstData;
-(void)processFirstData:(NSData *)data;
-(NSData *)getSecondData;
-(void)processSecondData:(NSData *)data;
@end
