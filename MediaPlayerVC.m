//
//  MediaPlayerVC.m
//  TuneFlow
//
//  Created by Ben Goldberger on 1/3/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
