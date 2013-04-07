//
//  ADNClient.h
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADNUser.h"

@interface ADNClient : NSObject

@property (copy, nonatomic, readonly) NSString *accessToken;

- (id)initWithAccessToken:(NSString *)accessToken;

// Fetch information about a user using their username.
//
// username - Name of the user with or without the leading "@".
//
// Returns a ADNUser that represents the user.
- (ADNUser *)fetchUserWithUsername:(NSString *)username;

#pragma mark Following

// Fetch the list of users who are followed by a user.
//
// user - The user who is following.
//
// Returns a set of ADNUser objects.
- (NSSet *)fetchFollowingForUser:(ADNUser *)user;


// Fetch the list of users who follow a user.
//
// user - The user who is followed.
//
// Returns a set of ADNUser objects.
- (NSSet *)fetchFollowersForUser:(ADNUser *)user;

@end
