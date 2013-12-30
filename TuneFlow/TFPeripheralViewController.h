//
//  TFPeripheralViewController.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/25/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface TFPeripheralViewController : UIViewController <CBPeripheralManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *peripheralButton;

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *customCharacteristic;
@property (nonatomic, strong) CBMutableService *customService;
@property (nonatomic) NSInteger sendDataIndex;
@property (nonatomic) NSData *dataToSend;

#define NOTIFY_MTU      20

@end

