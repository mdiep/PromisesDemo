//
//  ADNReactiveClient.m
//  Promises
//
//  Created by Matt Diephouse on 4/8/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "ADNReactiveClient.h"

@interface ADNReactiveClient ()
@property (strong, nonatomic, readonly) ADNClient *client;
@end

@implementation ADNReactiveClient

- (id)initWithClient:(ADNClient *)client
{
    self = [super init];
    
    if (self)
    {
        _client = client;
    }
    
    return self;
}

#pragma mark Users

- (RACSignal *)fetchUserWithUsername:(NSString *)username
{
    return [[RACSignal
        start:^(BOOL *success, NSError *__autoreleasing *error) {
            return [self.client fetchUserWithUsername:username];
        }]
        deliverOn:RACScheduler.mainThreadScheduler];
}

- (RACSignal *)fetchAvatarForUser:(ADNUser *)user
{
    return [[RACSignal
        start:^(BOOL *success, NSError *__autoreleasing *error) {
            return [self.client fetchAvatarForUser:user];
        }]
        deliverOn:RACScheduler.mainThreadScheduler];
}

#pragma mark Following

- (RACSignal *)fetchFollowingForUser:(ADNUser *)user
{
    return [[RACSignal
        start:^(BOOL *success, NSError *__autoreleasing *error) {
            return [self.client fetchFollowingForUser:user];
        }]
        deliverOn:RACScheduler.mainThreadScheduler];
}

- (RACSignal *)fetchFollowersForUser:(ADNUser *)user
{
    return [[RACSignal
        start:^(BOOL *success, NSError *__autoreleasing *error) {
            return [self.client fetchFollowersForUser:user];
        }]
        deliverOn:RACScheduler.mainThreadScheduler];
}

@end
