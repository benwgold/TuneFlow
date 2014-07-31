//
//  MediaPlayerVC.m
//  TuneFlow
//
//  Created by Ben Goldberger on 1/3/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//


//- (id)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)ti target:(id)t selector:(SEL)s userInfo:(id)ui repeats:(BOOL)rep;
#import "MediaPlayerVC.h"
#import "Song.h"

@interface MediaPlayerVC ()
@property double startTime;
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
    //build playlist
    [self setMediaItemPlaylist:self.songTitles];
    
    
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //set up audio player
    if ([self.mediaItemPlaylist count] > 0){
        self.audioPlayer = [[AVPlayer alloc] init];
    }
    else{
        [self returnToSongList];
        //exit(1);
    }
    self.offset = 0;
    
    //listen for notificatiosn from bluecomm, and begin transfer
    [self displayTransferUpdates:YES];
    [self.blueComm setupTransfer:2];
}

-(void)displayTransferUpdates:(BOOL)comm{
    if (comm){
        [[NSNotificationCenter defaultCenter]addObserverForName:[BlueCommModel notificationName]
                            object:nil
                             queue:nil
                        usingBlock:^(NSNotification *notification)
         {
             _titleLabel.text = [notification.userInfo objectForKey:[BlueCommModel notificationName]];
         }];
    }
    else{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:[BlueCommModel notificationName] object:nil];
    }
}

-(void)playCurrentSong{
    MPMediaItem* curSong = [self.mediaItemPlaylist objectAtIndex:self.curSongIndex];
    AVPlayerItem *currentItem = [AVPlayerItem playerItemWithURL:[curSong valueForProperty:MPMediaItemPropertyAssetURL]];
    [self.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
    [self.audioPlayer play];
    _titleLabel.text = [curSong valueForProperty:MPMediaItemPropertyTitle];
    _artistLabel.text = [curSong valueForProperty:MPMediaItemPropertyArtist];
    MPMediaItemArtwork *art = [curSong valueForProperty:MPMediaItemPropertyArtwork];
    _albumView.image = [art imageWithSize:_albumView.bounds.size];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:currentItem];
}

//Play next song automatically
-(void)itemDidFinishPlaying:(AVPlayerItem *)item{
    self.curSongIndex++;
    //Return to list if completed.
    if (self.curSongIndex >= [self.mediaItemPlaylist count]){
        [self returnToSongList];
    }
    [self playCurrentSong];
}


-(void)returnToSongList{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setMediaItemPlaylist:(NSArray *)mediaItemPlaylist{
    NSMutableArray *mediaItems = [[NSMutableArray alloc]init];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [songQuery items];
    //
    //TODO: Brute force way of finding matching songs.  Find better way.
    //
    for (int i = 0; i<[mediaItemPlaylist count]; i++){
        //Song *targetSong = [mediaItemPlaylist objectAtIndex:i];
        NSString *targetSong = [mediaItemPlaylist objectAtIndex:i];
        for (MPMediaItem *song in itemsFromGenericQuery) {
            if ([targetSong isEqualToString:[song valueForProperty:MPMediaItemPropertyTitle]]){//[targetSong title]){
                //if (![song valueForProperty:MPMediaItemPropertyIsCloudItem]){
                //see if song in library is included in set of songs sent from other iPhone
                    [mediaItems addObject:song];
                //}
            }
        }
    }
    _mediaItemPlaylist = (NSArray *)mediaItems;
}

-(void)transferComplete:(BOOL)successful{
    NSLog(@"Transfer Complete");
    //Stop displaying transfer updates
    [self displayTransferUpdates:NO];
    [self updateTime];
    NSDate *synchronizedDate = [NSDate dateWithTimeInterval:-self.offset sinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:self.startTime]];
    NSTimer *t = [[NSTimer alloc]initWithFireDate:synchronizedDate interval:0 target:self selector:@selector(playCurrentSong) userInfo:nil repeats:FALSE];
    [[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
}

-(void)updateTime{
    double c = CFAbsoluteTimeGetCurrent();
    //self.textView.text = [NSString stringWithFormat:@"Corrected Time: %f System Time: %f Offset: %f SynchronizedDate: %f", c+self.offset, c, self.offset, self.startTime];
}

-(NSData *)getFirstData{
    
    self.isLead = true;
    /*
    double t = CFAbsoluteTimeGetCurrent();
    return [NSData dataWithBytes:&t length:sizeof(double)];
     */
    return [NSData data];
}
-(void)processFirstData:(NSData *)data{
    double d;
    assert([data length] == sizeof(d));
    memcpy(&d, [data bytes], sizeof(d));
    double difference = d- CFAbsoluteTimeGetCurrent() ;
    self.offset = difference;
    self.startSettingUpReturnTime = CFAbsoluteTimeGetCurrent();
}
-(NSData *)getSecondData{
    self.isLead = false;

    /*self.startTime = CFAbsoluteTimeGetCurrent();
    double t =  self.startTime;
    NSLog([NSString stringWithFormat:@"Sending time: %f", t]);
    NSData *data =[NSData dataWithBytes:&t length:sizeof(double)];

    double d;
    assert([data length] == sizeof(d));
    memcpy(&d, [data bytes], sizeof(d));
    NSLog([NSString stringWithFormat:@"Actually sent time: %f", d]);

    return data;
*/
    return [NSData data]; //equivelant to sending bluetooth timestamp
}

-(void)receiveBluetoothTimestamp:(double)timestamp{
    //only set starttime based on timestamp if you are not the lead or the "responder"
    if (!self.isLead){
        self.startTime = timestamp + START_TIME_OFFSET_SECS;
    }
}

-(void)processSecondData:(NSData *)data{
    double timestamp;
    assert([data length] == sizeof(timestamp));
    memcpy(&timestamp, [data bytes], sizeof(timestamp));
    //NSLog([NSString stringWithFormat:@"Receiving time: %f", timestamp]);

    self.startTime = timestamp + START_TIME_OFFSET_SECS;
    
    //self.offset = -.5*(timestamp-CFAbsoluteTimeGetCurrent());
    self.offset = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
