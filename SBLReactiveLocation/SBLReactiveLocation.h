//
//  SBLReactiveLocation.h
//  SBLReactiveLocation
//
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

@class RACSignal;

/**
  A reactive wrapper around the `CLLocationManager`. The implementation tries to stay as close as possible to the original `CLLocationManager` implementation while exposing the updates that are traditionally handled by a `CLLocationManagerDelegate` as `RACSignal`s.
 */
@interface SBLReactiveLocation : NSObject

/**
 Returns a signal that contains the application’s authorization status for using location services.

 @return A `RACSignal` of `CLAuthorizationStatus` events.
 */
@property (readonly, nonatomic) RACSignal *authorizationStatus;

/**
 The minimum angular change (measured in degrees) required to generate new heading events.
 
 Delegates to the underlying CLLocationManager object.
 */
@property(assign, nonatomic) CLLocationDegrees headingFilter;

/*
 The device orientation to use when computing heading values.
 
 Delegates to the underlying CLLocationManager object.
 */
@property(assign, nonatomic) CLDeviceOrientation headingOrientation;

/**
 Returns a signal that automatically starts updating heading information on first subscription.
 
 @return A `RACSignal` that streams the current `CLHeading` information.
 */
- (RACSignal *)updateHeading;

/**
 Returns a signal that automatically ranges for nearby beacons on first subscription.

 @param region The region to range.
 @return A `RACSignal` that contains an `NSArray` of nearby `CLBeacons` in region.
 */
- (RACSignal *)rangeBeaconsInRegion:(CLBeaconRegion *)region;

/**
 The largest boundary distance that can be assigned to a region.
 
 Delegates to the underlying CLLocationManager object.
*/
@property(readonly, nonatomic) CLLocationDistance maximumRegionMonitoringDistance;

/**
 Returns a signal signal with the current region state changes.
 
 @param region The region to monitor
 @return A `RACSignal` of `CLRegionState`.
 */
- (RACSignal *)determineStateForRegion:(CLRegion *)region;

/**
 Sends next when entering a specified region.
 
 @param region The region to monitor
 @return A `RACSignal` with the monitored region.
 */
- (RACSignal *)monitorEnterRegion:(CLRegion *)region;

/**
 Sends exit when exiting a specified region.
 
 @param region The region to monitor
 @return A `RACSignal` with the monitored region.
 */
- (RACSignal *)monitorExitRegion:(CLRegion *)region;

@end
