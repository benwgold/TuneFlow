//
//  TFViewController.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BlueCommModel.h"

#import <MediaPlayer/MediaPlayer.h>
#import "AllSongsTVC.h"
#import "Models/Song.h" 

@interface TFViewController : UIViewController  <BlueCommDelegate>


@property (strong, nonatomic) IBOutlet UIView *syncButton;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *statusView;

@property(nonatomic) NSArray *sharedSongs;


@property (nonatomic, strong) BlueCommModel *blueComm;


-(void)transferComplete:(BOOL)successful;
-(NSData *)getFirstData;
-(void)processFirstData:(NSData *)data;
-(NSData *)getSecondData;
-(void)processSecondData:(NSData *)data;


@end
