//
//  SBLReactiveLocation.m
//  SBLReactiveLocation
//
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#import "SBLReactiveLocation.h"
#import "SBLReactiveLocationSubscriberCount.h"
#import <ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <libkern/OSAtomic.h>

@interface SBLReactiveLocation() <CLLocationManagerDelegate> {
  int32_t _headingSubscriberCount;
  SBLReactiveLocationSubscriberCount *_rangingSubscribers;
  SBLReactiveLocationSubscriberCount *_monitoringSubscribers;
}

@property (strong, nonatomic) CLLocationManager *manager;

@end

@implementation SBLReactiveLocation

- (id)init
{
  self = [super init];
  if (self == nil) return nil;
  
  _headingSubscriberCount = 0;
  _monitoringSubscribers = [[SBLReactiveLocationSubscriberCount alloc] init];
  _rangingSubscribers = [[SBLReactiveLocationSubscriberCount alloc] init];
  
  return self;
}

// lazy load the underlying locationManager
- (CLLocationManager *)manager
{
  if (_manager == nil) {
    _manager = [[CLLocationManager alloc] init];
    _manager.delegate = self;
  }
  return _manager;
}

#pragma mark - authorization

- (RACSignal *)authorizationStatus
{
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *status = [[self rac_signalForSelector:@selector(locationManager:didChangeAuthorizationStatus:)
                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                         reduceEach:^id(id _, id statusNumber){
                           return statusNumber;
                         }];
    return [status subscribe:subscriber];
  }] setNameWithFormat:@"<%@:%p -authorizationStatus >", self.class, self];
}

#pragma mark - heading

- (CLLocationDegrees)headingFilter
{
  return self.manager.headingFilter;
}

- (void)setHeadingFilter:(CLLocationDegrees)headingFilter
{
  self.manager.headingFilter = headingFilter;
}

- (CLDeviceOrientation)headingOrientation
{
  return self.manager.headingOrientation;
}

- (void)setHeadingOrientation:(CLDeviceOrientation)headingOrientation
{
  self.manager.headingOrientation = headingOrientation;
}

- (RACSignal *)updateHeading
{
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *heading = [[self rac_signalForSelector:@selector(locationManager:didUpdateHeading:)
                                                      fromProtocol:@protocol(CLLocationManagerDelegate)]
                          reduceEach:^id(id _, CLHeading *heading){
                            return heading;
                          }];
    
    RACDisposable *disposable = [[RACSignal merge:@[heading, [self locationErrorSignal]]] subscribe:subscriber];
    
    @strongify(self);
    if (OSAtomicIncrement32(&_headingSubscriberCount) == 1) {
      [self.manager startUpdatingHeading];
    } else {
      [subscriber sendNext:self.manager.heading];
    }
    
    return [RACDisposable disposableWithBlock:^{
      [disposable dispose];
      if (OSAtomicDecrement32(&_headingSubscriberCount) == 0) {
        [self.manager stopUpdatingHeading];
      }
    }];
  }] setNameWithFormat:@"<%@:%p -updateHeading>", self.class, self];
}


- (RACSignal *)locationErrorSignal
{
  return [[[[self rac_signalForSelector:@selector(locationManager:didFailWithError:)
                           fromProtocol:@protocol(CLLocationManagerDelegate)]
            reduceEach:^id(id _, NSError *error){
              return error;
            }]
           filter:^BOOL(NSError *error) {
             return error.code != kCLErrorLocationUnknown;
           }]
          flattenMap:^RACStream *(NSError *error) {
            return [RACSignal error:error];
          }];
}

#pragma mark - beacon ranging

- (RACSignal *)rangeBeaconsInRegion:(CLBeaconRegion *)region
{
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *beacons = [[self rac_signalForSelector:@selector(locationManager:didRangeBeacons:inRegion:)
                                        fromProtocol:@protocol(CLLocationManagerDelegate)]
                          reduceEach:^id(id _, NSArray *beacons, id _region){
                            return beacons;
                          }];
    
    RACSignal *error = [[[[self rac_signalForSelector:@selector(locationManager:rangingBeaconsDidFailForRegion:withError:)
                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                        reduceEach:^id(id _, CLBeaconRegion *_region, NSError *error){
                          return error;
                        }]
                        filter:^BOOL(NSError *error) {
                          return error.code != kCLErrorLocationUnknown;
                        }]
                        flattenMap:^RACStream *(NSError *error) {
                          return [RACSignal error:error];
                        }];
    
    
    RACDisposable *disposable = [[RACSignal merge:@[beacons, error]] subscribe:subscriber];
    
    @strongify(self);
    if ([_rangingSubscribers incrementForKey:region] == 1) {
      [self.manager startRangingBeaconsInRegion:region];
    }
    
    return [RACDisposable disposableWithBlock:^{
      [disposable dispose];
      if ([_rangingSubscribers decrementForKey:region] == 0) {
        [self.manager stopRangingBeaconsInRegion:region];
      }
    }];
  }] setNameWithFormat:@"<%@:%p : - rangeBeaconsInRegion: %@", self.class, self, region];
}

#pragma mark - monitoring

- (CLLocationDistance)maximumRegionMonitoringDistance
{
  return self.manager.maximumRegionMonitoringDistance;
}

- (RACSignal *)determineStateForRegion:(CLRegion *)region
{
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *state = [[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:)
                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                        reduceEach:^id(id _, id state, id _region){
                          return state;
                        }];
    @strongify(self);
    return [self monitoringDisposableForSignal:state subscriber:subscriber region:region];
  }] setNameWithFormat:@"<%@:%p : - determineStateForRegion: %@", self.class, self, region];
}

- (RACSignal *)monitorEnterRegion:(CLRegion *)region
{
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *enter = [[self rac_signalForSelector:@selector(locationManager:didEnterRegion:)
                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                        reduceEach:^id(id _, CLRegion *reg){
                          return reg;
                        }];
    
    @strongify(self);
    return [self monitoringDisposableForSignal:enter subscriber:subscriber region:region];
  }] setNameWithFormat:@"<%@:%p : - monitorEnterRegion: %@", self.class, self, region];
}

- (RACSignal *)monitorExitRegion:(CLRegion *)region
{
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACSignal *exit = [[self rac_signalForSelector:@selector(locationManager:didExitRegion:)
                                       fromProtocol:@protocol(CLLocationManagerDelegate)]
                        reduceEach:^id(id _, CLRegion *reg){
                          return reg;
                        }];
    
    @strongify(self);
    return [self monitoringDisposableForSignal:exit subscriber:subscriber region:region];
  }] setNameWithFormat:@"<%@:%p : - monitorExitRegion: %@", self.class, self, region];
}

- (RACDisposable *)monitoringDisposableForSignal:(RACSignal *)signal subscriber:(id <RACSubscriber>)subscriber region:(CLRegion *)region
{
  RACDisposable *disposable = [[RACSignal merge:@[signal, [self monitoringErrorSignal]]] subscribe:subscriber];
  
  if ([_monitoringSubscribers incrementForKey:region] == 1) {
    [self.manager startMonitoringForRegion:region];
    [self.manager requestStateForRegion:region];
  }
  return [RACDisposable disposableWithBlock:^{
    [disposable dispose];
    if ([_monitoringSubscribers decrementForKey:region] == 0) {
      [self.manager stopMonitoringForRegion:region];
    }
  }];
}

- (RACSignal *)monitoringErrorSignal
{
  return [[[[self rac_signalForSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)
                           fromProtocol:@protocol(CLLocationManagerDelegate)]
            reduceEach:^id(id _, id _region, NSError *error){
              return error;
            }]
           filter:^BOOL(NSError *error) {
             return error.code != kCLErrorLocationUnknown;
           }]
          flattenMap:^RACStream *(NSError *error) {
            return [RACSignal error:error];
          }];
}

@end
