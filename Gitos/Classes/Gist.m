//
//  Gist.m
//  Gitos
//
//  Created by Tri Vuong on 1/27/13.
//  Copyright (c) 2013 Crafted By Tri. All rights reserved.
//

#import "Gist.h"

@implementation Gist

@synthesize data, details;

- (id)initWithData:(NSDictionary *)gistData
{
    self = [super init];

    self.data = gistData;

    return self;
}

- (NSString *)getId
{
    return [self.data valueForKey:@"id"];
}

- (NSString *)getName
{
    return [NSString stringWithFormat:@"gist:%@", [self getId]];
}

- (NSString *)getDescription
{
    if ([self.data valueForKey:@"description"] != [NSNull null]) {
        return [self.data valueForKey:@"description"];
    } else {
        return @"n/a";
    }
}

- (NSString *)getCreatedAt
{
    return [self.data valueForKey:@"created_at"];
}

- (NSInteger)getNumberOfFiles
{
    NSArray *files = [self.data valueForKey:@"files"];
    return [files count];
}

- (NSInteger)getNumberOfForks
{
    NSArray *forks = [self.details valueForKey:@"forks"];
    return [forks count];
}

- (NSInteger)getNumberOfComments
{
    return [[self.details valueForKey:@"comments"] integerValue];
}

@end
