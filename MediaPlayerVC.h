//
//  MediaPlayerVC.h
//  TuneFlow
//
//  Created by Ben Goldberger on 1/3/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueCommModel.h"

@interface MediaPlayerVC : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) BlueCommModel *blueComm;
@property (strong, nonatomic) NSArray *playlist;

@property (strong, nonatomic) NSArray *mediaItemPlaylist;


@property (nonatomic) double offset;
@property (nonatomic) bool isLead;

@property (nonatomic) double startSettingUpReturnTime;

-(void)startPlay;

-(void)transferComplete:(BOOL)successful;
-(NSData *)getFirstData;
-(void)processFirstData:(NSData *)data;
-(NSData *)getSecondData;
-(void)processSecondData:(NSData *)data;
@end
