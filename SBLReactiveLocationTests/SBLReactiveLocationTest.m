//
//  SBLReactiveLocationTest.m
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#define EXP_SHORTHAND
#import <Specta.h>
#import <Expecta.h>
#import <ReactiveCocoa.h>
#import <OCMock.h>


@import CoreLocation;

#import "SBLReactiveLocation.h"

// expose implementation details for easier testing
@interface SBLReactiveLocation(Testing) <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *manager;

@end

////////////////////////////////////////////////////

CLBeaconRegion* CreateRegion() {
  NSUUID *uuid = [NSUUID UUID];
  CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                              identifier:[uuid UUIDString]];
  return region;
}

////////////////////////////////////////////////////

SpecBegin(SBLReactiveLocationTest)

describe(@"SBLReactiveLocation", ^{
  __block id mockManager;
  __block SBLReactiveLocation *loc;

  // always mock the manager
  beforeEach(^{
    loc =[[SBLReactiveLocation alloc] init];
    
    mockManager = [OCMockObject mockForClass:CLLocationManager.class];
    [[[mockManager stub] andReturn:loc] delegate];
    
    loc.manager = mockManager;
  });
  
  context(@"- authorizationStatus", ^{
    it(@"updates the status", ^{
      __block CLAuthorizationStatus status;
      [loc.authorizationStatus subscribeNext:^(NSNumber *_status) {
        status = [_status intValue];
      }];
      
      [loc locationManager:nil didChangeAuthorizationStatus:kCLAuthorizationStatusDenied];
      expect(status).to.equal(kCLAuthorizationStatusDenied);
      [loc locationManager:nil didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorized];
      expect(status).to.equal(kCLAuthorizationStatusAuthorized);
    });
  });
  
  context(@"- updateHeading", ^{
    it(@"sends the heading information", ^{
      [[mockManager expect] startUpdatingHeading];
      
      __block CLHeadingComponentValue x,y,z;
      [[loc updateHeading] subscribeNext:^(CLHeading *heading) {
        x = heading.x;
        y = heading.y;
        z = heading.z;
      }];
      
      id heading = [OCMockObject mockForClass:(CLHeading.class)];
      [[[heading stub] andReturnValue:@(0.1)] x];
      [[[heading stub] andReturnValue:@(0.2)] y];
      [[[heading stub] andReturnValue:@(0.3)] z];
      
      [loc locationManager:nil didUpdateHeading:heading];
      
      expect(x).to.equal(0.1);
      expect(y).to.equal(0.2);
      expect(z).to.equal(0.3);
      
      [mockManager verify];
    });
    
    it(@"starts update only for the first subscriber", ^{
      [[mockManager stub] heading];
      [[mockManager expect] startUpdatingHeading];
      
      [[loc updateHeading] subscribeNext:^(id _){}];
      [mockManager verify];
      
      [[mockManager reject] startUpdatingHeading];
      [[loc updateHeading] subscribeNext:^(id _){}];
      [mockManager verify];
    });
    
    it(@"stops heading updates when there is no more subscriber", ^{
      [[mockManager expect] startUpdatingHeading];
      [[mockManager expect] stopUpdatingHeading];
      
      RACDisposable *disposable = [[loc updateHeading] subscribeNext:^(id _){}];
      [disposable dispose];
      
      [mockManager verify];
    });
    
    it(@"handles errors", ^{
      [[mockManager expect] startUpdatingHeading];
      [[mockManager expect] stopUpdatingHeading];
      
      __block NSInteger errorCode;
      [[loc updateHeading] subscribeNext:^(id x) {
        NSAssert(false, @"should not be success");
      } error:^(NSError *error) {
        errorCode = error.code;
      }];
      
      NSError *err = [NSError errorWithDomain:@"spec" code:kCLErrorHeadingFailure userInfo:nil];
      [loc locationManager:nil didFailWithError:err];
      expect(errorCode).to.equal(kCLErrorHeadingFailure);
    });
  });
  
  context(@"- rangeBeaconsInRegion:", ^{
    __block CLBeaconRegion *region;
    beforeEach(^{
      NSUUID *uuid = [NSUUID UUID];
      region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"region-identifier-ranging"];
    });
    
    it(@"returns an NSArray signal of beacons", ^{
      [[mockManager expect] startRangingBeaconsInRegion:region];
      
      __block NSArray *beacons;
      [[loc rangeBeaconsInRegion:region] subscribeNext:^(id x) {
        beacons = x;
      }];
      
      id beacon = [OCMockObject mockForClass:CLBeacon.class];
      [loc locationManager:nil didRangeBeacons:@[beacon, beacon] inRegion:region];
      expect(beacons.count).to.equal(2);
      expect(beacons[0]).to.beKindOf(CLBeacon.class);
      [mockManager verify];
    });
    
    it(@"starts ranging only for newly registered regions", ^{
      [[mockManager expect] startRangingBeaconsInRegion:region];
      [[loc rangeBeaconsInRegion:region] subscribeNext:^(id _){}];
      [[mockManager reject] startRangingBeaconsInRegion:region];

      [[loc rangeBeaconsInRegion:region] subscribeNext:^(id _){}];
      [mockManager verify];
    });
    
    it(@"stops ranging on last subscriber", ^{
      [[mockManager expect] startRangingBeaconsInRegion:region];
      RACDisposable *d1 = [[loc rangeBeaconsInRegion:region] subscribeNext:^(id _){}];
      RACDisposable *d2 = [[loc rangeBeaconsInRegion:region] subscribeNext:^(id _){}];

      [d1 dispose];
      [[mockManager expect] stopRangingBeaconsInRegion:region];
      [d2 dispose];
      
      [mockManager verify];
    });
    
    it(@"delivers ranging errors", ^{
      [[mockManager expect] startRangingBeaconsInRegion:region];
      [[mockManager expect] stopRangingBeaconsInRegion:region];
      
      __block NSInteger errorCode;
      [[loc rangeBeaconsInRegion:region] subscribeError:^(NSError *error) {
        errorCode = error.code;
      }];
      
      [loc locationManager:nil rangingBeaconsDidFailForRegion:region
                 withError:[NSError errorWithDomain:@"spec" code:kCLErrorRangingFailure userInfo:nil]];
      
      expect(errorCode).to.equal(kCLErrorRangingFailure);
      [mockManager verify];
    });
    
  });

  context(@"monitoring", ^{
    sharedExamplesFor(@"a hygienic signal", ^(NSDictionary *data) {
      __block RACSignal *signal;
      __block CLBeaconRegion *region;
      
      beforeEach(^{
        signal = data[@"signal"];
        region = data[@"region"];
      });
      
      it(@"only starts monitoring for new regions", ^{
        [[mockManager stub] requestStateForRegion:region];
        [[mockManager expect] startMonitoringForRegion:region];
        [signal subscribeNext:^(id _){}];
        [[mockManager reject] startMonitoringForRegion:region];
        [signal subscribeNext:^(id _){}];
        [mockManager verify];
      });
      
      it(@"stops monitoring on last subscriber", ^{
        [[mockManager stub] requestStateForRegion:region];
        [[mockManager expect] startMonitoringForRegion:region];
        RACDisposable *d1 = [signal subscribeNext:^(id _){}];
        RACDisposable *d2 = [signal subscribeNext:^(id _){}];
        
        [d1 dispose];
        [[mockManager expect] stopMonitoringForRegion:region];
        [d2 dispose];
        
        [mockManager verify];
      });
      
      it(@"delivers monitoring errors", ^{
        [[mockManager stub] requestStateForRegion:region];
        [[mockManager expect] startMonitoringForRegion:region];
        [[mockManager expect] stopMonitoringForRegion:region];
        
        __block NSInteger errorCode;
        [signal subscribeError:^(NSError *error) {
          errorCode = error.code;
        }];
        
        [loc locationManager:nil monitoringDidFailForRegion:region
                   withError:[NSError errorWithDomain:@"spec" code:kCLErrorRegionMonitoringFailure userInfo:nil]];
        
        expect(errorCode).to.equal(kCLErrorRegionMonitoringFailure);
        [mockManager verify];
      });
    });
    
    context(@"- determineStateForRegion:", ^{
      it(@"monitors state", ^{
        CLBeaconRegion *region = CreateRegion();
        [[mockManager expect] startMonitoringForRegion:region];
        [[mockManager expect] requestStateForRegion:region];
        
        __block int state;
        [[loc determineStateForRegion:region] subscribeNext:^(NSNumber *st) {
          state = st.intValue;
        }];
        
        [loc locationManager:nil didDetermineState:CLRegionStateInside forRegion:region];
        expect(state).to.equal(CLRegionStateInside);
        [loc locationManager:nil didDetermineState:CLRegionStateOutside forRegion:region];
        expect(state).to.equal(CLRegionStateOutside);
        
        [mockManager verify];
      });
      
      itShouldBehaveLike(@"a hygienic signal", ^{
        CLBeaconRegion *region = CreateRegion();
        return @{
                 @"signal": [loc determineStateForRegion:region],
                 @"region": region,
                 };
      });
    });
    
    context(@"- monitorEnterRegion:", ^{
      it(@"sends the entered region", ^{
        CLBeaconRegion *region = CreateRegion();
        [[mockManager expect] startMonitoringForRegion:region];
        
        [[mockManager expect] startMonitoringForRegion:region];
        [[mockManager expect] requestStateForRegion:region];
        
        __block CLBeaconRegion *foundRegion;
        
        [[loc monitorEnterRegion:region] subscribeNext:^(id x) {
          foundRegion = x;
        }];
        
        [loc locationManager:nil didEnterRegion:region];
        expect(foundRegion).to.equal(region);
      });
      
      itShouldBehaveLike(@"a hygienic signal", ^{
        CLBeaconRegion *region = CreateRegion();
        return @{
                 @"signal": [loc monitorEnterRegion:region],
                 @"region": region,
                 };
      });
    });
    
    context(@"- monitorExitRegion:", ^{
      it(@"sends the exited region", ^{
        CLBeaconRegion *region = CreateRegion();
        [[mockManager expect] startMonitoringForRegion:region];
        
        [[mockManager expect] startMonitoringForRegion:region];
        [[mockManager expect] requestStateForRegion:region];
        
        __block CLBeaconRegion *foundRegion;
        
        [[loc monitorExitRegion:region] subscribeNext:^(id x) {
          foundRegion = x;
        }];
        
        [loc locationManager:nil didExitRegion:region];
        expect(foundRegion).to.equal(region);
      });
      
      itShouldBehaveLike(@"a hygienic signal", ^{
        CLBeaconRegion *region = CreateRegion();
        return @{
                 @"signal": [loc monitorExitRegion:region],
                 @"region": region,
                 };
      });
    });
  });

  
});

SpecEnd