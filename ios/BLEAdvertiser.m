#import "BLEAdvertiser.h"
@import CoreBluetooth;

@implementation BLEAdvertiser

#define REGION_ID @"com.privatekit.ibeacon"

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(BLEAdvertiser)

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onDeviceFound", @"onBTStatusChange"];
}

RCT_EXPORT_METHOD(setCompanyId: (nonnull NSNumber *)companyId){
    RCTLogInfo(@"setCompanyId function called %@", companyId);
    self->centralManager = [[CBCentralManager alloc] initWithDelegate:self queue: nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES)}];
    self->peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
}

RCT_EXPORT_METHOD(broadcast: (NSString *)uid payload:(NSArray *)payload options:(NSDictionary *)options
    resolve: (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){

    RCTLogInfo(@"Broadcast function called %@ at %@", uid, payload);
    // Beacon Version. 
    //NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uid];
    //CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:1 minor:1 identifier:REGION_ID];
    //NSDictionary *advertisingData = [beaconRegion peripheralDataWithMeasuredPower:nil];
    
    // Criar Manufacturer Data a partir do payload
    NSMutableData *manufacturerData = [[NSMutableData alloc] init];
    if (payload && [payload count] > 0) {
        for (NSNumber *byte in payload) {
            uint8_t byteValue = [byte unsignedCharValue];
            [manufacturerData appendBytes:&byteValue length:1];
        }
    }
    
    // Log para debug - ver o que está sendo enviado
    RCTLogInfo(@"🔵 [iOS Native] Manufacturer Data criado: %@", manufacturerData);
    RCTLogInfo(@"🔵 [iOS Native] Manufacturer Data length: %lu", (unsigned long)[manufacturerData length]);
    
    // Converter para hex para debug
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)[manufacturerData bytes];
    for (NSUInteger i = 0; i < [manufacturerData length]; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    RCTLogInfo(@"🔵 [iOS Native] Manufacturer Data hex: %@", hexString);
    
    // Processar opções de nome do dispositivo
    NSMutableDictionary *advertisingData = [NSMutableDictionary dictionary];
    
    // Sempre incluir o Service UUID
    [advertisingData setObject:@[[CBUUID UUIDWithString:uid]] forKey:CBAdvertisementDataServiceUUIDsKey];
    
    // Incluir Manufacturer Data se fornecido
    if (manufacturerData && [manufacturerData length] > 0) {
        [advertisingData setObject:manufacturerData forKey:CBAdvertisementDataManufacturerDataKey];
    }
    
    // Processar opções de nome do dispositivo
    if (options) {
        // Incluir nome do dispositivo se solicitado
        if ([options objectForKey:@"includeDeviceName"] && [[options objectForKey:@"includeDeviceName"] boolValue]) {
            NSString *localName = [options objectForKey:@"localName"];
            if (localName && [localName length] > 0) {
                [advertisingData setObject:localName forKey:CBAdvertisementDataLocalNameKey];
                RCTLogInfo(@"🔵 [iOS Native] Incluindo nome local: %@", localName);
            } else {
                // Usar nome do dispositivo se não especificado
                [advertisingData setObject:[[UIDevice currentDevice] name] forKey:CBAdvertisementDataLocalNameKey];
                RCTLogInfo(@"🔵 [iOS Native] Incluindo nome do dispositivo: %@", [[UIDevice currentDevice] name]);
            }
        }
        
        // Incluir TX Power Level se solicitado
        if ([options objectForKey:@"includeTxPowerLevel"] && [[options objectForKey:@"includeTxPowerLevel"] boolValue]) {
            NSNumber *txPowerLevel = [options objectForKey:@"txPowerLevel"];
            if (txPowerLevel) {
                [advertisingData setObject:txPowerLevel forKey:CBAdvertisementDataTxPowerLevelKey];
                RCTLogInfo(@"🔵 [iOS Native] Incluindo TX Power Level: %@", txPowerLevel);
            }
        }
    }
    
    RCTLogInfo(@"🔵 [iOS Native] Advertising Data completo: %@", advertisingData);

    [peripheralManager startAdvertising:advertisingData];

    resolve(@"Broadcasting");
}

RCT_EXPORT_METHOD(stopBroadcast:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){

    [peripheralManager stopAdvertising];

    resolve(@"Stopping Broadcast");
}

RCT_EXPORT_METHOD(scan: (NSArray *)payload options:(NSDictionary *)options 
    resolve: (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){

    if (!centralManager) { reject(@"Device does not support Bluetooth", @"Adapter is Null", nil); return; }
    
    switch (centralManager.state) {
        case CBManagerStatePoweredOn:    break;
        case CBManagerStatePoweredOff:   reject(@"Bluetooth not ON",@"Powered off", nil);   return;
        case CBManagerStateResetting:    reject(@"Bluetooth not ON",@"Resetting", nil);     return;
        case CBManagerStateUnauthorized: reject(@"Bluetooth not ON",@"Unauthorized", nil);  return;
        case CBManagerStateUnknown:      reject(@"Bluetooth not ON",@"Unknown", nil);       return;
        case CBManagerStateUnsupported:  reject(@"STATE_OFF",@"Unsupported", nil);          return;
    }
 
    [centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:YES]}];
}

 
RCT_EXPORT_METHOD(scanByService: (NSString *)uid options:(NSDictionary *)options 
    resolve: (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){

    if (!centralManager) { reject(@"Device does not support Bluetooth", @"Adapter is Null", nil); return; }
    
    switch (centralManager.state) {
        case CBManagerStatePoweredOn:    break;
        case CBManagerStatePoweredOff:   reject(@"Bluetooth not ON",@"Powered off", nil);   return;
        case CBManagerStateResetting:    reject(@"Bluetooth not ON",@"Resetting", nil);     return;
        case CBManagerStateUnauthorized: reject(@"Bluetooth not ON",@"Unauthorized", nil);  return;
        case CBManagerStateUnknown:      reject(@"Bluetooth not ON",@"Unknown", nil);       return;
        case CBManagerStateUnsupported:  reject(@"STATE_OFF",@"Unsupported", nil);          return;
    }
 
    [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:uid]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:YES]}];
}


RCT_EXPORT_METHOD(stopScan:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){

    [centralManager stopScan];
    resolve(@"Stopping Scan");
}

RCT_EXPORT_METHOD(enableAdapter){
    RCTLogInfo(@"enableAdapter function called");
}

RCT_EXPORT_METHOD(disableAdapter){
    RCTLogInfo(@"disableAdapter function called");
}

RCT_EXPORT_METHOD(getAdapterState:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){
    
    switch (centralManager.state) {
        case CBManagerStatePoweredOn:       resolve(@"STATE_ON"); return;
        case CBManagerStatePoweredOff:      resolve(@"STATE_OFF"); return;
        case CBManagerStateResetting:       resolve(@"STATE_TURNING_ON"); return;
        case CBManagerStateUnauthorized:    resolve(@"STATE_OFF"); return;
        case CBManagerStateUnknown:         resolve(@"STATE_OFF"); return;
        case CBManagerStateUnsupported:     resolve(@"STATE_OFF"); return;
    }
}

RCT_EXPORT_METHOD(isActive: 
     (RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject){
  
    resolve(([centralManager state] == CBManagerStatePoweredOn) ? @YES : @NO);
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    RCTLogInfo(@"Found Name: %@", [peripheral name]);
    RCTLogInfo(@"Found Services: %@", [peripheral services]);
    RCTLogInfo(@"Found Id : %@", [peripheral identifier]);
    RCTLogInfo(@"Found UUID String : %@", [[peripheral identifier] UUIDString]);

    NSArray *keys = [advertisementData allKeys];
    for (int i = 0; i < [keys count]; ++i) {
        id key = [keys objectAtIndex: i];
        NSString *keyName = (NSString *) key;
        NSObject *value = [advertisementData objectForKey: key];
        if ([value isKindOfClass: [NSArray class]]) {
            printf("   key: %s\n", [keyName cStringUsingEncoding: NSUTF8StringEncoding]);
            NSArray *values = (NSArray *) value;
            for (int j = 0; j < [values count]; ++j) {
                NSObject *aValue = [values objectAtIndex: j];
                printf("       %s\n", [[aValue description] cStringUsingEncoding: NSUTF8StringEncoding]);
                printf("       is NSData: %d\n", [aValue isKindOfClass: [NSData class]]);
            }
        } else {
            const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
            printf("   key: %s, value: %s\n", [keyName cStringUsingEncoding: NSUTF8StringEncoding], valueString);
        }
    }

    NSMutableDictionary *params =  [[NSMutableDictionary alloc] initWithCapacity:1];      
    NSMutableArray *paramsUUID = [[NSMutableArray alloc] init];

    NSObject *kCBAdvDataServiceUUIDs = [advertisementData objectForKey: @"kCBAdvDataServiceUUIDs"];
    if ([kCBAdvDataServiceUUIDs isKindOfClass:[NSArray class]]) {
        NSArray *uuids = (NSArray *) kCBAdvDataServiceUUIDs;
        RCTLogInfo(@"🔵 [iOS Native] Total de Service UUIDs encontrados: %lu", (unsigned long)[uuids count]);
        for (int j = 0; j < [uuids count]; ++j) {
            NSObject *aValue = [uuids objectAtIndex: j];
            RCTLogInfo(@"🔵 [iOS Native] Service UUID %d - Tipo: %@", j, NSStringFromClass([aValue class]));
            RCTLogInfo(@"🔵 [iOS Native] Service UUID %d - Valor bruto: %@", j, aValue);
            
            // 🔥 CORREÇÃO: Sempre usar UUID completo para evitar truncamento
            if ([aValue isKindOfClass:[CBUUID class]]) {
                CBUUID *uuid = (CBUUID *)aValue;
                NSString *uuidString = [uuid UUIDString];
                
                // 🔥 SEMPRE usar UUID completo para garantir compatibilidade
                if ([uuidString isEqualToString:@"7777"] || [uuidString containsString:@"7777"]) {
                    uuidString = @"00007777-0000-1000-8000-00805F9B34FB";
                    RCTLogInfo(@"🔵 [iOS Native] Usando UUID completo: %@", uuidString);
                }
                
                [paramsUUID addObject:uuidString];
                RCTLogInfo(@"🔵 [iOS Native] Service UUID final: %@", uuidString);
            } else {
                NSString *description = [aValue description];
                [paramsUUID addObject:description];
                RCTLogInfo(@"🔵 [iOS Native] Service UUID (fallback): %@", description);
            }
        }
    } else {
        RCTLogInfo(@"🔵 [iOS Native] Nenhum Service UUID encontrado ou não é array");
    }

    RSSI = RSSI && RSSI.intValue < 127 ? RSSI : nil;

    params[@"serviceUuids"] = paramsUUID;
    params[@"rssi"] = RSSI;
    params[@"deviceName"] = [peripheral name];
    params[@"deviceAddress"] = [peripheral identifier];
    params[@"txPower"] = [advertisementData objectForKey: @"kCBAdvDataTxPowerLevel"];
    
    // 🔥 ADICIONAR: Ler Manufacturer Data (Android envia via manufData)
    NSObject *kCBAdvDataManufacturerData = [advertisementData objectForKey: @"kCBAdvDataManufacturerData"];
    if ([kCBAdvDataManufacturerData isKindOfClass:[NSData class]]) {
        NSData *manufacturerData = (NSData *) kCBAdvDataManufacturerData;
        const unsigned char *bytes = (const unsigned char *)[manufacturerData bytes];
        NSUInteger length = [manufacturerData length];
        
        NSMutableArray *manufDataArray = [[NSMutableArray alloc] init];
        // 🔥 CORREÇÃO: Pular os primeiros 2 bytes (companyId + size) para pegar apenas o deviceID
        for (NSUInteger i = 2; i < length; i++) {
            [manufDataArray addObject:@(bytes[i])];
        }
        
        params[@"manufData"] = manufDataArray;
        params[@"companyId"] = @(224); // EnumBle.COMPANY_ID
        RCTLogInfo(@"🔵 [iOS Native] Manufacturer Data encontrado: %@ bytes, deviceID: %@ bytes", @(length), @(length-2));
    } else {
        RCTLogInfo(@"🔵 [iOS Native] Nenhum Manufacturer Data encontrado");
    }
    
    [self sendEventWithName:@"onDeviceFound" body:params];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Check BT status");
    NSMutableDictionary *params =  [[NSMutableDictionary alloc] initWithCapacity:1];      
    switch (central.state) {
        case CBManagerStatePoweredOff:
            params[@"enabled"] = @NO;
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBManagerStatePoweredOn:
            params[@"enabled"] = @YES;
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            break;
        case CBManagerStateResetting:
            params[@"enabled"] = @NO;
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBManagerStateUnauthorized:
            params[@"enabled"] = @NO;
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBManagerStateUnknown:
            params[@"enabled"] = @NO;
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBManagerStateUnsupported:
            params[@"enabled"] = @NO;
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
    [self sendEventWithName:@"onBTStatusChange" body:params];
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"%ld, CBPeripheralManagerStatePoweredOn", peripheral.state);
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"%ld, CBPeripheralManagerStatePoweredOff", peripheral.state);
            break;
        case CBManagerStateResetting:
            NSLog(@"%ld, CBPeripheralManagerStateResetting", peripheral.state);
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"%ld, CBPeripheralManagerStateUnauthorized", peripheral.state);
            break;
        case CBManagerStateUnsupported:
            NSLog(@"%ld, CBPeripheralManagerStateUnsupported", peripheral.state);
            break;
        case CBManagerStateUnknown:
            NSLog(@"%ld, CBPeripheralManagerStateUnknown", peripheral.state);
            break;
        default:
            break;
    }
}


@end
  
