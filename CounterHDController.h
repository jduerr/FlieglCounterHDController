//
//  CounterHDController.h
//  CounterInclinationViewer
//
//  Created by Johannes Dürr on 18.05.17.
//  Copyright © 2017 Johannes Dürr. All rights reserved.
//




#pragma mark - Introduction

/*  ************* -------- ---          The Delegate Protocol          --- -------- ************* */
/*________________________________________________________________________________________________*/
/*
 * The following methods are divided into two categories:
 * 1. Required
 * 2. Optional
 *
 * You must adopt and implement the required methods as follows:
 *
 * cc_didUpdateAvailablePeripherals:
 *    The CounterHDController will scan for Peripherals and call "cc_didUpdateAvailablePeripherals" if it finds
 *    CounterHD Beacons, giving you a NSDictionary with CBPeripherals that it found. Use
 *    NSDictionaries "allKeys", "allValues" or "objectForKey" to get the Peripherals from the
 *    dictionary. If you are interested in working with one of the Peripherals, call
 *    "connectPeripheral" on the CounterHDController.
 *
 * While connected to the peripheral, your instance of CounterHDController will try to forward all
 * calls from the Peripheral to the delegate if the matching methods are implemented. See the section
 * @optional of this Header File to see wich methods are available to you.
 *
 *
 *
 * USAGE:
 * 
 * 1. Adopt the CounterHDController delegate protocoll in your class:
 *
 *          @interface YOURCLASS : PARENTCLASS <CounterHDDelegate>
 *          {
 *              // put your instance variables here...
 *              CounterHDController* beaconController
 *          }
 *          @end
 *
 * 2. Create an instance of CounterHDController and assign your Controller as its delegate i.e. in your - (void) viewDidLoad{}
 *
 *          beaconController = [[CounterHDController alloc]initWithDelegate:self autoReconnecting:YES];
 *          [beaconController setIsLoggingEnabled:YES];
 *
 * 3. Implement the methods that are required by the delegate protocoll:
 *
 *          - (void)cc_didUpdateAvailablePeripherals:(NSDictionary *)peripherals{
 *               NSArray* foundPeripherals = [peripherals allValues];
 *               [beaconController connectPeripheral:[foundPeripherals firstObject]];
 *           }
 *
 * 4. Implement all optional methods that provide informations that you are interested in. The CounterHDController will update you 
 *    as soon as new data arrives. You also can use the public declared functions to configure, manipulate or command the
 *    connected peripheral.
 *
 *
 *
 * 5. Have fun!
 *
 *
 */



@import CoreBluetooth;
@import CoreLocation;

#import <Foundation/Foundation.h>

#pragma mark - public types, constants & definitions

#define FLIEGL_BEACON_SERVICE_UUID          @"C93AAAA0-C497-4C95-8699-01B142AF0C24"
#define FLIEGL_SENSOR_PLUS_SERVICE_UUID     @"C83AAAA0-C497-4C95-8699-01B142AF0C24"
#define FLIEGL_BEACON_ONLY_SERVICE_UUID     @"C23AAAA0-C497-4C95-8699-01B142AF0C24"


#define WRITE                               0x02
#define READ                                0x01

#define CMD_FILTER_TIME                     16
#define CMD_AXIS_MODE                       17
#define CMD_AXIS_CALIB                      18
#define CMD_AXIS_THRESH_TIME                19
#define CMD_AXIS_BOUNDS                     20
#define CMD_BASIC_LOCALNAME                 21
#define CMD_BASIC_MAJOR                     22
#define CMD_BASIC_MINOR                     23
#define CMD_BASIC_TXPOWER                   24
#define CMD_BASIC_UUID                      25
#define CMD_EEPROM_TRANSPORT                26
#define CMD_READ_AXIS_CONFIG                27
#define CMD_EEPROM_SELF_TEST                28
#define CMD_FSEC_SET_USER_ROLE              29
#define CMD_FSEC_SET_NEW_PIN                30
#define CMD_SET_CURRENT_TIME                31
#define CMD_READ_CURRENT_TIME               32
#define CMD_SET_RADIO_POWER                 33
#define CMD_READ_RADIO_POWER                34
#define CMD_SET_VGPS_LOCATION               35
#define CMD_SET_LED_BLINK                   36
#define CMD_READ_SENSIBILITY_TO_rsSTART     44
#define CMD_READ_ABSOLUTE_EVENT_ID          45
#define CMD_READ_DAY_COUNT_YES_OR_NO        47
#define CMD_SET_TIME_DISPLAY_MODE           64
#define CMD_READ_TIME_DISPLAY_MODE          65
#define CMD_READ_FLIEGL_COUNTER_PERIPH_TYPE 66
#define CMD_RESET_FACTORY_DEFAULT_WO_CALIB  67

#define CMD_READ_PITCH_METERING_ACTIVE      49
#define CMD_READ_MINUTES_TO_SLEEP           51
#define CMD_READ_HOURS_TO_SLEEP             52

#define CMD_READ_APPLICATION_PURPOSE        53

#define CMD_READ_MIN_AXIS_ROTATION_LOAD     58
#define CMD_READ_AVG_AXIS_ROTATION_LOAD     61
#define CMD_READ_MODE4_BORDER_INCL          63
#define CMD_RESET_SLEEP_COUNTER             37
#define CMD_TOGGLE_SLEEP_COUNTER_ON_OFF     38
#define CMD_SET_SLEEP_TIMEOUT_MINUTES       39
#define CMD_SET_SLEEP_TIMEOUT_HOURS         40
#define CMD_SET_LIS_WAKEUP_VALUE            41
#define CMD_SET_LIS_MOVEMENT_BORDER_VALUE   43
#define CMD_SET_AUTO_DAILY_COUNTER_ON_OFF   46
#define CMD_SET_RESET_MANUAL_DAILY_COUNT    48
#define CMD_SET_PITCH_METERING_ON_OFF       50
#define CMD_SET_SET_APPLICATION_PURPOSE     54
#define CMD_SET_MIN_AXIS_ROTATION_LOAD      57
#define CMD_TOGGLE_AUTOCALIB_ROTATION_METER 59
#define CMD_SET_AVG_AXIS_ROTATION_LOAD      60
#define CMD_SET_MODE4_BORDER_INCL           62



uint8_t currentPacketNumber;

unsigned int biggest_id;
unsigned int packetIDMax;

typedef struct __attribute__((packed))
{
    uint16_t packetNum;
    unsigned char payload[18];
}st_eep_transport_Msg;

typedef union{
    unsigned char bytes[20];
    st_eep_transport_Msg eepTransportMsg;
}un_st_eep_transport_Msg;

typedef union{
    uint8_t bytes[2];
    int16_t si;
}int16toByte;

typedef union{
    uint8_t bytes[2];
    uint16_t ui;
}uint16toByte;

typedef union{
    uint32_t ui32;
    unsigned char bytes[4];
}uint32ToByte;

typedef union{
    uint8_t bytes[4];
    Float32 float_val;
}float2Byte;

typedef union{
    unsigned char bytes[582520];
    un_st_eep_transport_Msg messages[29126];
}un_eeprom;

typedef enum{
    EEP_EVT_MODE_DISABLED = 0,
    EEP_EVT_MODE_BOUNDARIES_COUNT = 1,
    EEP_EVT_MODE_BOUNDARIES_TIME = 2,
    EEP_EVT_MODE_PROCESS_COUNT = 3
}en_eep_event_Mode;

typedef enum{
    kRadioPowerLevel_Highest_04_db = 0,
    kRadioPowerLevel_Default_00_db = 1,
    kRadioPowerLevel_Low_neg_04_db = 2,
    kRadioPowerLevel_Lower_0_neg_08_db = 3,
    kRadioPowerLevel_Lower_1_neg_12_db = 4,
    kRadioPowerLevel_Lower_2_neg_16_db = 5,
    kRadioPowerLevel_Lower_3_neg_20_db = 6
}kRadioPowerLevel;

typedef enum{
    EEP_EVT_FLAVOR_DISABLED = 0,
    EEP_EVT_FLAVOR_OVER = 1,
    EEP_EVT_FLAVOR_UNDER = 2,
    EEP_EVT_FLAVOR_OVERANDUNDER = 3,
    EEP_EVT_FLAVOR_WITHIN_BOUNDS = 4,
    EEP_EVT_FLAVOR_OUTOF_BOUNDS = 5
}en_eep_event_FLAVOR;

typedef enum{
    EEP_EVT_AXIS_RS =0,
    EEP_EVT_AXIS_X = 1,
    EEP_EVT_AXIS_Y = 2,
    EEP_EVT_AXIS_Z = 3,
    EEP_EVT_AXIS_INVALID = 255
    
}en_eep_event_Axis;

typedef enum{
    en_USER_ROLE_ANONYMOUS = 0,
    en_USER_ROLE_USER = 1,
    en_USER_ROLE_TRUSTED_USER = 2,
    en_USER_ROLE_OWNER = 3,
    en_USER_ROLE_MAN_SERVICE = 4,
    en_USER_ROLE_MANUFACTURER = 5
}en_User_Role;

typedef struct __attribute__((packed))
{
    uint32_t 						eepID;
    en_eep_event_Mode               mode;
    en_eep_event_FLAVOR             flavor;
    en_eep_event_Axis               axis;
    uint8_t							rs_state;
    time_t							event_date;
    uint32_t						event_count;
    uint32_t						event_pCount;
    time_t						    event_duration;
    Float32							latitude;
    Float32							longitude;
    unsigned char 			        unused[18];
    uint8_t							crc8;
}st_eep_Event;

#define EEP_EVENT_SIZE 51

typedef union
{
    unsigned char bytes[EEP_EVENT_SIZE];
    st_eep_Event eep_event;
}un_eep_Event;

#pragma mark - HDBEvent Helper Class

@interface HDBEvent : NSObject{
    st_eep_Event evt_data;
}

@property (nonatomic) uint32_t eepID;
@property (nonatomic) uint8_t mode;
@property (nonatomic) uint8_t flavor;
@property (nonatomic) uint8_t axis;
@property (nonatomic) uint8_t rsState;
@property (nonatomic) time_t eventDate;
@property (nonatomic) uint32_t eventCount;
@property (nonatomic) uint32_t eventProcessCount;
@property (nonatomic) time_t eventDuration;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) uint8_t crc8;
@property (nonatomic) NSData* _Nullable proprietaryData;


@end

#pragma mark - CounterHDController Class definition

@interface CounterHDController : NSObject <CBPeripheralDelegate, CBCentralManagerDelegate>
{
    CBCentralManager*   manager;
    CBPeripheral*       selected_peripheral;
    NSTimer*            connectionTimer;
    
    //unsigned char eprom8bytes[524280];
    
    NSMutableData* eepReceivedDataStream;
    //un_eeprom myEeprom;
    //un_eep_Event eep_Events[10280];
    NSMutableDictionary* eventDictionary;
    Boolean isEEPTransferInitiated;
}

#pragma mark - Properties

@property (nonatomic) id _Nonnull                   delegate;
@property (nonatomic) BOOL                          isLoggingEnabled;
@property (nonatomic) BOOL                          isAutoReconnecting;
@property (nonatomic) NSMutableDictionary* _Nonnull foundCharacteristics;
@property (nonatomic) NSMutableDictionary* _Nonnull foundPeripherals;
@property (nonatomic) NSMutableDictionary* _Nonnull foundPeripherals_sPlus;
@property (nonatomic) uint16_t peripheralPin;
@property (nonatomic) en_User_Role peripheralRole;

#pragma mark - Initialisation / Connection handling

- (instancetype _Nonnull )initWithDelegate:(_Nonnull id)delegate autoReconnecting:(BOOL)reconnecting userRole:(en_User_Role)role pin:(uint16_t)pin;
- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral autoReconnecting:(BOOL)reconnecting;
- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral;
- (void)disconnectPeripheral:(CBPeripheral* _Nonnull)peripheral;
- (void)resetManager;

#pragma mark - Device Manipulation / Configuration

/*  ************* --------  Device configuration and manipulation methods  -------- ************* */
/*________________________________________________________________________________________________*/

// Low Pass filter ---------------------------------------------------------------------------------


-(void)readEEPMemoryInfo;

/**
 Sets a new filter time for x axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)setLowPassFilterTime_X_s:(uint8_t)newFilterTime_s;

/**
 Sets a new filter time for y axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)setLowPassFilterTime_Y_s:(uint8_t)newFilterTime_s;

/**
 Sets a new filter time for z axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)setLowPassFilterTime_Z_s:(uint8_t)newFilterTime_s;

/**
 Sets new filter times for x, y, and z axis.

 @param newX : the new filter time in seconds for the x axis.
 @param newY : the new filter time in seconds for the y axis.
 @param newZ : the new filter time in seconds for the z axis.
 */
- (void)setLowPassFilterTime_XYZ_With_X:(uint8_t)newX Y:(uint8_t)newY Z:(uint8_t)newZ;

// Peripheral Time configuration -------------------------------------------------------------------

/**
 Sends and sets the iDevice's current time (seconds since 1970...) to the peripheral.
 */
- (void)setPeripheralCurrentTime;

/**
 Sends a "read time" request to the connected peripheral
 */
- (void)readPeripheralCurrentTime;


// Peripheral vGPS configuration ------------------------------------------------------------------

/**
 Sends and sets a location with timestamp for the peripheral wich it will
 use to geo tag events for up to 2 hours.
 **/
- (void)setPeripheralVLocation:(CLLocation*_Nonnull)location;


// Peripheral Radio configuration ------------------------------------------------------------------

- (void) setPeripheralRadioPower:(kRadioPowerLevel)rPLevel;
- (void) readPeripheralRadioPower;

// User Roles     ----------------------------------------------------------------------------------
- (void)setUserRole:(en_User_Role)role withPin:(uint16_t)pin;

- (void)setNewPin:(uint16_t)pin forUserRole:(en_User_Role)role;


// Axis calibration --------------------------------------------------------------------------------

/**
 Calibrate (set 0) the x axis to the current inclination.
 */
- (void)calibrate_X_Axis;

/**
 Calibrate (set 0) the y axis to the current inclination.
 */
- (void)calibrate_Y_Axis;

/**
 Calibrate (set0) the z axis to the current inclination.
 */
- (void)calibrate_Z_Axis;

/**
 Calibrate (set0) all three axes to the current inclination values.
 */
- (void)calibrate_XYZ_Axis;

/**
 Undo the calibration for the x axis.
 */
- (void)reset_X_calibration;

/**
 Undo the calibration for the y axis.
 */
- (void)reset_Y_calibration;

/**
 Undo the calibration for the z axis.
 */
- (void)reset_Z_calibration;

/**
 Undo the calibration for all three axes.
 */
- (void)reset_XYZ_calibration;

/**
 Invert measured inclination of x axis.

 @param inv : whether or not to invert (*-1) the measurement.
 */
- (void)invert_X_Axis:(BOOL)inv;

/**
 Invert measured inclination of y axis.

 @param inv : whether or not to invert (*-1) the measurement.
 */
- (void)invert_Y_Axis:(BOOL)inv;

/**
 Invert measured inclination of z axis.

 @param inv : whether or not to invert (*-1) the measurement.
 */
- (void)invert_Z_Axis:(BOOL)inv;

/**
 Invert measured inclination of all three axes.

 @param inv : whether or not to invert (*-1) the measurements.
 */
- (void)invert_XYZ_Axis:(BOOL)inv;

- (void)set_resetFactoryDefaultsWithoutCalibration:(uint16_t)securityCode;

// Axis Mode and Flavour configuration -------------------------------------------------------------

/**
 Set a new mode, flavor and rs dependency. Available modes and flavors are
 - Disabled (0)
    - Disabled (0)
 - Count Boundaries (1)
    - Over Bound
    - Under Bound
    - Over AND Under Bound
 - Time track Boundaries (1)
    - Within Bounds
    - Out of Bounds
 - Process Counting (2)
    - Disabled (0)
 
 You can refer to / use en_eep_event_Mode, en_eep_event_Flavor enumerations.

 @param xMode : The new mode to set.
 @param xFlavor : The new flavor to set.
 @param rsDep : Whether or not the mode should be RS Activity dependent.
 */
- (void)setAxisModeWith_XMode:(uint8_t)xMode
                             XFlavor:(uint8_t)xFlavor
                         rsDependent:(uint8_t)rsDep;

/**
 Set a new mode, flavor and rs dependency. Available modes and flavors are
 - Disabled (0)
 - Disabled (0)
 - Count Boundaries (1)
 - Over Bound
 - Under Bound
 - Over AND Under Bound
 - Time track Boundaries (1)
 - Within Bounds
 - Out of Bounds
 - Process Counting (2)
 - Disabled (0)
 
 You can refer to / use en_eep_event_Mode, en_eep_event_Flavor enumerations.

 @param yMode The new mode to set.
 @param yFlavor The new Flavor to set.
 @param rsDep Whether or not the Mode will be RS Activity dependent.
 */
- (void)setAxisModeWith_YMode:(uint8_t)yMode
                             YFlavor:(uint8_t)yFlavor
                         rsDependent:(uint8_t)rsDep;

/**
 Set a new mode, flavor and rs dependency. Available modes and flavors are
 - Disabled (0)
 - Disabled (0)
 - Count Boundaries (1)
 - Over Bound
 - Under Bound
 - Over AND Under Bound
 - Time track Boundaries (1)
 - Within Bounds
 - Out of Bounds
 - Process Counting (2)
 - Disabled (0)
 
 You can refer to / use en_eep_event_Mode, en_eep_event_Flavor enumerations.

 @param zMode The new mode to set.
 @param zFlavor The new flavor to set.
 @param rsDep Whether or not the mode will be RS Activity dependent.
 */
- (void)setAxisModeWith_ZMode:(uint8_t)zMode
                             ZFlavor:(uint8_t)zFlavor
                         rsDependent:(uint8_t)rsDep;

/**
 Set a new mode, flavor and rs dependency. Available modes and flavors are
 - Disabled (0)
 - Disabled (0)
 - Count Boundaries (1)
 - Over Bound
 - Under Bound
 - Over AND Under Bound
 - Time track Boundaries (1)
 - Within Bounds
 - Out of Bounds
 - Process Counting (2)
 - Disabled (0)
 
 You can refer to / use en_eep_event_Mode, en_eep_event_Flavor enumerations.

 @param xMode The new mode for x axis to set.
 @param xFlavor the new flavor for x axis to set.
 @param rsxDep Whether or not x Axis mode will be RS Activity dependent
 @param yMode The new mode for the y axis to set.
 @param yFlavor The new flavor to set for the y axis.
 @param rsyDep Whether or not y Axis mode will be RS Activity dependent.
 @param zMode The new mode for the z axis to set.
 @param zFlavor The new flavor to set for the z axis.
 @param rszDep Whether or not z Axis mode will be RS Activity dependent.
 */
- (void)setAxisModeWith_XMode:(uint8_t)xMode
                             XFlavor:(uint8_t)xFlavor
                         rsxDependent:(uint8_t)rsxDep
                               YMode:(uint8_t)yMode
                             YFlavor:(uint8_t)yFlavor
                         rsyDependent:(uint8_t)rsyDep
                               ZMode:(uint8_t)zMode
                             ZFlavor:(uint8_t)zFlavor
                         rszDependent:(uint8_t)rszDep;
// Axis Boundaries ---------------------------------------------------------------------------------

/**
 Set new boundary values.

 @param topBound : The inclination of the upper bound.
 @param botBound : The inclination of the bottom bound
 */
- (void)setAxisBoundariesWithXTop:(int16_t)topBound
                                 XBottom:(int16_t)botBound;

/**
 Set new boundary values

 @param topBound : The inclination of the upper bound.
 @param botBound : The inclination of the bottom bound.
 */
- (void)setAxisBoundariesWithYTop:(int16_t)topBound
                                 YBottom:(int16_t)botBound;

/**
 Set new boundary values

 @param topBound : The inclination of the upper bound.
 @param botBound : The inclination of the bottom bound.
 */
- (void)setAxisBoundariesWithZTop:(int16_t)topBound
                                 ZBottom:(int16_t)botBound;

/**
 Set new boundary values.

 @param topxBound : The inclination of the upper x bound.
 @param botxBound : The inclination of the bottom x bound.
 @param topyBound : The inclination of the upper y bound.
 @param botyBound : The inclination of the bottom y bound.
 @param topzBound : The inclination of the upper z bound.
 @param botzBound : The inclination of the bottom z bound.
 */
- (void)setAxisBoundariesWithXTop:(int16_t)topxBound
                                 XBottom:(int16_t)botxBound
                                 YBottom:(int16_t)topyBound
                                 YBottom:(int16_t)botyBound
                                 ZBottom:(int16_t)topzBound
                                 ZBottom:(int16_t)botzBound;

// Axis Inertia (threshold  times) -----------------------------------------------------------------

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia 
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startRS : The inertia for starting criteria.
 @param endRS : The inertia for stopping criteria.
 */
- (void)setAxisInertiaTimeThreshRSStart:(uint16_t)startRS andRSEnd:(uint16_t)endRS;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startX The inertia for starting criteria.
 @param endX The inertia for stopping criteria.
 */
- (void)setAxisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param starty : The inertia for starting criteria.
 @param endy : The inertia for stopping criteria.
 */
- (void)setAxisInertiaTimeThreshYStart:(uint16_t)starty andYEnd:(uint16_t)endy;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startz : The inertia for starting criteria.
 @param endz : The inertia for stopping criteria.
 */
- (void)setAxisInertiaTimeThreshZStart:(uint16_t)startz andZEnd:(uint16_t)endz;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startX : The inertia for starting criteria of x axis.
 @param endX : The inertia for stopping criteria of x axis.
 @param starty : The inertia for starting criteria of y axis.
 @param endy : The inertia for stopping criteria of y axis.
 @param startz : The inertia for starting criteria of z axis.
 @param endz : The inertia for stopping criteria of z axis.
 @param startrs : The inertia for starting criteria of RS Activity measurements.
 @param endrs : The inertia for stopping criteria of RS Activity measurements.
 */
- (void)setAxisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX
                                       YStart:(uint16_t)starty andYEnd:(uint16_t)endy
                                       ZStart:(uint16_t)startz andZEnd:(uint16_t)endz
                                      RSStart:(uint16_t)startrs andRSEnd:(uint16_t)endrs;

- (void)setTimeDisplayMode:(uint8_t)newMode;


// Set new beacon basic info -----------------------------------------------------------------------

/**
 iBeacon Basic information - Set a new Bluetooth local name.

 @param name : The new local name.
 */
- (void)basic_info_setNewLocalName:(NSString*_Nonnull)name;

/**
 iBeacon Basic information. Set a new minor value for the iBeacon Advertisment of the device.

 @param minor : The new minor value.
 */
- (void)basic_info_setNewMinor:(uint16_t)minor;

/**
 iBeacon Basic information. Set a new major value for the iBeacon Advertisment of the device.

 @param major : The new major value.
 */
- (void)basic_info_setNewMajor:(uint16_t)major;

/**
 iBeacon Basic information. Set a new tx power value for the iBeacon Advertisment of the device.

 @param txPower : The new tx power value.
 */
- (void)basic_info_setNewTXPower:(int8_t)txPower;

/**
 iBeacon Basic information. Set a new UUID value for the iBeacon Advertisment of the device.

 @param uuid The new UUID.
 */
- (void)basic_info_setNewUUID:(NSString*_Nonnull)uuid;


// DFU characteristic commands ---------------------------------------------------------------------

/**
 Commands the connected peripheral to reboot and stay in bootloader instead of booting up the 
 firmware.
 */
- (void)dfu_sendPeripheralToBootloader;

/**
 Commands teh connected peripheral to reboot.
 */
- (void)dfu_rebootPeripheral;

/**
 Commands the connected peripheral to switch iBeacon usage mode.
    - Automagically switches between:
        a) normal usage
        b) agricultural practices
 This is neccessary to setup a device for usage in an ISOBUS compatible environment.
 NOTE: Setting a device to agricultural practice will calculate a new major value having an
 CRC8 Checksum of major, minor, txPower and UUID as the MSB of the current major value.
 */
- (void)dfu_activateAgriCulturalUsage;

/**
 Commands the peripheral to store all current device configurations to the internal flash memory of 
 the device. This is neccessary to avoid loosing data on repowering/rebooting/restarting the device.
 */
- (void)dfu_savePStorage;

// EEProm ------------------------------------------------------------------------------------------

/**
 Commands the connected peripheral to transfer the complete eeprom storage.
 */
- (void)eeprom_startTransferBeginningWithEEP_ID:(uint32_t)req_start_id;


/**
 Commands the connected peripheral to perform an eeprom self test.
 */
- (void)eeprom_startSelfTest;

// Param Transport Request -------------------------------------------------------------------------
/**
 Commands the connected peripheral to transfer the axis configuration for a specified axis.

 @param axis : The axis we want to get the current configuration for.
 */
- (void)read_currentAxisConfiguration:(uint8_t)axis;

/**
 Sets whether or not the Peripheral will show activity and states as LED blink codes.
 
 @param newState : The new state of this option: (true - shows LED codes, false - LED deactivated)
 */
- (void)set_LED_Blink:(boolean_t)newState;

- (void)read_pitchMeteringState;
- (void)read_minutesToSleep;
- (void)read_hoursToSleep;
- (void)read_applicationPurpose;
- (void)read_minAxisRotationLoat;
- (void)read_averageAxisRotationLoad;
- (void)read_mode4BorderInclination;
- (void)reset_sleepCounter;
- (void)set_sleepCounterOnOrOff:(boolean_t)counterOn;
- (void)set_sleepCounter_Hours:(uint16_t)hours;
- (void)set_sleepCounter_Minutes:(uint16_t)minutes;
- (void)set_LIS_WakeUp_value: (uint8_t)value;
- (void)set_LIS_Movement_value: (uint8_t)value;
- (void)set_automaticDailyCountOnOrOff:(boolean_t)onOrOff;
- (void)reset_manual_dailyCounters;
- (void)set_pitchMetering_OnOrOff:(boolean_t)onOrOff;
- (void)set_applicationPurpose:(uint8_t)appPurpose;
- (void)set_minAxisRotationLoad:(uint8_t)minLoad;
- (void)start_autoCalibrationOfRotationMetering;
- (void)set_averageAxisRotationLoad:(uint8_t)avgLoad;
- (void)set_mode4BorderInclination:(uint8_t)inclination_border;


@end

#pragma mark - The Delegate Protocol

/*  ************* -------- ---          The Delegate Protocol          --- -------- ************* */
/*________________________________________________________________________________________________*/


@protocol CounterHDDelegate

#pragma mark - required

/*  ************* -------- ---                 Required                --- -------- ************* */
/*________________________________________________________________________________________________*/

/**
 This gets called if CounterHDController found peripherals matching CounterHD Hardware.

 @param peripherals : The peripherals it found.
 */

- (void)cc_didUpdateAvailablePeripherals:(NSDictionary*_Nonnull)peripherals;
- (void)cc_didUpdateAvailableSensorPlusPeripherals:(NSDictionary*_Nonnull)peripherals;

/*  ************* -------- ---                 Optional                --- -------- ************* */
/*________________________________________________________________________________________________*/
@optional
#pragma mark - optional
// OPTIONAL
/**
 The CoutnerHDController did connect to a pripheral.

 @param peripheral : The peripheral that has been connected.
 */
- (void) cc_didConnectPeripheral:(CBPeripheral*_Nullable)peripheral;

/**
 The CounterHDController did disconnect from a peripheral.

 @param peripheral : The peripheral that has been disconnected.
 */
- (void) cc_didDisconnectPeripheral:(CBPeripheral*_Nullable)peripheral;

- (void) cc_didUpdateEEPMemoryInfo:(uint32_t) maxPossible anCurrentMax:(uint32_t) currentMaxEvtID;

/**
 This method gets periodically called with updated totals for the following set of informations:

 @param xEventCount : The total Count of Events along the x axis.
 @param yEventCount : The total Count of Events along the y axis.
 @param zEventCount : The total Count of Events along the z axis.
 @param xActiveTime : The total time (minutes) of tracked activity along the x axis.
 @param yActiveTime : The total time (minutes) of tracked activity along the y axis.
 @param zActiveTime : The total time (minutes) of tracked activity along the z axis.
 @param xProcessCount : The total count of tracked processes along the x axis.
 @param yProcessCount : The total count of tracked processes along the y axis.
 @param zProcessCount : The total count of tracked processes along the z axis.
 */
- (void) cc_didUpdateTotalsForEventCount:(uint16_t)yEventCount
                        zEventCount:(uint16_t)zEventCount
                        yActiveTime:(uint32_t)yActiveTime
                        zActiveTime:(uint32_t)zActiveTime
                      yProcessCount:(uint16_t)yProcessCount
                      zProcessCount:(uint16_t)zProcessCount;


/**
 This method provides you general information about the connected CounterHD and is being
 called periodically.

 @param deviceType :the hardware device type
 @param deviceRevision :the hardware device revision
 @param buildNumber :the current firmware build number
 @param firmwareMajor :the major part of th firmware version. i.e. 2.xx
 @param firmwareMinor :the minor part of the firmware verison. i.e. X.23
 @param statusBits :a collection of flags indicating the state of the device.
 @param rs_time : A value indicating how long the beacon has been tracking activity
 @param rs_count A value indicating how often the beacon has been tracking activity
 */
- (void) cc_didUpdateDeviceStateWith_DeviceType:(uint16_t)deviceType
                           deviceRevision:(uint16_t)deviceRevision
                              buildNumber:(uint16_t)buildNumber
                            firmwareMajor:(uint8_t)firmwareMajor
                            firmwareMinor:(uint8_t)firmwareMinor
                               statusBits:(uint32_t)statusBits
                                  rs_time:(uint32_t)rs_time
                                 rs_count:(uint32_t)rs_count;


/**
 This method gives you the current configuration of an beacons axis. It is initially 
 valued 0x00 0x00... - And will be filled with correct values as an answer to requesting
 the axisconfiguration. (see manipulation methods)

 @param axis : the selected axis (0: none, 1: rs, 2: x-Axis, 3: y-Axis, 4: z-Axis)
 @param mode : the selected axis mode (count, time track,...)
 @param flavor :the selected flavor of the mode (over bound, under bound)
 @param filterTime_s : the selected low pass filter time in seconds
 @param isInverted : whether or not the axis value is inverted (* -1)
 @param isRSDependent whether or not tracking or counting only starts if rs activity is recognized.
 @param topBound : the upper bound inclination
 @param botBound : the bottom bound inclination
 @param topInertia : the inertia being used if crossing the top boundary
 @param botInertia : the inertia being used if crossing the bottom boundary
 */
- (void) cc_didUpdateAxisConfigurationForAxis:(uint8_t)axis
                                   mode:(uint8_t)mode
                                 flavor:(uint8_t)flavor
                             filterTime:(uint8_t)filterTime_s
                             isInverted:(uint8_t)isInverted
                          isRSDependent:(uint8_t)isRSDependent
                               topBound:(int16_t)topBound
                               botBound:(int16_t)botBound
                             topInertia:(uint16_t)topInertia
                             botInertia:(uint16_t)botInertia;


/**
 This periodically called method provides you with all current values of the beacons accelerometer.

 @param x_corrected : the current x-Inclination (using calibration)
 @param y_corrected : the current y-Inclination (using calibration)
 @param z_corrected : the current z-Inclination (using calibration)
 @param x : the current x-Inclination as raw value (ignoring calibration)
 @param y : the current y-Inclination as raw value (ignoring calibration)
 @param z : the current z-Inclination as raw value (ignoring calibration)
 @param gX : measured gravity affect along the x-Axis
 @param gY measured gravity affect along the y-Axis
 @param gZ measured gravity affect along the z-Axis
 */
- (void)cc_didUpdateInclincationForX:(float)x_corrected andY:(float)y_corrected andZ:(float)z_corrected rawX:(float)x rawY:(float)y rawZ:(float)z gravityX:(int8_t)gX gravityY:(int8_t)gY gravityZ:(int8_t)gZ frequencyFFT_z:(NSString*_Nullable)frequency;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param deviceType :the hardware device type
 */
- (void)cc_didUpdateDeviceType:(uint16_t)deviceType;

- (void)cc_didUpdate_RS_TotalApplication_s:(uint32_t)application_seconds andFillingStreetSecs:(uint32_t)street_seconds;

- (void)cc_didUpdate_absoluteLastEventID:(uint32_t)evtId
                       dailyProcessCount:(uint16_t)pCount_day dailyRSApplication_s:(uint32_t)RSapplic_s dailyRSStreet_s:(uint32_t)RSstreet_s
                            dailyRSCount:(uint32_t)dayCountRSTime;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param deviceRevision :the hardware device revision
 */
- (void)cc_didUpdateDeviceRevision:(uint16_t)deviceRevision;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param firmwareBuildNr :the current firmware build number
 */
- (void)cc_didUpdateFirmwareBuildNr:(uint16_t)firmwareBuildNr;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param major :the major part of th firmware version. i.e. 2.xx
 @param minor :the minor part of the firmware verison. i.e. X.23
 */
- (void)cc_didUpdateFirmwareMajor:(uint8_t)major andMinor:(uint8_t)minor;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param flags :a collection of flags indicating the state of the device.
 */
- (void)cc_didUpdateStatusFlags:(uint32_t)flags;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param rsTime : A value indicating how long the beacon has been tracking activity
 */
- (void)cc_didUpdateRSTime:(uint32_t)rsTime;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param rsCount A value indicating how often the beacon has been tracking activity
 */
- (void)cc_didUpdateRSCount:(uint32_t)rsCount;

- (void)cc_didUpdateModeDependendState(uint8_t)state;

/**
 The iBeacon Standard informations.

 @param minor :This beacons current minor value of its iBeacon Advertisment.
 */
- (void)cc_didUpdateMinor:(uint16_t)minor;


/**
 The iBeacon Standard information

 @param major :This beacons current major value of its iBeacon Advertisment.
 */
- (void)cc_didUpdateMajor:(uint16_t)major;

/**
 The Accelerometers chip-temperature (If available)

 @param temperature_dC : the chips temperature in deg celsius.
 */
- (void)cc_didUpdateLISTemperature:(int16_t)temperature_dC;

/**
 The iBeacon Standard information

 @param localName :This beacons current local name value of its active scan response Advertisment.
 */
- (void)cc_didUpdateLocalName:(NSString*_Nullable)localName;


/**
 The iBeacon Standard information

 @param txPower :This beacons current TX-Power value of its iBeacon Advertisment.
 */
- (void)cc_didUpdateTXPower:(int8_t)txPower;


/**
 The iBeacon Stnadard informations

 @param uuid :This beacons current UUID value of its iBeacon Advertisment. Please
 * be aware that this is the UUID that is being broadcastet - NOT the UUID your
 iOS device shows you if scanning for peripherals. iOS devices since iOS 6+ do NOT
 provide you the real UUIDs in scan results but give you locally generated ones instead.
 */
- (void)cc_didUpdateUUID:(NSString*_Nullable)uuid;


/**
 Action info (Button Events)

 @param isOn Whether or not the button 1 is being triggered.
 */
- (void)cc_didUpdateButton1_trigger:(BOOL)isOn;


/**
 Action info (Button Events)

 @param isOn whether or not the button 2 is being triggered.
 */
- (void)cc_didUpdateButton2_trigger:(BOOL)isOn;


/**
 Aciont info (Button Events)

 @param isOn whether or not the button 3 is being triggered.
 */
- (void)cc_didUpdateButton3_trigger:(BOOL)isOn;

/**
 Aciont info (Button Events)
 
 @param isOn whether or not the button 4 (extern) is being triggered.
 */
- (void)cc_didUpdateButton4_trigger:(BOOL)isOn;

/**
 After requesting an eeprom transfer - This method is being called
 periodically, providing you the current transfer status as percentage.

 @param percentage the current transfer state in %
 */
- (void)cc_didUpdateEepromTransferPercentage:(float)percentage;


/**
 After requesting an eeprom self test - This method is being called
 providing you the amount of errors it has encountered during the test as well
 as the retrieved data it has been reading after the test.

 @param errorCount : the total error count. (0x00 if everything went fine)
 @param testData : the test result read from eep. Should have value 0x01 through 0x0A - length: 10 Bytes.
 */
- (void)cc_didUpdateEepromSelftestResultErrorCount:(uint8_t)errorCount
                                           TestData:(NSData*_Nonnull)testData;

/**
 After requesting an eeprom transfer - This method is being called
 providing you all Events that have been found in the eeprom.

 @param eventDictionary a collection of all valid events found in eeprom storage.
 */
- (void)cc_didUpdateEepromTransferedEvents:(NSMutableDictionary*_Nullable)eventDictionary;


/**
 Peripheral is sending ints current battery info

 @param charge : The current battery charge as percentage
 @param dcdcEnabled : Whether or not the peripheral is using DCDC mode.
 */
- (void)cc_didUpdateBatteryCharge:(uint8_t)charge dcdcEnabled:(BOOL)dcdcEnabled;


/**
 Peripheral has updated value for its current selected user role.

 @param userRole : The en_User_Role identification.
 */
- (void)cc_didUpdateUserRole:(en_User_Role)userRole;

/** Written banks
*/

-(void)cc_didReadCurrentPacketNumber:(uint8_t)currentPacketNumber;


/**
 Peripheral has updated the value for its current time

 @param currentDate The current date / time as NSDate
 */
- (void)cc_didUpdateCurrentPeripheralTime:(NSDate*_Nonnull)currentDate;


/**
 Peripheral has updated the value of its radio power.

 @param radioPower - The power in db as signed 8bit integer.
 */
- (void)cc_didUpdateRadioPower:(int8_t)radioPower;

- (void)cc_didUpdateSensorPlusValuesWith_reed1_count:(uint16_t)count_r1
                                         reed2_count:(uint16_t)count_r2
                                         reed3_count:(uint16_t)count_r3
                                         reed4_count:(uint16_t)count_r4
                                         reed1_time:(uint16_t)time_r1
                                         reed2_time:(uint16_t)time_r2
                                         reed3_time:(uint16_t)time_r3
                                         reed4_time:(uint16_t)time_r4
                                          reed1_mode:(uint8_t)mode_r1
                                          reed2_mode:(uint8_t)mode_r2
                                          reed3_mode:(uint8_t)mode_r3
                                          reed4_mode:(uint8_t)mode_r4;

/**
 Peripheral has sent update on its current time display mode

 @param currentDisplayMode : the current time display mode
 Modi: 0: Gesamtzeit RS, 1: Tageszähler manuell RS, 2: Tageszähler automatisch RS, 3: Gesamtzeit Ausbringzeit, 4: Tagesz. manuell Ausbringzeit, 5. Tagesz.  automatisch Ausbringzeit, 6: Befüllungszeit Gesamt, 7: Befüllungszeit Tageszähler manuell, 8: Befüllunszeit Tageszähler automatisch. 
 */
- (void)cc_didUpdate_modeTimeDisplay:(uint8_t)currentDisplayMode;


/**
 Peripheral has sent update on its Fliegl peripheral type
 
 @param counterHardwareType : the peripheral type
 Modi: 1: CounterHD, 2: Display Counter 3: Sigfox Counter 
 */
- (void)cc_didUpdate_FlieglCounterDeviceType:(uint8_t)counterHardwareType;

- (void) cc_didUpdate_PitchMeteringState:(boolean_t)state;
- (void) cc_didUpdate_MinutesToSleep:(uint16_t)minutes;
- (void) cc_didUpdate_HoursToSleep:(uint16_t)hours;
- (void) cc_didUpdate_ApplicationPurpose:(uint8_t)purpose;
- (void) cc_didUpdate_MinAxisRotationLoad:(uint8_t)minAxisLoad;
- (void) cc_didUpdate_AverageAxisRotationLoad:(uint8_t)percentage;
- (void) cc_didUpdate_Mode4BorderInclination:(uint8_t)axis andBorderInclination:(uint8_t)border;


@required
//- (void)anotherRequiredMethod;

@end


