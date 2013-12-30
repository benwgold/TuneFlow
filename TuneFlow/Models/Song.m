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

@end
