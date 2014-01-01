//
//  TFViewController.h
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BlueCommModel.h"

#import <MediaPlayer/MediaPlayer.h>
#import "AllSongsTVC.h"
#import "Models/Song.h" 


#import <CoreBluetooth/CoreBluetooth.h>

@interface TFViewController : UIViewController  <BlueCommDelegate>//<CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>


@property (strong, nonatomic) IBOutlet UIView *syncButton;

@property (weak, nonatomic) IBOutlet UITextView *textView;


@property (nonatomic, strong) BlueCommModel *blueComm;

-(void)transferComplete:(BOOL)successful;
/*
@property(nonatomic) bool alreadyReceivedData;
@property(nonatomic) bool alreadySentData;

//central properties
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableData *data;

//peripheral properties
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *customCharacteristic;
@property (nonatomic, strong) CBMutableService *customService;
@property (nonatomic) NSInteger sendDataIndex;
@property (nonatomic) NSData *dataToSend;

#define NOTIFY_MTU      20
*/
@end
