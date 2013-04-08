//
//  ADNPromiseClient.m
//  Promises
//
//  Created by Matt Diephouse on 4/8/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "ADNPromiseClient.h"

@interface ADNPromiseClient ()
@property (strong, nonatomic, readonly) ADNClient *client;
@end

@implementation ADNPromiseClient

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

- (Promise *)fetchUserWithUsername:(NSString *)username
{
    return [Promise of:^{
        return [self.client fetchUserWithUsername:username];
    }];
}

- (Promise *)fetchAvatarForUser:(ADNUser *)user
{
    return [Promise of:^{
        return [self.client fetchAvatarForUser:user];
    }];
}

#pragma mark Following

- (Promise *)fetchFollowingForUser:(ADNUser *)user
{
    return [Promise of:^{
        return [self.client fetchFollowingForUser:user];
    }];
}

- (Promise *)fetchFollowersForUser:(ADNUser *)user
{
    return [Promise of:^{
        return [self.client fetchFollowersForUser:user];
    }];
}

@end

