//
//  MediaPlayerVC.m
//  TuneFlow
//
//  Created by Ben Goldberger on 1/3/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//


//- (id)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)ti target:(id)t selector:(SEL)s userInfo:(id)ui repeats:(BOOL)rep;
#import "MediaPlayerVC.h"

@interface MediaPlayerVC ()

@end

@implementation MediaPlayerVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.textView.text = [self.playlist description];
}

-(void)transferComplete:(BOOL)successful{

    
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: .1 target: self selector:@selector(updateTime) userInfo: nil repeats:YES];
}
-(void)updateTime{
    double c = CFAbsoluteTimeGetCurrent();
    if (self.isLead){
        c+=self.offset;
    }
    self.textView.text = [NSString stringWithFormat:@"%f", c];
}

-(NSData *)getFirstData{
    self.isLead = true;
    double t = CFAbsoluteTimeGetCurrent();
    return [NSData dataWithBytes:&t length:sizeof(double)];
}
-(void)processFirstData:(NSData *)data{
    double d;
    assert([data length] == sizeof(d));
    memcpy(&d, [data bytes], sizeof(d));
    double difference = CFAbsoluteTimeGetCurrent() - d;
    self.offset = difference;
    
    self.startSettingUpReturnTime = CFAbsoluteTimeGetCurrent();
}
-(NSData *)getSecondData{
    double timeSettingUpReturnTime = CFAbsoluteTimeGetCurrent()-self.startSettingUpReturnTime;
    
    double t = self.offset;
    return [NSData dataWithBytes:&t length:sizeof(double)];
}
-(void)processSecondData:(NSData *)data{
    double d;
    assert([data length] == sizeof(d));
    memcpy(&d, [data bytes], sizeof(d));
    self.offset = d;
    //self.plusOffset = true;
}
/*
-(NSArray *)constructMediaItemArray:(NSArray *)arr{
    NSMutableArray *items = [[NSMutableArray alloc]initWithArray:arr];
    NSMutableArray *sharedSongs = [[NSMutableArray alloc]init];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [songQuery items];
    //NSMutableDictionary *internalSongsToTimes = [[NSMutableDictionary alloc]init];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSLog(@"Size of mediaitem");
        NSLog([[NSString alloc]initWithFormat:@"%lu", sizeof(song)]);
        if (![song valueForProperty:MPMediaItemPropertyIsCloudItem]){
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
                    NSLog(@"Size of songobj");
                    NSLog([[NSString alloc]initWithFormat:@"%lu", sizeof(songObj)]);
                    [sharedSongs addObject:songObj];
                }
            }
        }
    }
}

- (NSArray *)findSharedSongs:(NSDictionary *)potentialSongsToTimes{
    NSMutableArray *sharedSongs = [[NSMutableArray alloc]init];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [songQuery items];
    //NSMutableDictionary *internalSongsToTimes = [[NSMutableDictionary alloc]init];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        NSLog(@"Size of mediaitem");
        NSLog([[NSString alloc]initWithFormat:@"%lu", sizeof(song)]);
        if (![song valueForProperty:MPMediaItemPropertyIsCloudItem]){
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
                    NSLog(@"Size of songobj");
                    NSLog([[NSString alloc]initWithFormat:@"%lu", sizeof(songObj)]);
                    [sharedSongs addObject:songObj];
                }
            }
        }
    }
    return sharedSongs;
}
  */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
