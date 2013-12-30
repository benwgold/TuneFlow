//
//  Song.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/25/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Song : NSObject

@property(weak, nonatomic) const NSString *title;

@property(weak, nonatomic) const NSString *artist;

@property(weak, nonatomic) const NSNumber *playbackDuration;

@property(weak, nonatomic) const NSString *album;

-(id) init;

-(id) initWithTitle:(NSString *)title withArtist:(NSString *)artist withPlaybackDuration:(NSNumber *)playbackDuration withAlbum:(NSString *)album;

@end
