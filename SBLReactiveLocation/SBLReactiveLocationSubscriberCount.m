//
//  SBLReactiveLocationSubscriberCount.m
//  SBLReactiveLocation
//
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#import "SBLReactiveLocationSubscriberCount.h"

@interface SBLReactiveLocationSubscriberCount() {
  NSMutableDictionary *_dict;
}

@end

@implementation SBLReactiveLocationSubscriberCount

- (instancetype)init
{
  self = [super init];
  if (self == nil) return nil;
  
  _dict = [NSMutableDictionary dictionary];
  
  return self;
}

- (NSUInteger)incrementForKey:(id <NSCopying>)key
{
  NSUInteger count = 1;
  @synchronized(self) {
    if ([_dict objectForKey:key] == nil || [[_dict objectForKey:key] unsignedIntegerValue] == 0) {
      [_dict setObject:@(count) forKey:key];
    } else {
      count = [[_dict objectForKey:key] unsignedIntegerValue];
      count++;
      [_dict setObject:@(count) forKey:key];
    }
  }
  return count;
}

- (NSUInteger)decrementForKey:(id<NSCopying>)key
{
  NSAssert([_dict objectForKey:key] != nil, @"trying to decrement a non exisiting subscriber");
  NSUInteger count;
  @synchronized(self) {
    count = [[_dict objectForKey:key] unsignedIntegerValue];
    count--;
    [_dict setObject:@(count) forKey:key];
  }
  return count;
}

@end
