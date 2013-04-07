//
//  ADNUser.m
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "ADNUser.h"

@implementation ADNUser

#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%@)>",
            NSStringFromClass([self class]), self, self.username];
}

- (NSUInteger)hash
{
    return [self.userID hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ADNUser class]])
    {
        ADNUser *user = object;
        return [self.userID isEqual:user.userID];
    }
    else
    {
        return [super isEqual:object];
    }
}

#pragma mark Public Methods

+ (id)userWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if (self)
    {
        _userID     = dictionary[@"id"];
        _username   = dictionary[@"username"];
        _name       = dictionary[@"name"];
    }
    
    return self;
}

@end
