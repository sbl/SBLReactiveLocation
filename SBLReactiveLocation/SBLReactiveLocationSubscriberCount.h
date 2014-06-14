//
//  SBLReactiveLocationSubscriberCount.h
//  SBLReactiveLocation
//
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#import <Foundation/Foundation.h>

// thread safe data structure to keep track of subscriptions.
@interface SBLReactiveLocationSubscriberCount : NSObject

// `incrementForKey` automatically creates a subscriber named `key` with a count of 1 if there is no such subscriber. Otherwise increment.
- (NSUInteger)incrementForKey:(id <NSCopying>)key;
- (NSUInteger)decrementForKey:(id <NSCopying>)key;

@end
