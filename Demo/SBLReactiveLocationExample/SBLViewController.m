//
//  SBLViewController.m
//  SBLReactiveLocationExample
//
//  Created by sbl on 14.06.2014.
//  Copyright (c) 2014 Stephen Lumenta. All rights reserved.
//

#import "SBLViewController.h"

#import <ReactiveCocoa.h>
#import <SBLReactiveLocation.h>

@interface SBLViewController ()

@property (weak, nonatomic) IBOutlet UILabel *headingLabel;

@end

@implementation SBLViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  SBLReactiveLocation *loc = [[SBLReactiveLocation alloc] init];
  RAC(self.headingLabel, text) = [[loc updateHeading] map:^id(CLHeading *heading) {
    return [NSString stringWithFormat:@"%f :: %f :: %f", heading.x, heading.y, heading.z];
  }];
}

@end
