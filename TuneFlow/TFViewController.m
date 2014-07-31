//
//  TFViewController.m
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import "TFViewController.h"

#import <CoreLocation/CoreLocation.h>

@interface TFViewController ()

@property(nonatomic) bool syncStarted;
@property NSInteger counter;
@end


@implementation TFViewController

-(void)transferComplete:(BOOL)successful {
    if (successful){
        [self displayTransferUpdates:NO];
        
        AllSongsTVC *vc =[self.storyboard instantiateViewControllerWithIdentifier:@"AllSongs"];
        [vc setSharedSongs: self.sharedSongs];
        [vc setBlueComm: self.blueComm];
        self.blueComm.delegate = vc;
        [self.navigationController pushViewController:vc animated:true];
    }
    else{
        NSLog(@"ERROR: Transfer was not successful");
    }
}

- (void)viewDidLoad
{
    self.blueComm = [[BlueCommModel alloc]init];
    self.blueComm.delegate = self;
}


- (IBAction)syncWithDevice:(id)sender {
    if (!self.syncStarted){ //make sure sync only called once, can cause issues otherwise
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserverForName:nil
                            object:nil
                             queue:nil
                        usingBlock:^(NSNotification *notification)
         {
             NSString *message = [[notification userInfo] objectForKey:[BlueCommModel notificationName]];
             _statusView.text =  [NSString stringWithFormat:@"%@", message];
         }];
        [self displayTransferUpdates:YES];
        self.syncStarted = true;
        //get data to send to central connecters
        [self.blueComm setupTransfer:0];
    }
}

-(void)displayTransferUpdates:(BOOL)comm{
    if (comm){
        [[NSNotificationCenter defaultCenter]addObserverForName:[BlueCommModel notificationName]
                                                object:nil
                                                queue:nil
                                                usingBlock:^(NSNotification *notification)
         {
             _statusView.text = [notification.userInfo objectForKey:[BlueCommModel notificationName]];
         }];
    }
    else{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:[BlueCommModel notificationName] object:nil];
        _statusView.text = @"";
    }
}
         
-(NSData *)getFirstData{
    return [self getSongData];
}

-(void)processFirstData:(NSData *)data{
    NSDictionary *externalSongsToTimes = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self.textView setText:[externalSongsToTimes description]];
    self.sharedSongs = (NSArray *)[self findSharedSongs:externalSongsToTimes];
    
}
-(NSData *)getSecondData{
    if ([self.sharedSongs count] > 0){
        return [NSKeyedArchiver archivedDataWithRootObject:[self getSongTimeDict:self.sharedSongs]];
    }
    else{
        NSLog(@"ERROR: No shared songs found");
        return nil;
    }
}

-(void)processSecondData:(NSData *)data{
    NSDictionary *sharedSongsToTimes = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self.textView setText:[sharedSongsToTimes description]];
    self.sharedSongs = (NSArray *)[self findSharedSongs:sharedSongsToTimes];
}

-(NSDictionary *)getSongTimeDict:(NSArray *)songs{
    NSMutableDictionary *returnDict = [[NSMutableDictionary alloc]init];
    for (Song *song in songs){
        [returnDict setObject:[song playbackDuration] forKey:[song title]];
    }
    return returnDict;
}
- (NSArray *)findSharedSongs:(NSDictionary *)potentialSongsToTimes{
    NSMutableArray *sharedSongs = [[NSMutableArray alloc]init];
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithBool:0] forProperty:MPMediaItemPropertyIsCloudItem comparisonType:MPMediaPredicateComparisonEqualTo];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    [songQuery addFilterPredicate:predicate];
    NSArray *itemsFromGenericQuery = [songQuery items];
    for (MPMediaItem *song in itemsFromGenericQuery) {
            NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
            NSNumber *potentialSongTime = [potentialSongsToTimes objectForKey:songTitle]; //theirSongTime nil if not on device (will occur often)
            
            //see if song in library is included in set of songs sent from other iPhone
            if (potentialSongTime != nil){
                NSNumber *ourSongTime = [song valueForProperty:MPMediaItemPropertyPlaybackDuration];
                //...and see if time is the same, if so, add to set.
                if([potentialSongTime isEqual: ourSongTime]){
                    NSString *songAlbum = [song valueForProperty: MPMediaItemPropertyAlbumTitle];
                    NSString *songArtist = [song valueForProperty: MPMediaItemPropertyArtist];
                    Song *songObj = [[Song alloc] initWithTitle:songTitle withArtist:songArtist withPlaybackDuration:ourSongTime withAlbum:songAlbum];
                    [sharedSongs addObject:songObj];
                }
            }
    }
    return sharedSongs;
}

-(NSData *)getSongData{
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [songQuery items];
    //NSMutableArray *allSongs = [[NSMutableArray alloc]init];
    NSMutableDictionary *songsToTimes = [[NSMutableDictionary alloc]init];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
        //const NSString *songAlbum = [song valueForProperty: MPMediaItemPropertyAlbumTitle];
        //const NSString *songArtist = [song valueForProperty: MPMediaItemPropertyArtist];
        NSNumber *songLength = [song valueForProperty: MPMediaItemPropertyPlaybackDuration];
        //Song *songObj = [[Song alloc] initWithTitle:songTitle withArtist:songArtist withPlaybackDuration:songLength withAlbum:songAlbum];
        //[allSongs addObject:songObj];
        [songsToTimes setValue:songLength forKey:songTitle];
    }
    return [NSKeyedArchiver archivedDataWithRootObject:songsToTimes];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
