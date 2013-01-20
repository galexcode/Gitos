//
//  Branch.m
//  Gitos
//
//  Created by Tri Vuong on 1/20/13.
//  Copyright (c) 2013 Crafted By Tri. All rights reserved.
//

#import "Branch.h"
#import "AppConfig.h"

@implementation Branch

@synthesize name;

- (id)initWithData:(NSDictionary *)data
{
    self = [super init];

    self.name = [data valueForKey:@"name"];

    return self;
}

- (NSString *)getUrl
{
    return @"";
}

@end
