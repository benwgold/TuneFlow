//
//  Song.m
//  TuneFlow
//
//  Created by Ben Goldberger on 12/25/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import "Song.h"

@implementation Song


-(id) init{
    self = [super init];
    return self;
}

-(id) initWithTitle:(NSString *)title withArtist:(NSString *)artist withPlaybackDuration:(NSNumber *)playbackDuration withAlbum:(NSString *)album
{
    if (self = [super init])
    {
        self.title = title;
        self.artist = artist;
        self.playbackDuration = playbackDuration;
        self.album = album;
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.title forKey:@"1"];
    [aCoder encodeObject:self.artist forKey:@"2"];
    [aCoder encodeObject:self.playbackDuration forKey:@"3"];
    [aCoder encodeObject:self.album forKey:@"4"];

}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        
        [self setTitle:[aDecoder decodeObjectForKey:@"1"]];
        [self setArtist:[aDecoder decodeObjectForKey:@"2"]];
        [self setPlaybackDuration:[aDecoder decodeObjectForKey:@"3"]];
        [self setAlbum:[aDecoder decodeObjectForKey:@"4"]];
    }
    return self;
}

@end
