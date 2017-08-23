//
//  CounterHDController.m
//  CounterInclinationViewer
//
//  Created by Johannes Dürr on 18.05.17.
//  Copyright © 2017 Johannes Dürr. All rights reserved.
//

#import "CounterHDController.h"

@implementation HDBEvent

@end


@implementation CounterHDController

- (instancetype _Nonnull )initWithDelegate:(_Nonnull id)delegate autoReconnecting:(BOOL)reconnecting userRole:(en_User_Role)role pin:(uint16_t)pin
{
    self = [super init];
    if (self) {
        [self setDelegate:delegate];
        [self setIsAutoReconnecting:reconnecting];
        _peripheralPin = pin;
        _peripheralRole = role;
        _foundCharacteristics = [[NSMutableDictionary alloc]init];
        _foundPeripherals = [[NSMutableDictionary alloc]init];
        
        manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    
    eventDictionary = [[NSMutableDictionary alloc]init];
    
    return self;
}


- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral autoReconnecting:(BOOL)reconnecting
{
    self.isAutoReconnecting = reconnecting;
    [self connectPeripheral:peripheral];
}

- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral
{
    if (selected_peripheral != nil && selected_peripheral.state != CBPeripheralStateDisconnected) {
        selected_peripheral = nil;
    }
    selected_peripheral = peripheral;
    [manager connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(CBPeripheral* _Nonnull)peripheral{
    _isAutoReconnecting = FALSE;
    if (connectionTimer != nil) {
        [connectionTimer invalidate];
        connectionTimer = nil;
    }
    [manager cancelPeripheralConnection:peripheral];
    selected_peripheral = nil;
    
    
}

- (void)timer
{
    // if delegate wants us to watch out for reconnecting
    if (_isAutoReconnecting == TRUE) {
        // and if we are not in a connected sate
        if (selected_peripheral.state != CBPeripheralStateConnected || selected_peripheral.state != CBPeripheralStateConnecting || selected_peripheral.state == CBPeripheralStateDisconnected) {
            // tell manager to connect to the peripheral
            [manager connectPeripheral:selected_peripheral options:nil];
            if (self.isLoggingEnabled) {
                NSLog(@"%@", [NSString stringWithFormat:@"Reconnecting: %@", selected_peripheral.identifier.UUIDString]);
            }
        }
    }
}


#pragma mark - CBCentralManager Delegate

- (void)startScanning{
    if (self.isLoggingEnabled) {
        NSLog(@"Start Scanning");
    }
    
    CBUUID* counterServiceUUID = [CBUUID UUIDWithString:FLIEGL_BEACON_SERVICE_UUID];
    CBUUID* beaconServiceUUID = [CBUUID UUIDWithString:FLIEGL_BEACON_ONLY_SERVICE_UUID];
    
    NSArray* serviceArray = [NSArray arrayWithObjects:counterServiceUUID,nil];
    //NSDictionary *options    = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    
    [manager scanForPeripheralsWithServices:serviceArray options:nil/*options*/];
}

- (void)stopScanning{
    [manager stopScan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if ([manager state] == CBCentralManagerStatePoweredOff){
        if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStatePoweredOff");
        }
    }
            //[ProgressHUD showError:@"TCB needs Bluetooth to work properly"];
    
    if ([manager state] == CBCentralManagerStatePoweredOn){
        if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStatePoweredOn");
            [self startScanning];
        }
    }
    if ([manager state] == CBCentralManagerStateResetting)
    {
        if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStateResetting");
        }
    }
    if ([manager state] == CBCentralManagerStateUnauthorized){
            if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStateUnauthorized");
        }
    }
    if ([manager state] == CBCentralManagerStateUnknown){
        if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStateUnknown");
        }
    }
    if ([manager state] == CBCentralManagerStateUnsupported) {
        if (_isLoggingEnabled) {
            NSLog(@"CBCentralManagerStateUnsupported");
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    if (_isLoggingEnabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Found a peripheral: %@", peripheral.identifier]);
    }
    if ([self.foundPeripherals objectForKey:peripheral.identifier.UUIDString] == nil) {
        // not available yet - add:
        [self.foundPeripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
    }
    // update our delegate
    [_delegate cc_didUpdateAvailablePeripherals:_foundPeripherals];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [peripheral discoverServices:nil];
    [peripheral setDelegate:self];
    
    if (connectionTimer!= nil) {
        [connectionTimer invalidate];
        connectionTimer = nil;
    }
    
    [manager stopScan];
    
    // tell delegate
    if ([_delegate respondsToSelector:@selector(cc_didConnectPeripheral:)]) {
        [_delegate cc_didConnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (self.isLoggingEnabled) {
        NSLog(@"%@", [NSString stringWithFormat:@"Peripheral: %@ did disconnect.", peripheral.identifier.UUIDString]);
    }
    [self startScanning];
    if (self.isAutoReconnecting) {
        connectionTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    }
    // tell delegate
    if ([_delegate respondsToSelector:@selector(cc_didDisconnectPeripheral:)]) {
        [_delegate cc_didDisconnectPeripheral:peripheral];
    }
}

- (void)resetManager
{
    [manager stopScan];
    manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    [self startScanning];
}

#pragma mark - CBPeripheral Delegates

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (_isLoggingEnabled) {
        NSLog(@"Did discover Services...");
    }
    
    for (CBService* s  in peripheral.services) {
        if (_isLoggingEnabled) {
            NSLog(@"%@", [NSString stringWithFormat:@"%@", s.UUID.UUIDString]);
        }
        [peripheral discoverCharacteristics:nil forService:s];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    for (CBCharacteristic *c in service.characteristics) {
        if (self.isLoggingEnabled) {
            NSLog(@"Did discover Characteristic: %@", [NSString stringWithFormat:@"%@", c.UUID.UUIDString]);
        }
        
        // EEPRom Transport
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBC8-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBC8-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found EEPROM TRANSPORT Characteristic");
            }
        }
        
        // Param Transport (for reading back - predefined parameters)
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBC9-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBC9-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found PARAM TRANSPORT Characteristic");
            }
        }
        
        // DFU / Special commands
        if ([c.UUID.UUIDString isEqualToString:@"C93AAAA1-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23AAAA1-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found DFU Characteristic");
            }
            // we're going to send commands to this characteristic, so:
            // remember characteristic for writing to it
            [_foundCharacteristics setObject:c forKey:@"AAA1"];
        }
        
        // Beacon Basic Info
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBB1-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBB1-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Beacon Basic Characteristic");
            }
        }
        
        // UUID
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBB3-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBB3-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Beacon UUID Characteristic");
            }
        }
        
        // Button states (reed contacts)
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBB7-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBB7-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Button State Characteristic");
            }
        }
        
        // Event Totals
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBC3-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBC3-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Event Totals Characteristic");
            }
        }
        
        // Device State C93ABBFF-C497-4C95-8699-01B142AF0C24
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBFF-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBFF-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Device State Characteristic");
            }
            
        }
        
        // Device Configuration (Command-Handler)
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBD3-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBD3-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Device Configuration Characteristic");
            }
            
            // we're going to send commands to this characteristic, so:
            // remember characteristic for writing to it
            [_foundCharacteristics setObject:c forKey:@"BBD3"];
            
        }
        
        // lis3dh accl char
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBB8-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBB8-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Accelerometer Characteristic");
            }
        }
        
        // Battery information
        if ([c.UUID.UUIDString isEqualToString:@"C93ABBC0-C497-4C95-8699-01B142AF0C24"] ||
            [c.UUID.UUIDString isEqualToString:@"C23ABBC0-C497-4C95-8699-01B142AF0C24"]) {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            if (self.isLoggingEnabled) {
                NSLog(@"Found Battery Info Characteristic");
            }
        }
        
        
        
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    
    // Param Transport (reading back predefined parameters)
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBC9-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBC9-C497-4C95-8699-01B142AF0C24"]) {
        NSLog(@"Param Update: %@", [characteristic.value description]);
        uint8_t commandNumber = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(0, 1)]]bytes];
        //uint8_t packetNumber = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(1, 1)]] bytes];
        
        if (commandNumber == CMD_READ_AXIS_CONFIG)
        {
            
            uint8_t axis = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(2, 1)]]bytes];
            uint8_t mode = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(3, 1)]]bytes];
            uint8_t flavor = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(4, 1)]]bytes];
            uint8_t filterTime = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(5, 1)]]bytes];
            uint8_t isInverted = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(6, 1)]]bytes];
            uint8_t isRSDependent = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(7, 1)]]bytes];
            int16_t  topBound = *(int16_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(8, 2)]]bytes];
            int16_t  botBound = *(int16_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(10, 2)]]bytes];
            uint16_t  topInertia = *(uint16_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(12, 2)]]bytes];
            uint16_t  botInertia = *(uint16_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(14, 2)]]bytes];
            
            if ([_delegate respondsToSelector:@selector(cc_didUpdateAxisConfigurationForAxis:mode:flavor:filterTime:isInverted:isRSDependent:topBound:botBound:topInertia:botInertia:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cc_didUpdateAxisConfigurationForAxis:axis mode:mode flavor:flavor filterTime:filterTime isInverted:isInverted isRSDependent:isRSDependent topBound:topBound botBound:botBound topInertia:topInertia botInertia:botInertia];
                });
            }
        }
        if(commandNumber == CMD_EEPROM_SELF_TEST)
        {
            uint8_t errorCount = *(uint8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(2, 1)]]bytes];
            NSData* testResultData = [characteristic.value subdataWithRange:NSMakeRange(3, 10)];
            if ([_delegate respondsToSelector:@selector(cc_didUpdateEepromSelftestResultErrorCount:TestData:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cc_didUpdateEepromSelftestResultErrorCount:errorCount TestData:testResultData];
                });
            }
        }
        
        if (commandNumber == CMD_READ_CURRENT_TIME) {
            uint32_t  secsSince1970 = *(uint32_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(2, 4)]]bytes];
            NSDate* perDate = [NSDate dateWithTimeIntervalSince1970:secsSince1970];
            if ([_delegate respondsToSelector:@selector(cc_didUpdateCurrentPeripheralTime:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cc_didUpdateCurrentPeripheralTime:perDate];
                });
            }
        }
        
        if (commandNumber == CMD_READ_RADIO_POWER) {
            int8_t radioPower = *(int8_t*)[[NSData dataWithData:[characteristic.value subdataWithRange:NSMakeRange(2, 1)]]bytes];
            if ([_delegate respondsToSelector:@selector(cc_didUpdateRadioPower:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cc_didUpdateRadioPower:radioPower];
                });
            }
        }
    }
    
    // EEPROM Transport characteristic
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBC8-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBC8-C497-4C95-8699-01B142AF0C24"])
    {
        if (isEEPTransferInitiated) {
            
            uint16_t slot = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(0, 2)]bytes];
            NSData* data = [characteristic.value subdataWithRange:NSMakeRange(2, 18)];
            NSLog(@"Transfer %d: %@",slot, [data description]);
            
            memcpy(myEeprom.messages[slot].eepTransportMsg.payload, [data bytes], 18);
            myEeprom.messages[slot].eepTransportMsg.packetNum = slot;
            float perc = (slot/(7281.0f/100.0f));
            //NSLog(@"%@", [NSString stringWithFormat:@"Received EEP: %.2f (Slot: %d | 1%% = %.2f)", perc, slot, (float)(7281.0f/100.0f)]);
            if ([_delegate respondsToSelector:@selector(cc_didUpdateEepromTransferPercentage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [_delegate cc_didUpdateEepromTransferPercentage:perc];
                });
            }
            
            if (slot == 7281) {
                // We received the last slot. --> parse the memory now and handle the rest
                isEEPTransferInitiated = false;
                NSMutableData* eepData = [[NSMutableData alloc]init];
                // collect the whole data
                for (uint16_t i = 0; i<7282; i++) {
                    
                    if (i == 3640 || i == 7281) {
                        [eepData appendData:[NSData dataWithBytes:myEeprom.messages[i].eepTransportMsg.payload length:15]];
                    }else{
                        [eepData appendData:[NSData dataWithBytes:myEeprom.messages[i].eepTransportMsg.payload length:18]];
                    }
                }
                
                
                // we now have the pure eeprom bytes.
                for (uint16_t i = 0; i< 2570; i++)
                {
                    NSData* eventData = [eepData subdataWithRange:NSMakeRange((i*EEP_EVENT_SIZE), EEP_EVENT_SIZE)];
                    
                    eep_Events[i].eep_event.eepID = *(uint16_t*)[[eventData subdataWithRange:NSMakeRange(0, 2)]bytes];
                    
                    eep_Events[i].eep_event.mode = *(uint8_t*)[[eventData subdataWithRange:NSMakeRange(2, 1)]bytes];
                    
                    eep_Events[i].eep_event.flavor = *(uint8_t*)[[eventData subdataWithRange:NSMakeRange(3, 1)]bytes];
                    
                    eep_Events[i].eep_event.axis = *(uint8_t*)[[eventData subdataWithRange:NSMakeRange(4, 1)]bytes];
                    
                    eep_Events[i].eep_event.rs_state = *(uint8_t*)[[eventData subdataWithRange:NSMakeRange(5, 1)]bytes];
                    
                    eep_Events[i].eep_event.event_date = *(uint32_t*)[[eventData subdataWithRange:NSMakeRange(6, 4)]bytes];
                    
                    eep_Events[i].eep_event.event_count = *(uint16_t*)[[eventData subdataWithRange:NSMakeRange(10, 2)]bytes];
                    
                    eep_Events[i].eep_event.event_pCount = *(uint16_t*)[[eventData subdataWithRange:NSMakeRange(12, 2)]bytes];
                    
                    eep_Events[i].eep_event.event_duration = *(uint32_t*)[[eventData subdataWithRange:NSMakeRange(14, 4)]bytes];
                    
                    eep_Events[i].eep_event.latitude = *(Float32*)[[eventData subdataWithRange:NSMakeRange(18, 4)]bytes];
                    
                    eep_Events[i].eep_event.longitude = *(Float32*)[[eventData subdataWithRange:NSMakeRange(22, 4)]bytes];
                    
                    for (uint8_t un = 0; un < 24; un++) {
                        eep_Events[i].eep_event.unused[un] = *(uint8_t*)[[eventData subdataWithRange:NSMakeRange((26+un), 1)]bytes];
                    }
                    
                    NSData* propData = [eventData subdataWithRange:NSMakeRange(26, 24)];
                    
                    eep_Events[i].eep_event.crc8 = *(uint16_t*)[[eventData subdataWithRange:NSMakeRange(50, 1)]bytes];
                    
                    uint8_t checkCRC8 = 0;
                    for (uint8_t j = 0; j< (EEP_EVENT_SIZE-1); j++) {
                        checkCRC8 += eep_Events[i].bytes[j];
                    }
                    
                    if (checkCRC8 == eep_Events[i].eep_event.crc8) {
                        NSLog(@"WE HAVE A WINNER: %d", eep_Events[i].eep_event.eepID);
                        NSLog(@"Parsed Location lat: %f lon: %f", eep_Events[i].eep_event.latitude, eep_Events[i].eep_event.longitude);
                        // Create an object
                        HDBEvent* event = [[HDBEvent alloc]init];
                        event.eepID = eep_Events[i].eep_event.eepID;
                        event.mode = eep_Events[i].eep_event.mode;
                        event.flavor = eep_Events[i].eep_event.flavor;
                        event.axis = eep_Events[i].eep_event.axis;
                        event.rsState = eep_Events[i].eep_event.rs_state;
                        event.eventDate = eep_Events[i].eep_event.event_date;
                        event.eventCount = eep_Events[i].eep_event.event_count;
                        event.eventProcessCount = eep_Events[i].eep_event.event_pCount;
                        event.eventDuration = eep_Events[i].eep_event.event_duration;
                        event.latitude = eep_Events[i].eep_event.latitude;
                        event.longitude = eep_Events[i].eep_event.longitude;
                        event.crc8 = eep_Events[i].eep_event.crc8;
                        event.proprietaryData = propData;
                        // add object to dictionary if it does not exist...
                        [eventDictionary setObject:event forKey:[NSNumber numberWithInt:event.eepID]];
                        
                    }else{
                    }
                }//end for loop generating objects
                if ([_delegate respondsToSelector:@selector(cc_didUpdateEepromTransferedEvents:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate cc_didUpdateEepromTransferedEvents:eventDictionary];
                    });
                }
            }
        }
    }
    
    
    
    // Beacon Basic Info
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBB1-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBB1-C497-4C95-8699-01B142AF0C24"]) {
        NSLog(@"RECEIVED BEACON info (Basic info)");
        uint16_t minor, major;
        NSString* localName;
        int8_t txPower;
        int16_t lisTemperature;
        
        minor = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(0, 2)]bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateMinor:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateMinor:minor];
            });
        }
        major = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(2, 2)]bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateMajor:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateMajor:major];
            });
        }
        if (characteristic.value.length == 18) {
            lisTemperature = *(int16_t*)[[characteristic.value subdataWithRange:NSMakeRange(16, 2)]bytes];
            NSLog(@"%@", [NSString stringWithFormat:@"LIS Temperature: %d", lisTemperature]);
            
            if ([_delegate respondsToSelector:@selector(cc_didUpdateLISTemperature:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cc_didUpdateLISTemperature:lisTemperature];
                });
            }
        }
        
        
        txPower = *(int8_t*)[[characteristic.value subdataWithRange:NSMakeRange(15, 1)]bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateTXPower:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateTXPower:txPower];
            });
        }
        
        NSData* localNameData = [characteristic.value subdataWithRange:NSMakeRange(4, 11)];
        localName = [[NSString alloc]initWithData:localNameData encoding:NSUTF8StringEncoding];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateLocalName:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateLocalName:localName];
            });
        }
    }
    
    // UUID
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBB3-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBB3-C497-4C95-8699-01B142AF0C24"]) {
        
        NSData* uuidData = [characteristic.value subdataWithRange:NSMakeRange(0, 16)];
        NSString* uuidString;
        
        CBUUID* uuid = [CBUUID UUIDWithData:uuidData];
        if (uuid!= nil) {
            uuidString = uuid.UUIDString;
        }else{
            uuidString = @"Received illegal UUID value";
        }
        
        if ([_delegate respondsToSelector:@selector(cc_didUpdateUUID:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateUUID:uuidString];
            });
        }
    }
    
    // battery information
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBC0-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBC0-C497-4C95-8699-01B142AF0C24"]) {
        
        uint8_t charge = *(uint8_t*)[[characteristic.value subdataWithRange:NSMakeRange(0, 1)]bytes];
        BOOL dcdcEnabled =  *(BOOL*)[[characteristic.value subdataWithRange:NSMakeRange(1, 1)]bytes];
        
        if (self.isLoggingEnabled) {
            NSLog(@"Received Battery Information (%d%%, DCDC: %d)", charge, dcdcEnabled);
        }
        
        if ([_delegate respondsToSelector:@selector(cc_didUpdateBatteryCharge:dcdcEnabled:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateBatteryCharge:charge dcdcEnabled:dcdcEnabled];
            });
        }
    }
    
    // button state
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBB7-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBB7-C497-4C95-8699-01B142AF0C24"])
    {
        // Button 3
        uint8_t state = *(uint8_t*)[[characteristic.value subdataWithRange:NSMakeRange(0, 1)]bytes];
        if (state & 1)
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton1_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton3_trigger:YES];
                });
            }
        }else
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton1_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton3_trigger:NO];
                });
            }
        }
        // Button 1
        if (state & (1<<1))
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton2_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton1_trigger:YES];
                });
            }
        }else
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton2_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton1_trigger:NO];
                });
            }
        }
        // Button 2
        if (state & (1<<2))
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton3_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton2_trigger:YES];
                });
            }
        }else
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton3_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [_delegate cc_didUpdateButton2_trigger:NO];
                });
            }
        }
        // Button 4 (external)
        if (state & (1<<3))
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton4_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_delegate cc_didUpdateButton4_trigger:YES];
                               });
            }
        }else
        {
            if ([_delegate respondsToSelector:@selector(cc_didUpdateButton4_trigger:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   [_delegate cc_didUpdateButton4_trigger:NO];
                               });
            }
        }
        
    }

    
    // Event Totals
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBC3-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBC3-C497-4C95-8699-01B142AF0C24"]) {
        uint16_t xEventCount, yEventCount, zEventCount, xActiveTime, yActiveTime, zActiveTime, xProcessCount, yProcessCount, zProcessCount;
        
        xEventCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(0, 2)]bytes];
        yEventCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(2, 2)]bytes];
        zEventCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(4, 2)]bytes];
        xActiveTime = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(6, 2)]bytes];
        yActiveTime = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(8, 2)]bytes];
        zActiveTime = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(10, 2)]bytes];
        xProcessCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(12, 2)]bytes];
        yProcessCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(14, 2)]bytes];
        zProcessCount = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(16, 2)]bytes];
        
        if ([_delegate respondsToSelector:@selector(cc_didUpdateTotalsForXEventCount:yEventCount:zEventCount:xActiveTime:yActiveTime:yActiveTime:xProcessCount:yProcessCount:zProcessCount:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateTotalsForXEventCount:xEventCount yEventCount:yEventCount zEventCount:zEventCount xActiveTime:xActiveTime yActiveTime:yActiveTime yActiveTime:zActiveTime xProcessCount:xProcessCount yProcessCount:yProcessCount zProcessCount:zProcessCount];
            });
        }
    }
    
    // Device State
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBFF-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBFF-C497-4C95-8699-01B142AF0C24"]) {
        
        uint16_t deviceType, deviceRevision, buildNumber, rs_count;
        uint8_t firmwareMajor, firmwareMinor;
        uint32_t statusBits, rs_time;
        uint8_t currentUserRole;
        int8_t chipTemperature;
        
        
        // device type
        NSData* devType_data = [characteristic.value subdataWithRange:NSMakeRange(0, 2)];
        deviceType = *(uint16_t*)[devType_data bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateDeviceType:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateDeviceType:deviceType];
            });
        }
        
        // device Revision
        NSData* devRevision_data = [characteristic.value subdataWithRange:NSMakeRange(2, 2)];
        deviceRevision = *(uint16_t*)[devRevision_data bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateDeviceRevision:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateDeviceRevision:deviceRevision];
            });
        }
        
        // firmware build number
        NSData* buildNumber_data = [characteristic.value subdataWithRange:NSMakeRange(4, 2)];
        buildNumber = *(uint16_t*)[buildNumber_data bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateFirmwareBuildNr:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateFirmwareBuildNr:buildNumber];
            });
        }
        
        // firmware major and minor
        firmwareMajor = *(uint8_t*)[[characteristic.value subdataWithRange:NSMakeRange(6, 1)]bytes];
        firmwareMinor = *(uint8_t*)[[characteristic.value subdataWithRange:NSMakeRange(7, 1)]bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateFirmwareMajor:andMinor:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateFirmwareMajor:firmwareMajor andMinor:firmwareMinor];
            });
        }
        
        // user role (current set)
        currentUserRole = *(uint8_t*)[[characteristic.value subdataWithRange:NSMakeRange(18, 1)]bytes];
        
        // chip temperature
        chipTemperature = *(int8_t*)[[characteristic.value subdataWithRange:NSMakeRange(19, 1)]bytes];
        
        // check if the user role equals our role or set if not
        if (currentUserRole != _peripheralRole) {
            [self setUserRole:_peripheralRole withPin:_peripheralPin];
        }
        
        if ([_delegate respondsToSelector:@selector(cc_didUpdateUserRole:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateUserRole:currentUserRole];
            });
        }

        // Status bits
        NSData* statusBits_data = [characteristic.value subdataWithRange:NSMakeRange(8, 4)];
        statusBits = *(uint32_t*)[statusBits_data bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateStatusFlags:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateStatusFlags:statusBits];
            });
        }
        
        // RS_Totals
        rs_time = *(uint32_t*)[[characteristic.value subdataWithRange:NSMakeRange(12, 4)]bytes];
        rs_count = *(uint16_t*)[[characteristic.value subdataWithRange:NSMakeRange(16, 2)]bytes];
        if ([_delegate respondsToSelector:@selector(cc_didUpdateRSTime:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateRSTime:rs_time];
            });
        }
        if ([_delegate respondsToSelector:@selector(cc_didUpdateRSCount:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateRSCount:rs_count];
            });
        }
        if (self.isLoggingEnabled) {
            
        }
        
        if ([_delegate respondsToSelector:@selector(cc_didUpdateDeviceStateWith_DeviceType:deviceRevision:buildNumber:firmwareMajor:firmwareMinor:statusBits:rs_time:rs_count:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate cc_didUpdateDeviceStateWith_DeviceType:deviceType deviceRevision:deviceRevision buildNumber:buildNumber firmwareMajor:firmwareMajor firmwareMinor:firmwareMinor statusBits:statusBits rs_time:rs_time rs_count:rs_count];
            });
        }
        
    }
    
    // Lis3dh incl Characteristic
    if ([characteristic.UUID.UUIDString isEqualToString:@"C93ABBB8-C497-4C95-8699-01B142AF0C24"] ||
        [characteristic.UUID.UUIDString isEqualToString:@"C23ABBB8-C497-4C95-8699-01B142AF0C24"]) {
        // avoid updating childviews!
        //NSLog(@"Received Accl Value update");
        
        NSData* x_data = [characteristic.value subdataWithRange:NSMakeRange(0, 2)];
        NSData* y_data = [characteristic.value subdataWithRange:NSMakeRange(2, 2)];
        NSData* z_data = [characteristic.value subdataWithRange:NSMakeRange(4, 2)];
        NSData* x_corrected_data = [characteristic.value subdataWithRange:NSMakeRange( 6, 2)];
        NSData* y_corrected_data = [characteristic.value subdataWithRange:NSMakeRange(8, 2)];
        NSData* z_corrected_data = [characteristic.value subdataWithRange:NSMakeRange(10, 2)];
        
        // available but not used in this implementation
        NSData* x_acceleration_data = [characteristic.value subdataWithRange:NSMakeRange(12, 1)];
        NSData* y_acceleration_data = [characteristic.value subdataWithRange:NSMakeRange(13, 1)];
        NSData* z_acceleration_data = [characteristic.value subdataWithRange:NSMakeRange(14, 1)];
        // 15 -> byte unused
        NSData* freq_bin1 = [characteristic.value subdataWithRange:NSMakeRange(16, 1)];
        NSData* freq_bin2 = [characteristic.value subdataWithRange:NSMakeRange(17, 1)];
        NSData* freq_bin3 = [characteristic.value subdataWithRange:NSMakeRange(18, 1)];
        NSData* freq_bin4 = [characteristic.value subdataWithRange:NSMakeRange(19, 1)];
        
        
        int16_t x = *(uint16_t*)[x_data bytes];
        int16_t y = *(uint16_t*)[y_data bytes];
        int16_t z = *(uint16_t*)[z_data bytes];
        
        int16_t x_corrected = *(uint16_t*)[x_corrected_data bytes];
        int16_t y_corrected = *(uint16_t*)[y_corrected_data bytes];
        int16_t z_corrected = *(uint16_t*)[z_corrected_data bytes];
        
        // available but not used in this implementation:
        int8_t xGravity = *(int8_t*)[x_acceleration_data bytes];
        int8_t yGravity = *(int8_t*)[y_acceleration_data bytes];
        int8_t zGravity = *(int8_t*)[z_acceleration_data bytes];
        
        // frequency bins
        int8_t bin1 = *(int8_t*)[freq_bin1 bytes];
        int8_t bin2 = *(int8_t*)[freq_bin2 bytes];
        int8_t bin3 = *(int8_t*)[freq_bin3 bytes];
        int8_t bin4 = *(int8_t*)[freq_bin4 bytes];
        
        NSString* zFrequency = [NSString stringWithFormat:@"%.3f | %.3f | %.3f | %.3f Hz", [self calcFreqFromBin:bin1], [self calcFreqFromBin:bin2], [self calcFreqFromBin:bin3], [self calcFreqFromBin:bin4]];
        
        
        if (self.isLoggingEnabled) {
            NSLog(@"%@", [NSString stringWithFormat:@"Accelerometer Data\nX: %d\nY: %d\nZ: %d\nCorrected X: %d\nCorrected Y: %d\nCorrected Z: %d\nXAccel: %d\nYAccel: %d\nZAccel: %d\n\n", x,y,z,x_corrected,y_corrected,z_corrected, xGravity, yGravity, zGravity]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector(cc_didUpdateInclincationForX:andY:andZ:rawX:rawY:rawZ:gravityX:gravityY:gravityZ: frequencyFFT_z:)]) {
                [_delegate cc_didUpdateInclincationForX:(float)x_corrected andY:(float)y_corrected andZ:(float)z_corrected rawX:(float)x rawY:(float)y rawZ:(float)z gravityX:(int8_t)xGravity gravityY:(int8_t)yGravity gravityZ:(int8_t)zGravity frequencyFFT_z:zFrequency];
            }
        });
    }
}

- (float)calcFreqFromBin:(uint8_t)bin{
    float freq = (float) bin * 100.0f / 128.0f;
    return freq;
}

#pragma mark - Device configuration and manipulation Methods

// Device configuration and manipulation methods
// Low Pass filter
- (void)setLowPassFilterTime_X_s:(uint8_t)newFilterTime_s
{
    unsigned char senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_FILTER_TIME;
    senddata[2] = newFilterTime_s;
    senddata[3] = 0xff;
    senddata[4] = 0xff;
    
    // retrieve char
    CBCharacteristic* filter_time_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (filter_time_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:filter_time_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setLowPassFilterTime_Y_s:(uint8_t)newFilterTime_s
{
    unsigned char senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_FILTER_TIME;
    senddata[2] = 0xff;
    senddata[3] = newFilterTime_s;
    senddata[4] = 0xff;
    
    // retrieve char
    CBCharacteristic* filter_time_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (filter_time_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:filter_time_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setLowPassFilterTime_Z_s:(uint8_t)newFilterTime_s
{
    unsigned char senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_FILTER_TIME;
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    senddata[4] = newFilterTime_s;
    
    // retrieve char
    CBCharacteristic* filter_time_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (filter_time_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:filter_time_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setLowPassFilterTime_XYZ_With_X:(uint8_t)newX Y:(uint8_t)newY Z:(uint8_t)newZ
{
    unsigned char senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_FILTER_TIME;
    senddata[2] = newX;
    senddata[3] = newY;
    senddata[4] = newZ;
    
    // retrieve char
    CBCharacteristic* filter_time_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (filter_time_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:filter_time_char type:CBCharacteristicWriteWithResponse];
    }
}
// Axis calibration
- (void)calibrate_X_Axis
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x01;// X
    senddata[3] = 0x00;// Y
    senddata[4] = 0x00;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)calibrate_Y_Axis
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x00;// X
    senddata[3] = 0x01;// Y
    senddata[4] = 0x00;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)calibrate_Z_Axis
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x00;// X
    senddata[3] = 0x00;// Y
    senddata[4] = 0x01;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)calibrate_XYZ_Axis
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x01;// X
    senddata[3] = 0x01;// Y
    senddata[4] = 0x01;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)reset_X_calibration
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x02;// X
    senddata[3] = 0x00;// Y
    senddata[4] = 0x00;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)reset_Y_calibration
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x00;// X
    senddata[3] = 0x02;// Y
    senddata[4] = 0x00;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)reset_Z_calibration
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x00;// X
    senddata[3] = 0x00;// Y
    senddata[4] = 0x02;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)reset_XYZ_calibration{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = 0x02;// X
    senddata[3] = 0x02;// Y
    senddata[4] = 0x02;// Z
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)invert_X_Axis:(BOOL)inv{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    if (inv) {
        senddata[2] = 0x04;// X
        senddata[3] = 0x00;// Y
        senddata[4] = 0x00;// Z
    }else{
        senddata[2] = 0x03;// X
        senddata[3] = 0x00;// Y
        senddata[4] = 0x00;// Z
    }
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)invert_Y_Axis:(BOOL)inv
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    if (inv) {
        senddata[2] = 0x00;// X
        senddata[3] = 0x04;// Y
        senddata[4] = 0x00;// Z
    }else{
        senddata[2] = 0x00;// X
        senddata[3] = 0x03;// Y
        senddata[4] = 0x00;// Z
    }
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)invert_Z_Axis:(BOOL)inv
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    if (inv) {
        senddata[2] = 0x00;// X
        senddata[3] = 0x00;// Y
        senddata[4] = 0x04;// Z
    }else{
        senddata[2] = 0x00;// X
        senddata[3] = 0x00;// Y
        senddata[4] = 0x03;// Z
    }
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)invert_XYZ_Axis:(BOOL)inv
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_CALIB;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    if (inv) {
        senddata[2] = 0x04;// X
        senddata[3] = 0x04;// Y
        senddata[4] = 0x04;// Z
    }else{
        senddata[2] = 0x03;// X
        senddata[3] = 0x03;// Y
        senddata[4] = 0x03;// Z
    }
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }

}

// Peripheral time

- (void)setPeripheralCurrentTime
{
    // get current date
    NSDate* date = [NSDate date];
    uint32ToByte tmpTime = {0x00};
    tmpTime.ui32 = (uint32_t)[date timeIntervalSince1970];
    
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_SET_CURRENT_TIME;
    memcpy(&senddata[2], tmpTime.bytes, 4);
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)readPeripheralCurrentTime
{
    
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_READ_CURRENT_TIME;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

// VGPS / Location

- (void)setPeripheralVLocation:(CLLocation*_Nonnull)location
{
    unsigned char senddata[20] = {0};
    senddata[0] = WRITE;
    senddata[1] = CMD_SET_VGPS_LOCATION;
    
    float2Byte latitude;
    float2Byte longitude;
    uint32ToByte timestampSecs;
    
    latitude.float_val = (float)  location.coordinate.latitude;
    longitude.float_val = (float) location.coordinate.longitude;
    timestampSecs.ui32 = [location.timestamp timeIntervalSince1970];
    
    senddata[2] = latitude.bytes[3];
    senddata[3] = latitude.bytes[2];
    senddata[4] = latitude.bytes[1];
    senddata[5] = latitude.bytes[0];
    
    senddata[6] = latitude.bytes[3];
    senddata[7] = latitude.bytes[2];
    senddata[8] = latitude.bytes[1];
    senddata[9] = latitude.bytes[0];
    
    senddata[10] = latitude.bytes[3];
    senddata[11] = latitude.bytes[2];
    senddata[12] = latitude.bytes[1];
    senddata[13] = latitude.bytes[0];
    
    memcpy(&senddata[2],  latitude.bytes, 4);
    memcpy(&senddata[6],  longitude.bytes, 4);
    memcpy(&senddata[10], timestampSecs.bytes, 4);
    
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

// Peripheral Radio Power

- (void) setPeripheralRadioPower:(kRadioPowerLevel)rPLevel
{
    
    int8_t radioPower = 0;
    
    unsigned char senddata[20] = {0};
    senddata[0] = WRITE;
    senddata[1] = CMD_SET_RADIO_POWER;
    
    
    switch (rPLevel) {
        case kRadioPowerLevel_Default_00_db:
            radioPower = 0;
            break;
            
            //kRadioPowerLevel_Highest_04_db = 0,
        case kRadioPowerLevel_Highest_04_db:
            radioPower = 4;
            break;
            
            //kRadioPowerLevel_Low_neg_04_db = 2,
        case kRadioPowerLevel_Low_neg_04_db:
            radioPower = -4;
            break;
            
            //kRadioPowerLevel_Lower_0_neg_08_db = 3,
        case kRadioPowerLevel_Lower_0_neg_08_db:
            radioPower = -8;
            break;
            
            //kRadioPowerLevel_Lower_1_neg_12_db = 4,
        case kRadioPowerLevel_Lower_1_neg_12_db:
            radioPower = -12;
            break;
            
            //kRadioPowerLevel_Lower_2_neg_16_db = 5,
        case kRadioPowerLevel_Lower_2_neg_16_db:
            radioPower = -16;
            break;
            
            //kRadioPowerLevel_Lower_3_neg_20_db = 6
        case kRadioPowerLevel_Lower_3_neg_20_db:
            radioPower = -20;
            break;
            
        default:
            radioPower = 0;
            break;
    }
    
    senddata[2] = radioPower;
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}


- (void) readPeripheralRadioPower
{
    unsigned char senddata[20] = {0};
    senddata[0] = WRITE;
    senddata[1] = CMD_READ_RADIO_POWER;
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}



// User Role

- (void)setUserRole:(en_User_Role)role withPin:(uint16_t)pin
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_FSEC_SET_USER_ROLE;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = role;
    uint16toByte tmpPin;
    tmpPin.ui = pin;
    senddata[3] = tmpPin.bytes[0];
    senddata[4] = tmpPin.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
    
}

- (void)setNewPin:(uint16_t)pin forUserRole:(en_User_Role)role{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_FSEC_SET_NEW_PIN;
    // calibs - 0x01 == calibrate axis; 0x02 == reset calibration
    senddata[2] = role;
    uint16toByte tmpPin;
    tmpPin.ui = pin;
    senddata[3] = tmpPin.bytes[0];
    senddata[4] = tmpPin.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

// Axis Mode and Flavour configuration
- (void)setAxisModeWith_XMode:(uint8_t)xMode
                             XFlavor:(uint8_t)xFlavor
                         rsDependent:(uint8_t)rsDep
{
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_MODE;
    senddata[2] = xMode;
    senddata[3] = xFlavor; // 0 is disabled in beacon firmware!
    senddata[4] = 0xff;
    senddata[5] = 0xff; // 0 is disabled in beacon firmware!
    senddata[6] = 0xff;
    senddata[7] = 0xff; // 0 is disabled in beacon firmware!
    senddata[8] = rsDep;
    senddata[9] = 0xff;
    senddata[10] = 0xff;
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setAxisModeWith_YMode:(uint8_t)yMode
                             YFlavor:(uint8_t)yFlavor
                         rsDependent:(uint8_t)rsDep
{
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_MODE;
    senddata[2] = 0xff;
    senddata[3] = 0xff; // 0 is disabled in beacon firmware!
    senddata[4] = yMode;
    senddata[5] = yFlavor; // 0 is disabled in beacon firmware!
    senddata[6] = 0xff;
    senddata[7] = 0xff; // 0 is disabled in beacon firmware!
    senddata[8] = 0xff;
    senddata[9] = rsDep;
    senddata[10] = 0xff;
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setAxisModeWith_ZMode:(uint8_t)zMode
                             ZFlavor:(uint8_t)zFlavor
                         rsDependent:(uint8_t)rsDep
{
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_MODE;
    senddata[2] = 0xff;
    senddata[3] = 0xff; // 0 is disabled in beacon firmware!
    senddata[4] = 0xff;
    senddata[5] = 0xff; // 0 is disabled in beacon firmware!
    senddata[6] = zMode;
    senddata[7] = zFlavor; // 0 is disabled in beacon firmware!
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    senddata[10] = rsDep;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}
- (void)setAxisModeWith_XMode:(uint8_t)xMode
                             XFlavor:(uint8_t)xFlavor
                         rsxDependent:(uint8_t)rsxDep
                               YMode:(uint8_t)yMode
                             YFlavor:(uint8_t)yFlavor
                         rsyDependent:(uint8_t)rsyDep
                               ZMode:(uint8_t)zMode
                             ZFlavor:(uint8_t)zFlavor
                         rszDependent:(uint8_t)rszDep
{
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_MODE;
    senddata[2] = xMode;
    senddata[3] = xFlavor; // 0 is disabled in beacon firmware!
    senddata[4] = yMode;
    senddata[5] = yFlavor; // 0 is disabled in beacon firmware!
    senddata[6] = zMode;
    senddata[7] = zFlavor; // 0 is disabled in beacon firmware!
    senddata[8] = rsxDep;
    senddata[9] = rsyDep;
    senddata[10] = rszDep;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisBoundariesWithXTop:(int16_t)topBound
                                 XBottom:(int16_t)botBound
{
    
    int16toByte temp = {0x00};
    
    temp.si = topBound;
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_BOUNDS;
    senddata[2] = temp.bytes[0];
    senddata[3] = temp.bytes[1];
    
    temp.si = botBound;
    
    senddata[4] = temp.bytes[0];
    senddata[5] = temp.bytes[1];
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
        
    }
}

- (void)setAxisBoundariesWithYTop:(int16_t)topBound
                                 YBottom:(int16_t)botBound
{
    
    int16toByte temp = {0x00};
    
    temp.si = topBound;
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_BOUNDS;
    senddata[6] = temp.bytes[0];
    senddata[7] = temp.bytes[1];
    
    temp.si = botBound;
    
    senddata[8] = temp.bytes[0];
    senddata[9] = temp.bytes[1];
    
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    senddata[4] = 0xff;
    senddata[5] = 0xff;
    
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisBoundariesWithZTop:(int16_t)topBound
                                 ZBottom:(int16_t)botBound
{
    
    int16toByte temp = {0x00};
    
    
    uint8_t senddata[20] = {0x00};
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_BOUNDS;
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    senddata[4] = 0xff;
    senddata[5] = 0xff;
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    temp.si = topBound;
    senddata[10] = temp.bytes[0];
    senddata[11] = temp.bytes[1];
    temp.si = botBound;
    senddata[12] = temp.bytes[0];
    senddata[13] = temp.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisBoundariesWithXTop:(int16_t)topxBound
                                 XBottom:(int16_t)botxBound
                                 YBottom:(int16_t)topyBound
                                 YBottom:(int16_t)botyBound
                                 ZBottom:(int16_t)topzBound
                                 ZBottom:(int16_t)botzBound
{
    
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_BOUNDS;
    
    temp.si = topxBound;
    senddata[2] = temp.bytes[0];
    senddata[3] = temp.bytes[1];
    
    temp.si = botxBound;
    senddata[4] = temp.bytes[0];
    senddata[5] = temp.bytes[1];
    
    temp.si = topyBound;
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    
    temp.si = botyBound;
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    
    temp.si = topzBound;
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    
    temp.si = botzBound;
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisInertiaTimeThreshRSStart:(uint16_t)startRS andRSEnd:(uint16_t)endRS{
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_THRESH_TIME;
    
    // RS start
    temp.si = startRS;
    senddata[2] = temp.bytes[0];
    senddata[3] = temp.bytes[1];
    // RS stop
    temp.si = endRS;
    senddata[4] = temp.bytes[0];
    senddata[5] = temp.bytes[1];
    // x start
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    // x stop
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    // y start
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    // y stop
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    // z start
    senddata[14] = 0xff;
    senddata[15] = 0xff;
    // z stop
    senddata[16] = 0xff;
    senddata[17] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX{
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_THRESH_TIME;
    
    // RS start
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    // RS stop
    senddata[4] = 0xff;
    senddata[5] = 0xff;
    // x start
    temp.si = startX;
    senddata[6] = temp.bytes[0];
    senddata[7] = temp.bytes[1];
    // x stop
    temp.si = endX;
    senddata[8] = temp.bytes[0];
    senddata[9] = temp.bytes[1];
    // y start
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    // y stop
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    // z start
    senddata[14] = 0xff;
    senddata[15] = 0xff;
    // z stop
    senddata[16] = 0xff;
    senddata[17] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisInertiaTimeThreshYStart:(uint16_t)starty andYEnd:(uint16_t)endy{
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_THRESH_TIME;
    
    // RS start
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    // RS stop
    senddata[4] = 0xff;
    senddata[5] = 0xff;
    // x start
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    // x stop
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    // y start
    temp.si = starty;
    senddata[10] = temp.bytes[0];
    senddata[11] = temp.bytes[1];
    // y stop
    temp.si = endy;
    senddata[12] = temp.bytes[0];
    senddata[13] = temp.bytes[1];
    // z start
    senddata[14] = 0xff;
    senddata[15] = 0xff;
    // z stop
    senddata[16] = 0xff;
    senddata[17] = 0xff;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisInertiaTimeThreshZStart:(uint16_t)startz andZEnd:(uint16_t)endz{
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_THRESH_TIME;
    
    // RS start
    senddata[2] = 0xff;
    senddata[3] = 0xff;
    // RS stop
    senddata[4] = 0xff;
    senddata[5] = 0xff;
    // x start
    senddata[6] = 0xff;
    senddata[7] = 0xff;
    // x stop
    senddata[8] = 0xff;
    senddata[9] = 0xff;
    // y start
    senddata[10] = 0xff;
    senddata[11] = 0xff;
    // y stop
    senddata[12] = 0xff;
    senddata[13] = 0xff;
    // z start
    temp.si = startz;
    senddata[14] = temp.bytes[0];
    senddata[15] = temp.bytes[1];
    // z stop
    temp.si = endz;
    senddata[16] = temp.bytes[0];
    senddata[17] = temp.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)setAxisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX
                                       YStart:(uint16_t)starty andYEnd:(uint16_t)endy
                                       ZStart:(uint16_t)startz andZEnd:(uint16_t)endz
                                       RSStart:(uint16_t)startrs andRSEnd:(uint16_t)endrs

{
    int16toByte temp = {0x00};
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_AXIS_THRESH_TIME;
    
    // RS start
    temp.si = startrs;
    senddata[2] = temp.bytes[0];
    senddata[3] = temp.bytes[1];
    // RS stop
    temp.si = endrs;
    senddata[4] = temp.bytes[0];
    senddata[5] = temp.bytes[1];
    // x start
    temp.si = startX;
    senddata[6] = temp.bytes[0];
    senddata[7] = temp.bytes[1];
    // x stop
    temp.si = endX;
    senddata[8] = temp.bytes[0];
    senddata[9] = temp.bytes[1];
    // y start
    temp.si = starty;
    senddata[10] = temp.bytes[0];
    senddata[11] = temp.bytes[1];
    // y stop
    temp.si = endy;
    senddata[12] = temp.bytes[0];
    senddata[13] = temp.bytes[1];
    // z start
    temp.si = startz;
    senddata[14] = temp.bytes[0];
    senddata[15] = temp.bytes[1];
    // z stop
    temp.si = endz;
    senddata[16] = temp.bytes[0];
    senddata[17] = temp.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)basic_info_setNewLocalName:(NSString*_Nonnull)name
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_BASIC_LOCALNAME;
    
    // make sure we only hav 11 characters - because the beacons cannot handle more than that
    NSString* shortenedString;
    if ([name length]>11) {
        shortenedString = [name substringWithRange:NSMakeRange(0, 11)];
    }else{
        shortenedString = name;
    }
    
    memcpy(&senddata[2], [shortenedString UTF8String], [shortenedString length]);
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)basic_info_setNewMinor:(uint16_t)minor
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_BASIC_MINOR;
    
    uint16toByte temp = {0x00};
    
    temp.ui = minor;
    
    senddata[2]=temp.bytes[0];
    senddata[3]=temp.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}


- (void)basic_info_setNewMajor:(uint16_t)major
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_BASIC_MAJOR;
    
    uint16toByte temp = {0x00};
    
    temp.ui = major;
    
    senddata[2]=temp.bytes[0];
    senddata[3]=temp.bytes[1];
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)basic_info_setNewTXPower:(int8_t)txPower
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_BASIC_TXPOWER;
    senddata[2] = txPower;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)basic_info_setNewUUID:(NSString*_Nonnull)uuid
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_BASIC_UUID;
    
    NSUUID* uuId = [[NSUUID alloc]initWithUUIDString:uuid];
    unsigned char uuidBytes[16];
    [uuId getUUIDBytes:uuidBytes];
    
    memcpy(&senddata[2], uuidBytes, 16);
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)dfu_sendPeripheralToBootloader{
    uint8_t senddata[2] = {0x00};
    
    senddata[0] = 0xCA;
    senddata[1] = 0xFE;
    
    // retrieve char
    CBCharacteristic* dfu_Char = [_foundCharacteristics objectForKey:@"AAA1"];
    if (dfu_Char != nil) {
        NSLog(@"!!! Trying to send device to bootloader...");
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:2] forCharacteristic:dfu_Char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)dfu_rebootPeripheral{
    uint8_t senddata[2] = {0x00};
    
    senddata[0] = 0xFE;
    senddata[1] = 0xCA;
    
    // retrieve char
    CBCharacteristic* dfu_Char = [_foundCharacteristics objectForKey:@"AAA1"];
    if (dfu_Char != nil) {
        NSLog(@"!!! Trying to reboot the device...");
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:2] forCharacteristic:dfu_Char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)dfu_activateAgriCulturalUsage
{
    uint8_t senddata[2] = {0x00};
    
    senddata[0] = 0xDD;
    senddata[1] = 0xDD;
    
    // retrieve char
    CBCharacteristic* dfu_Char = [_foundCharacteristics objectForKey:@"AAA1"];
    if (dfu_Char != nil) {
        NSLog(@"!!! Trying set Beacon to AgriCultural Practice...");
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:2] forCharacteristic:dfu_Char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)dfu_savePStorage{
    uint8_t senddata[2] = {0x00};
    
    senddata[0] = 0xAB;
    senddata[1] = 0xCD;
    
    // retrieve char
    CBCharacteristic* dfu_Char = [_foundCharacteristics objectForKey:@"AAA1"];
    if (dfu_Char != nil) {
        NSLog(@"!!! Trying set Beacon to AgriCultural Practice...");
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:2] forCharacteristic:dfu_Char type:CBCharacteristicWriteWithResponse];
    }

}

- (void)eeprom_startTransfer{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_EEPROM_TRANSPORT;
    
    isEEPTransferInitiated = true;
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}

- (void)eeprom_startSelfTest{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_EEPROM_SELF_TEST;
        
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}


- (void)read_currentAxisConfiguration:(uint8_t)axis
{
    uint8_t senddata[20] = {0x00};
    
    senddata[0] = WRITE;
    senddata[1] = CMD_READ_AXIS_CONFIG;
    
    if (axis <= 4) {
        senddata[2] = axis;
    }
    
    
    // retrieve char
    CBCharacteristic* configuration_char = [_foundCharacteristics objectForKey:@"BBD3"];
    if (configuration_char != nil) {
        [selected_peripheral writeValue:[NSData dataWithBytes:senddata length:20] forCharacteristic:configuration_char type:CBCharacteristicWriteWithResponse];
    }
}




@end
