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

//notification properties
static NSString *const NOTIFICATION_NAME = @"bluecommstatus";
static NSString *const SETUP_KEY = @"setting up";
static NSString *const WAITING_KEY = @"waiting";
static NSString *const SCANNING_KEY = @"scanning";
static NSString *const CONNECTING = @"connecting";
static NSString *const SENDING_KEY = @"sending";
static NSString *const RECEIVING_KEY = @"receiving";

static NSString *const SETTING_ERROR_MESSAGE = @"Loading string could not be found";

//static NSString * const kServiceUUID = @"2F1B1054-D3AE-4915-A2F6-161654BF12C7";
//static NSString * const kCharacteristicUUID = @"E275E53A-EE3F-46F2-B408-727EEFE9FA98";


@implementation BlueCommModel


//Class method that returns the corresponding name of the notifications sent out
+ (NSString *)notificationName{
    return NOTIFICATION_NAME;
}

- (id)init
{
    self = [super init];
    _curTransferID = -1; //not transferring
    _data = [[NSMutableData alloc] init];
    _alreadyReceivedData = false;
    _alreadySentData = false;
    _syncInProgress = false;
    //arr = [NSArray arrayWithObjects:@"2F1B1054-D3AE-4915-A2F6-161654BF12C7",@"611836BD-BC8D-44D9-9059-C6BDC177CF01", nil];
    return self;
    
}
-(NSString *)getServiceUUID:(NSInteger)serviceID{
    switch (serviceID){
        case 0:
            return @"2F1B1054-D3AE-4915-A2F6-161654BF12C7";
        case 1:
            return @"611836BD-BC8D-44D9-9059-C6BDC177CF01";
        case 2:
            return @"171838F3-2D96-44FD-932D-EAA87236C3E5";
        default:
            NSLog(@"ERROR: Service id not valid nsinteger");
            return nil;
    }
}
-(NSString *)getCharacteristicUUID:(NSInteger)characteristicID{
    switch (characteristicID){
        case 0:
            return @"E275E53A-EE3F-46F2-B408-727EEFE9FA98";
        case 1:
            return @"4E51F472-ED4E-4AB9-AC97-AFCB7AA4D6DA";
        case 2:
            return @"97C05080-5C8F-4BCA-8184-87A1F6BEF593";
        default:
            NSLog(@"ERROR: Service id not valid nsinteger");
            return nil;
    }
}

- (NSString *)getStatusForKey: (NSString *)key{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"app-configs" ofType:@"plist"];
    NSDictionary *settings = [[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"bluetooth"];
    NSString * val = [settings objectForKey:key];
    if (val == nil){
        NSLog(SETTING_ERROR_MESSAGE);
    }
    return val;
}
-(void) notifyDelegateWithMessage:(NSString *)message{
    //Add content to user info. The dictionary KEY for the message is the same as the NOTIFICATION_NAME.
    NSDictionary* content = [[NSDictionary alloc] initWithObjectsAndKeys:message,NOTIFICATION_NAME, nil];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:NOTIFICATION_NAME object:nil userInfo:content]];
}


- (void)setupTransfer:(NSInteger)transferID{
    [self notifyDelegateWithMessage:[self getStatusForKey:SETUP_KEY]];
    
    if (!self.syncInProgress){ //make sure sync only called once, can cause issues otherwise
        self.curTransferID = transferID;
        self.syncInProgress = true;
        // Clear the data that we may already have
        [self.data setLength:0];
        //get data to send to central connecters
        self.dataToSend = [self.delegate getFirstData];
        if (self.centralManager == nil){
            [self createCentral];
        }
        else{
            if (self.peripheral != nil){
                switch (self.centralManager.state) {
                    case CBCentralManagerStatePoweredOn:
                        // Scans for any peripheral
                        [self.peripheral discoverServices:@[[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]]];
                        NSLog(@"Looking for services");
                        break;
                    default:
                        NSLog(@"Central Manager not in right state, even tho created");
                        break;
                }
            }
        }
    }
}

-(void) createCentral{
    if (self.centralManager == nil){
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    else{
        
    }
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            // Scans for any peripheral
            [self performSelector:@selector(handlePeripheralNotFound) withObject:nil afterDelay:5.0];
            
            [self.centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]] ] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
            NSLog(@"Scanning started");
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

//occurs after central manager created
-(void)handlePeripheralNotFound{
    if (self.peripheral == nil){
        if (self.peripheralManager == nil){
            [self createPeripheral];
        }
        else{
            NSLog(@"Thinking about creating peripheral because central still has self.peripheral = nil, but self.peripheralmanager!=nil");
        }
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
    [peripheral discoverServices:@[[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]]];
}
/*Looked for services, and found some
 */
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        [self stopNotifying];
        return;
    }
    NSLog(@"trying to find services");
    bool serviceAlreadySetup = false;
    //NSLog([aPeripheral.services description]);
    for (CBService *service in aPeripheral.services) {
        NSLog(@"service found");
        NSLog(@"Service found with UUID: %@", service.UUID);
        
        // Discovers the characteristics for a given service
        if ([service.UUID isEqual:[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]]) {
            serviceAlreadySetup = true;
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:[self getCharacteristicUUID:self.curTransferID]]] forService:service];
        }
    }
    //used when stuff is already created
    if((self.peripheralManager != nil) && !serviceAlreadySetup){
        //this happens to start the exchange after the very first exchange.  First guy looks for peripheral services. Cant find any.  Sets up service himself.
        [self setupService];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        [self stopNotifying];
        return;
    }
    NSLog(@"Found characteristic");
    if ([service.UUID isEqual:[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self getCharacteristicUUID:self.curTransferID]]]) {
                [self notifyDelegateWithMessage:[self getStatusForKey:RECEIVING_KEY]];
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
        NSLog(@"JUST GOT END OF MESSAGE!");
        // We have, so show the data,
        if (self.delegate != nil){

            //self.peripheral = nil;
            self.alreadyReceivedData = TRUE;
            if (self.alreadySentData){
                //just recieved data (this device had send it before receiving)
                [self.delegate processSecondData:(NSData *)self.data];
                self.syncInProgress = NO;
                self.alreadyReceivedData = false;
                self.alreadySentData = false;
                [self.delegate transferComplete:YES];
            }
            else
            {
                [self.delegate processFirstData:(NSData *)self.data];
                self.dataToSend = [self.delegate getSecondData];
                [self switchCentralToPeripheral];
            }
            // and disconnect from the scharactersitic
            //[self.centralManager cancelPeripheralConnection:peripheral];
            [self stopNotifying];
        }
        else{
            NSLog(@"ERROR: No delegate for bluecomm specified");
        }
    }
    
    else{
        // Otherwise, just add the data on to what we already have
    }
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}

-(void)switchCentralToPeripheral{
    if (self.dataToSend != nil){
        if (self.peripheralManager == nil){
            [self createPeripheral];
        }
        else{
            [self setupService];
        }
    }
    else
    {
        NSLog(@"ERROR: Data sent back by second device will be nil, no need to continue.");
        //no data to send, so end transfer
        //TODO MIGHT NEED TO CLEANUP
        self.syncInProgress = NO;
        self.alreadyReceivedData = false;
        self.alreadySentData = false;
        [self.delegate transferComplete:NO];
    }

}
/*
 - (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
 if (error) {
 NSLog(@"Error changing notification state: %@", error.localizedDescription);
 }
 
 // Exits if it's not the transfer characteristic
 if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:[self getCharacteristicUUID:self.curTransferID]]]) {
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
 [self stopNotifying];
 self.peripheral
 }
 }*/

- (void)stopNotifying{
    // Don't do anything if we're not connected
    if (!self.peripheral.isConnected) {
        return;
    }
    // See if we are subscribed to a characteristic on the peripheral
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self getCharacteristicUUID:self.curTransferID]]]) {
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
    //only create a peripheral manager not created yet
    if (self.peripheralManager == nil){
        
        NSLog(@"existing peripheral not found. Creating one");
    
        //stop existing scan
        //[self.centralManager stopScan];
        //make a peripheral manager
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error != nil){
        NSLog([error description]);
    }
    else {
        NSLog(@"service added successfully");
        // Starts advertising the service
        int serverNum = (self.alreadyReceivedData) ? 2 : 1;
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey : [NSString stringWithFormat:@"ICSERVER%i", serverNum], CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]] }];
    }
}
//occurs on peripheral manager init
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
    [self notifyDelegateWithMessage:[self getStatusForKey:WAITING_KEY]];

    NSLog(@"Setting up service");
    // Creates the characteristic UUID
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:[self getCharacteristicUUID:self.curTransferID]];
    
    // Creates the characteristic
    self.customCharacteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    // Creates the service UUID
    CBUUID *serviceUUID = [CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]];
    
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
            NSLog(@"JUST GOT To END OF MESSAGE!");
            self.alreadySentData = TRUE;
            if(self.alreadyReceivedData){
                //CANT remove services because services must exist to enter the didDiscoverServices callback, which is necessary to setup any new services
                //self.peripheralManager removeAllServices;
                self.syncInProgress = NO;
                self.alreadyReceivedData = false;
                self.alreadySentData = false;
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
        double doubleFromData;
        memcpy(&doubleFromData, [chunk bytes], sizeof(doubleFromData));
        NSLog(@"Sent: String-%@ Double-%f", stringFromData, doubleFromData);
        
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

        //[self.peripheralManager stopAdvertising];
        //not 100% necessary but for one time transfers, might as well
       // [self.peripheralManager removeAllServices];
        //self.centralManager= nil; // not really necessary i don't think, but clarifies old central is done
        if (self.centralManager == nil){
            [self performSelector:@selector(createCentral) withObject:nil afterDelay:2]; //wait 2 seconds so we know peripheral is setup on time
            //[self createCentral];
        }
        else{
            switch (self.centralManager.state) {
                case CBCentralManagerStatePoweredOn:
                    // Scans for any peripheral
                    if (self.peripheral == nil){
                        [self.centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]] ] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
                    }
                    [self performSelector:@selector(lookForServices) withObject:nil afterDelay:2];
                    break;
                default:
                    NSLog(@"Could not find newly created peripheral to send data back to first (central manager not correct state_");
                    break;
            }
        }
    }
}
-(void)lookForServices{
    [self notifyDelegateWithMessage:[self getStatusForKey:SCANNING_KEY]];

    // Search only for services that match our UUID
    NSLog(@"Looking for services");
    if (self.peripheral !=nil){
        [self.peripheral discoverServices:@[[CBUUID UUIDWithString:[self getServiceUUID:self.curTransferID]]]];
    }
    else{
        NSLog(@"ERROR: Central manager there...self.peripheral not.");
    }
}
/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [self notifyDelegateWithMessage:[self getStatusForKey:SENDING_KEY]];
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    //NSString *str = [NSString stringWithFormat:@"Sent this data!"];
    //self.dataToSend = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    //if time sync transfer, setting self.dataToSend is a signal to not measure time until just before sending.
    //Used for accuracy and time synchronization
    if (self.curTransferID == 2 && self.dataToSend == [NSData data]){
            double curTime = CFAbsoluteTimeGetCurrent();
            [self.delegate receiveBluetoothTimestamp:curTime];
            self.dataToSend = [NSData dataWithBytes:&curTime length:sizeof(double)];
    }
    
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

