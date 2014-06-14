# SBLReactiveLocation

[![Platform](http://img.shields.io/cocoapods/p/SBLReactiveLocation.svg?style=flat)](http://cocoadocs.org/docsets/SBLReactiveLocation)
[![Version](http://img.shields.io/cocoapods/v/SBLReactiveLocation.svg?style=flat)](http://cocoadocs.org/docsets/SBLReactiveLocation)
[![License](http://img.shields.io/cocoapods/l/SBLReactiveLocation.svg?style=flat)](http://cocoadocs.org/docsets/SBLReactiveLocation)

A ReactiveCocoa based wrapper around the `CLLocationManager` of CoreLocation. The implementation tries to
stay as close as possible to the original `CLLocationManager` implementation
while exposing the updates that are traditionally handled by a
`CLLocationManagerDelegate` as `RACSignals`.

## Features

See `SBLReactiveLocation.h` file for the complete API.

- supports heading updates
- supports iBeacon reaging
- supports region monitoring

## Install

	platform :ios, "7.0"
	pod "SBLReactiveLocation"

## Usage

e.g. for heading

	SBLReactiveLocation *loc = [[SBLReactiveLocation alloc] init];
	[[loc updateHeading] subscribeNext:^(CLHeading *heading) {
		// the works
	}];

## Todo

- CLLocation updates

## Contact

- the issue tracker
- [@bruitism](http://twitter.com/bruitism)

## License

MIT, see LICENSE

