//
//  BlueCommModel.h
//  TuneFlow
//
//  Created by Ben Goldberger on 1/1/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Models/Song.h"

#import <CoreBluetooth/CoreBluetooth.h>


//delegate protocol that allows the bluecomm to let its owning VC to do things after transfer
@protocol BlueCommDelegate <NSObject>
@required
-(void)transferComplete:(BOOL)successful ;
@end


@interface BlueCommModel : NSObject <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property(nonatomic, weak) id delegate;


@property(nonatomic) bool alreadyReceivedData;
@property(nonatomic) bool alreadySentData;


@property(nonatomic) bool syncStarted;
@property(nonatomic) NSArray *sharedSongs;

//central properties
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableData *data;
@property (weak, nonatomic) IBOutlet UITextView *textView;

//peripheral properties
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *customCharacteristic;
@property (nonatomic, strong) CBMutableService *customService;
@property (nonatomic) NSInteger sendDataIndex;
@property (nonatomic) NSData *dataToSend;

#define NOTIFY_MTU      20

-(id)init;
-(void)syncWithDevice;

@end
