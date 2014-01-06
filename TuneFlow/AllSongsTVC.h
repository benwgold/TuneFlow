//
//  AllSongsTVC.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueCommModel.h"

@interface AllSongsTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate, BlueCommDelegate>

@property(strong, nonatomic) NSArray *sharedSongs;
@property(strong, nonatomic) BlueCommModel *blueComm;

@property(strong, nonatomic) NSMutableArray *selectedSongs;

@property(strong, nonatomic) NSArray * finalPlaylist;


@property (strong, nonatomic) IBOutlet UITableView *tableView;

-(void)setSharedSongs:(NSArray *)sharedSongs;
-(void)setBlueComm:(BlueCommModel *)blueComm;

-(void)transferComplete:(BOOL)successful;
-(NSData *)getFirstData;
-(void)processFirstData:(NSData *)data;
-(NSData *)getSecondData;
-(void)processSecondData:(NSData *)data;

@end
