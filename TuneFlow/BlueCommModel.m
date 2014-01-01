//
//  BlueCommModel.m
//  TuneFlow
//
//  Created by Ben Goldberger on 1/1/14.
//  Copyright (c) 2014 Ben Goldberger. All rights reserved.
//

#import "BlueCommModel.h"

@interface BlueCommModel()
@end


static NSString * const kServiceUUID = @"2F1B1054-D3AE-4915-A2F6-161654BF12C7";
static NSString * const kCharacteristicUUID = @"E275E53A-EE3F-46F2-B408-727EEFE9FA98";


@implementation BlueCommModel

- (id)init
{
    self = [super init];
    
    _data = [[NSMutableData alloc] init];
    _alreadyReceivedData = false;
    _alreadySentData = false;
    _syncStarted = false;
    return self;
    
}
- (void)syncWithDevice{
    if (!self.syncStarted){ //make sure sync only called once, can cause issues otherwise
        self.syncStarted = true;
        //get data to send to central connecters
        self.dataToSend = [self getSongData];
        [self createCentral];
    }
}

-(void) createCentral{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            // Scans for any peripheral
            
            [self performSelector:@selector(createPeripheral) withObject:nil afterDelay:5.0];
            
            [self.centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID] ] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
            NSLog(@"Scanning started");
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        // Connects to the discovered peripheral
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected To The Peripheral");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        [self cleanupPeripheral];
        return;
    }
    NSLog(@"trying to find services");
    for (CBService *service in aPeripheral.services) {
        NSLog(@"service found");
        NSLog(@"Service found with UUID: %@", service.UUID);
        
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        [self cleanupPeripheral];
        return;
    }
    NSLog(@"Found characteristic");
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        // We have, so show the data,
        NSDictionary *externalSongsToTimes = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
        
        
        
        [self.textView setText:[externalSongsToTimes description]];
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        //[self.centralManager cancelPeripheralConnection:peripheral];
        self.sharedSongs = (NSArray *)[self findSharedSongs:externalSongsToTimes];
        [self cleanupPeripheral];
        //self.peripheral = nil;
        self.alreadyReceivedData = TRUE;
        if (self.delegate != nil){
            if ([self.sharedSongs count] > 0){
                if (self.alreadySentData){
                    [self.delegate transferComplete:YES];
                }
                else{
                    self.dataToSend = [NSKeyedArchiver archivedDataWithRootObject:[self getSongTimeDict:self.sharedSongs]];
                    [self createPeripheral];
                }
                
            }
            else{
                NSLog(@"ERROR: No shared songs found");
                [self.delegate transferComplete:NO];
            }
        }
        else{
            NSLog(@"ERROR: No delegate for bluecomm specified");
        }
    }
    
    else{
        [self.textView setText:@"Getting Text..."];
        // Otherwise, just add the data on to what we already have
    }
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
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
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [songQuery items];
    //NSMutableDictionary *internalSongsToTimes = [[NSMutableDictionary alloc]init];
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

/*
 - (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
 if (error) {
 NSLog(@"Error changing notification state: %@", error.localizedDescription);
 }
 
 // Exits if it's not the transfer characteristic
 if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
 return;
 }
 
 // Notification has started
 if (characteristic.isNotifying) {
 NSLog(@"Notification began on %@", characteristic);
 [peripheral readValueForCharacteristic:characteristic];
 } else { // Notification has stopped
 // so disconnect from the peripheral
 NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
 [self.centralManager cancelPeripheralConnection:self.peripheral];
 [self cleanupPeripheral];
 self.peripheral
 }
 }*/

- (void)cleanupPeripheral{
    // Don't do anything if we're not connected
    if (!self.peripheral.isConnected) {
        return;
    }
    // See if we are subscribed to a characteristic on the peripheral
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
}
////////////////////////////////
//
// PERIPHERAL METHODS
//
///////////////////////////////
//couldnt find existing peripheral. Stop centralManager search and make peripheral ourselves
- (void)createPeripheral
{
    //only create a peripheral if one has yet to be found
    //if (self.peripheral == nil){
    NSLog(@"existing peripheral not found. Creating one");
    
    //stop existing scan
    [self.centralManager stopScan];
    //make a peripheral manager
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    //}
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

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error != nil){
        NSLog([error description]);
    }
    else {
        NSLog(@"service added successfully");
        // Starts advertising the service
        int serverNum = (self.alreadyReceivedData) ? 2 : 1;
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey : [NSString stringWithFormat:@"ICSERVER%i", serverNum], CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:kServiceUUID]] }];
    }
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            [self setupService];
            break;
        default:
            NSLog(@"Peripheral Manager did change state");
            break;
    }
}
-(void) setupService
{
    NSLog(@"Setting up service");
    // Creates the characteristic UUID
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    
    // Creates the characteristic
    self.customCharacteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    // Creates the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    // Creates the service and adds the characteristic to it
    self.customService = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    // Sets the characteristics for this service
    self.customService.characteristics = @[self.customCharacteristic];
    
    // Publishes the service
    NSLog(@"Publish Service state...");
    
    [self.peripheralManager addService:self.customService];
}
/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    NSLog(@"sending piece of data");
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.customCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            
            //do i need something here?
            NSLog(@"Sent: EOM");
            self.alreadySentData = TRUE;
            if(self.alreadyReceivedData){
                [self.delegate transferComplete:YES];
            }else{
                [self switchPeripheralToCentral];
                
            }
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.customCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.customCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
                
                
                [self switchPeripheralToCentral];
            }
            
            
            
            return;
        }
    }
}

-(void)switchPeripheralToCentral{
    if(self.peripheralManager != nil){
        [self.peripheralManager stopAdvertising];
        //self.centralManager= nil; // not really necessary i don't think, but clarifies old central is done
        [self performSelector:@selector(createCentral) withObject:nil afterDelay:2]; //wait 2 seconds so we know peripheral is setup on time
    }
}
/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    //NSString *str = [NSString stringWithFormat:@"Sent this data!"];
    //self.dataToSend = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    [self sendData];
}

@end

