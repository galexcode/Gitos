//
//  TimelineEvent.h
//  Gitos
//
//  Created by Tri Vuong on 1/12/13.
//  Copyright (c) 2013 Crafted By Tri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RelativeDateDescriptor.h"

@interface TimelineEvent : NSObject

@property(nonatomic) NSInteger eventId;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *createdAt;
@property(nonatomic, strong) NSDictionary *actor;
@property(nonatomic, strong) NSDictionary *payload;
@property(nonatomic, strong) NSDictionary *repo;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;
@property(nonatomic, strong) NSDate *todayDate;
@property(nonatomic, strong) RelativeDateDescriptor *relativeDateDescriptor;

- (id)initWithOptions:(NSDictionary *)options;
- (NSString *)toString;
- (NSString *)toDateString;

@end
