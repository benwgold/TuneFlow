//
//  AllSongsTVC.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AllSongsTVC : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property(strong, nonatomic) NSArray *sharedSongs;

@property(strong, nonatomic) NSMutableSet *selectedSongs;



@property (strong, nonatomic) IBOutlet UITableView *tableView;

-(void)setSharedSongs:(NSArray *)sharedSongs;
@end
