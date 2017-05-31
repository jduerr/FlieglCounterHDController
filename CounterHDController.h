//
//  CounterHDController.h
//  CounterInclinationViewer
//
//  Created by Johannes Dürr on 18.05.17.
//  Copyright © 2017 Johannes Dürr. All rights reserved.
//






/*  ************* -------- ---          The Delegate Protocol          --- -------- ************* */
/*________________________________________________________________________________________________*/
/*
 * The following methods are divided into two categories:
 * 1. Required
 * 2. Optional
 *
 * You must adopt and implement the required methods as follows:
 *
 * AvailablePeripherals:
 *    The CounterHDController will scan for Peripherals and call "availablePeripherals" if it finds
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
 *          - (void)availablePeripherals:(NSDictionary *)peripherals{
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

#import <Foundation/Foundation.h>

#define FLIEGL_BEACON_SERVICE_UUID      @"C93AAAA0-C497-4C95-8699-01B142AF0C24"
#define FLIEGL_BEACON_ONLY_SERVICE_UUID @"C93AAAA0-C497-4C95-8699-01B142AF0C24"


#define WRITE                   0x02
#define READ                    0x01

#define CMD_FILTER_TIME         16
#define CMD_AXIS_MODE           17
#define CMD_AXIS_CALIB          18
#define CMD_AXIS_THRESH_TIME    19
#define CMD_AXIS_BOUNDS         20
#define CMD_BASIC_LOCALNAME     21
#define CMD_BASIC_MAJOR         22
#define CMD_BASIC_MINOR         23
#define CMD_BASIC_TXPOWER       24
#define CMD_BASIC_UUID          25
#define CMD_EEPROM_TRANSPORT    26
#define CMD_READ_AXIS_CONFIG    27
#define CMD_EEPROM_SELF_TEST    28

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
    unsigned char bytes[145640];
    un_st_eep_transport_Msg messages[7282];
}un_eeprom;

typedef enum{
    EEP_EVT_MODE_DISABLED = 0,
    EEP_EVT_MODE_BOUNDARIES_COUNT = 1,
    EEP_EVT_MODE_BOUNDARIES_TIME = 2,
    EEP_EVT_MODE_PROCESS_COUNT = 3
}en_eep_event_Mode;

typedef enum{
    EEP_EVT_FLAVOR_DISABLED = 0,
    EEP_EVT_FLAVOR_OVER = 1,
    EEP_EVT_FLAVOR_UNDER = 2,
    EEP_EVT_FLAVOR_OVERANDUNDER = 3,
    EEP_EVT_FLAVOR_WITHIN_BOUNDS = 4,
    EEP_EVT_FLAVOR_OUTOF_BOUNDS = 5
}en_eep_event_FLAVOR;

typedef enum{
    EEP_EVT_AXIS_NONE = 0,
    EEP_EVT_AXIS_X = 1,
    EEP_EVT_AXIS_Y = 2,
    EEP_EVT_AXIS_Z = 3,
    
}en_eep_event_Axis;


typedef struct __attribute__((packed))
{
    uint16_t 						eepID;
    en_eep_event_Mode               mode;
    en_eep_event_FLAVOR             flavor;
    en_eep_event_Axis               axis;
    uint8_t							rs_state;
    time_t							event_date;
    uint16_t						event_count;
    uint16_t						event_pCount;
    uint16_t						event_duration;
    double							latitude;
    double							longitude;
    unsigned char 			unused[24];
    uint8_t							crc8;
}st_eep_Event;

#define EEP_EVENT_SIZE 51

typedef union
{
    unsigned char bytes[EEP_EVENT_SIZE];
    st_eep_Event eep_event;
}un_eep_Event;


@interface HDBEvent : NSObject

@property (nonatomic) uint16_t eepID;
@property (nonatomic) uint8_t mode;
@property (nonatomic) uint8_t flavor;
@property (nonatomic) uint8_t axis;
@property (nonatomic) uint8_t rsState;
@property (nonatomic) time_t eventDate;
@property (nonatomic) uint16_t eventCount;
@property (nonatomic) uint16_t eventProcessCount;
@property (nonatomic) time_t eventDuration;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) uint8_t crc8;

@end



@interface CounterHDController : NSObject <CBPeripheralDelegate, CBCentralManagerDelegate>
{
    CBCentralManager*   manager;
    CBPeripheral*       selected_peripheral;
    NSTimer*            connectionTimer;
    
    un_eeprom myEeprom;
    un_eep_Event eep_Events[2570];
    NSMutableDictionary* eventDictionary;
    Boolean isEEPTransferInitiated;
}

@property (nonatomic) id _Nonnull                   delegate;
@property (nonatomic) BOOL                          isLoggingEnabled;
@property (nonatomic) BOOL                          isAutoReconnecting;
@property (nonatomic) NSMutableDictionary* _Nonnull foundCharacteristics;
@property (nonatomic) NSMutableDictionary* _Nonnull foundPeripherals;


- (instancetype _Nonnull )initWithDelegate:(_Nonnull id)delegate autoReconnecting:(BOOL)reconnecting;
- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral autoReconnecting:(BOOL)reconnecting;
- (void)connectPeripheral:(CBPeripheral*_Nonnull)peripheral;
- (void)disconnectPeripheral:(CBPeripheral* _Nonnull)peripheral;




/*  ************* --------  Device configuration and manipulation methods  -------- ************* */
/*________________________________________________________________________________________________*/

// Low Pass filter ---------------------------------------------------------------------------------

/**
 Sets a new filter time for x axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)updateLowPassFilterTime_X_s:(uint8_t)newFilterTime_s;

/**
 Sets a new filter time for y axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)updateLowPassFilterTime_Y_s:(uint8_t)newFilterTime_s;

/**
 Sets a new filter time for z axis.

 @param newFilterTime_s : the new filter time in seconds
 */
- (void)updateLowPassFilterTime_Z_s:(uint8_t)newFilterTime_s;

/**
 Sets new filter times for x, y, and z axis.

 @param newX : the new filter time in seconds for the x axis.
 @param newY : the new filter time in seconds for the y axis.
 @param newZ : the new filter time in seconds for the z axis.
 */
- (void)updateLowPassFilterTime_XYZ_With_X:(uint8_t)newX Y:(uint8_t)newY Z:(uint8_t)newZ;

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
- (void)configure_AxisModeWith_XMode:(uint8_t)xMode
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
- (void)configure_AxisModeWith_YMode:(uint8_t)yMode
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
- (void)configure_AxisModeWith_ZMode:(uint8_t)zMode
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
- (void)configure_AxisModeWith_XMode:(uint8_t)xMode
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
- (void)configure_AxisBoundariesWithXTop:(int16_t)topBound
                                 XBottom:(int16_t)botBound;

/**
 Set new boundary values

 @param topBound : The inclination of the upper bound.
 @param botBound : The inclination of the bottom bound.
 */
- (void)configure_AxisBoundariesWithYTop:(int16_t)topBound
                                 YBottom:(int16_t)botBound;

/**
 Set new boundary values

 @param topBound : The inclination of the upper bound.
 @param botBound : The inclination of the bottom bound.
 */
- (void)configure_AxisBoundariesWithZTop:(int16_t)topBound
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
- (void)configure_AxisBoundariesWithXTop:(int16_t)topxBound
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
- (void)configure_axisInertiaTimeThreshRSStart:(uint16_t)startRS andRSEnd:(uint16_t)endRS;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startX The inertia for starting criteria.
 @param endX The inertia for stopping criteria.
 */
- (void)configure_axisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param starty : The inertia for starting criteria.
 @param endy : The inertia for stopping criteria.
 */
- (void)configure_axisInertiaTimeThreshYStart:(uint16_t)starty andYEnd:(uint16_t)endy;

/**
 Once an Event Trigger criteria is met, use inertia to prevent the device from immediately fire an
 Event. You can set inertia values in seconds for Start and stop conditions. I.E. If start inertia
 equals 2 seconds for Counting mode, the device will only increment the counter if the inclination
 is higher than the upper bound inclination for longer then 2 seconds.

 @param startz : The inertia for starting criteria.
 @param endz : The inertia for stopping criteria.
 */
- (void)configure_axisInertiaTimeThreshZStart:(uint16_t)startz andZEnd:(uint16_t)endz;

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
- (void)configure_axisInertiaTimeThreshXStart:(uint16_t)startX andXEnd:(uint16_t)endX
                                       YStart:(uint16_t)starty andYEnd:(uint16_t)endy
                                       ZStart:(uint16_t)startz andZEnd:(uint16_t)endz
                                      RSStart:(uint16_t)startrs andRSEnd:(uint16_t)endrs;
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
- (void)eeprom_startTransfer;


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

@end



/*  ************* -------- ---          The Delegate Protocol          --- -------- ************* */
/*________________________________________________________________________________________________*/


@protocol CounterHDDelegate

/*  ************* -------- ---                 Required                --- -------- ************* */
/*________________________________________________________________________________________________*/
/**
 This gets called if CounterHDController found peripherals matching CounterHD Hardware.

 @param peripherals : The peripherals it found.
 */
- (void)availablePeripherals:(NSDictionary*_Nonnull)peripherals;


/*  ************* -------- ---                 Optional                --- -------- ************* */
/*________________________________________________________________________________________________*/
@optional
// OPTIONAL
/**
 The CoutnerHDController did connect to a pripheral.

 @param peripheral : The peripheral that has been connected.
 */
- (void) didConnectPeripheral:(CBPeripheral*_Nullable)peripheral;

/**
 The CounterHDController did disconnect from a peripheral.

 @param peripheral : The peripheral that has been disconnected.
 */
- (void) didDisconnectPeripheral:(CBPeripheral*_Nullable)peripheral;

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
- (void) updateTotalsForXEventCount:(uint16_t)xEventCount
                        yEventCount:(uint16_t)yEventCount
                        zEventCount:(uint16_t)zEventCount
                        xActiveTime:(uint16_t)xActiveTime
                        yActiveTime:(uint16_t)yActiveTime
                        yActiveTime:(uint16_t)zActiveTime
                      xProcessCount:(uint16_t)xProcessCount
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
- (void) updateDeviceStateWith_DeviceType:(uint16_t)deviceType
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
- (void) updateAxisConfigurationForAxis:(uint8_t)axis
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
- (void)updateInclincationForX:(float)x_corrected andY:(float)y_corrected andZ:(float)z_corrected rawX:(float)x rawY:(float)y rawZ:(float)z gravityX:(int8_t)gX gravityY:(int8_t)gY gravityZ:(int8_t)gZ;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param deviceType :the hardware device type
 */
- (void)deviceState_deviceType:(uint16_t)deviceType;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param deviceRevision :the hardware device revision
 */
- (void)deviceState_deviceRevision:(uint16_t)deviceRevision;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param firmwareBuildNr :the current firmware build number
 */
- (void)deviceState_firmwareBuildNr:(uint16_t)firmwareBuildNr;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param major :the major part of th firmware version. i.e. 2.xx
 @param minor :the minor part of the firmware verison. i.e. X.23
 */
- (void)deviceState_firmwareMajor:(uint8_t)major andMinor:(uint8_t)minor;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param flags :a collection of flags indicating the state of the device.
 */
- (void)deviceState_statusFlags:(uint32_t)flags;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param rsTime : A value indicating how long the beacon has been tracking activity
 */
- (void)deviceState_updateRSTime:(uint32_t)rsTime;

/**
 Device state method with single param.
 Provides you thefollowing param:
 @param rsCount A value indicating how often the beacon has been tracking activity
 */
- (void)deviceState_updateRSCount:(uint32_t)rsCount;


/**
 The iBeacon Standard informations.

 @param minor :This beacons current minor value of its iBeacon Advertisment.
 */
- (void)basicInfo_updateMinor:(uint16_t)minor;


/**
 The iBeacon Standard information

 @param major :This beacons current major value of its iBeacon Advertisment.
 */
- (void)basicInfo_updateMajor:(uint16_t)major;


/**
 The iBeacon Standard information

 @param localName :This beacons current local name value of its active scan response Advertisment.
 */
- (void)basicInfo_updateLocalName:(NSString*_Nullable)localName;


/**
 The iBeacon Standard information

 @param txPower :This beacons current TX-Power value of its iBeacon Advertisment.
 */
- (void)basicInfo_updateTXPower:(int8_t)txPower;


/**
 The iBeacon Stnadard informations

 @param uuid :This beacons current UUID value of its iBeacon Advertisment. Please
 * be aware that this is the UUID that is being broadcastet - NOT the UUID your
 iOS device shows you if scanning for peripherals. iOS devices since iOS 6+ do NOT
 provide you the real UUIDs in scan results but give you locally generated ones instead.
 */
- (void)basicInfo_updateUUID:(NSString*_Nullable)uuid;


/**
 Action info (Button Events)

 @param isOn Whether or not the button 1 is being triggered.
 */
- (void)actionInfo_button1_triggered:(BOOL)isOn;


/**
 Action info (Button Events)

 @param isOn whether or not the button 2 is being triggered.
 */
- (void)actionInfo_button2_triggered:(BOOL)isOn;


/**
 Aciont info (Button Events)

 @param isOn whether or not the button 3 is being triggered.
 */
- (void)actionInfo_button3_triggered:(BOOL)isOn;


/**
 After requesting an eeprom transfer - This method is being called
 periodically, providing you the current transfer status as percentage.

 @param percentage the current transfer state in %
 */
- (void)eeprom_transfer_receivedPercentage:(float)percentage;


/**
 After requesting an eeprom self test - This method is being called
 providing you the amount of errors it has encountered during the test as well
 as the retrieved data it has been reading after the test.

 @param errorCount : the total error count. (0x00 if everything went fine)
 @param testData : the test result read from eep. Should have value 0x01 through 0x0A - length: 10 Bytes.
 */
- (void)eeprom_selftestReceivedResultWithErrorCount:(uint8_t)errorCount
                                           TestData:(NSData*_Nonnull)testData;


/**
 After requesting an eeprom transfer - This method is being called
 providing you all Events that have been found in the eeprom.

 @param eventDictionary a collection of all valid events found in eeprom storage.
 */
- (void)eeprom_transfer_didFindEvents:(NSMutableDictionary*_Nullable)eventDictionary;


@required
//- (void)anotherRequiredMethod;

@end

