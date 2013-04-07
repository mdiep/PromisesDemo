//
//  ADNClient.m
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "ADNClient.h"

@implementation ADNClient

#pragma mark Public Methods

- (id)initWithAccessToken:(NSString *)accessToken
{
    self = [super init];
    
    if (self)
    {
        _accessToken = accessToken;
    }
    
    return self;
}

#pragma mark Users

- (ADNUser *)fetchUserWithUsername:(NSString *)username
{
    NSString *atUsername = [username hasPrefix:@"@"] ? username : [@"@" stringByAppendingString:username];
    NSArray  *result     = [self fetchURL:@"https://alpha-api.app.net/stream/0/users/search"
                           withParameters:@{ @"q": atUsername }];
    return [ADNUser userWithDictionary:result[0]];
}

- (NSImage *)fetchAvatarForUser:(ADNUser *)user
{
    NSData *data = [self _fetchURL:user.avatarURL withParameters:@{}];
    return [[NSImage alloc] initWithData:data];
}

#pragma mark Following

- (NSSet *)fetchFollowingForUser:(ADNUser *)user
{
    NSString *baseURL = @"https://alpha-api.app.net/stream/0/users/%@/following";
    NSArray  *result  = [self fetchPaginatedURL:[NSString stringWithFormat:baseURL, user.userID]
                                 withParameters:@{ }];
    
    NSMutableSet *followers = [NSMutableSet new];
    for (NSDictionary *user in result)
    {
        [followers addObject:[ADNUser userWithDictionary:user]];
    }
    
    return followers;
}

- (NSSet *)fetchFollowersForUser:(ADNUser *)user
{
    NSString *baseURL = @"https://alpha-api.app.net/stream/0/users/%@/followers";
    NSArray  *result  = [self fetchPaginatedURL:[NSString stringWithFormat:baseURL, user.userID]
                                 withParameters:@{ }];
    
    NSMutableSet *followers = [NSMutableSet new];
    for (NSDictionary *user in result)
    {
        [followers addObject:[ADNUser userWithDictionary:user]];
    }
    
    return followers;
}

#pragma mark Private Methods

- (NSData *)_fetchURL:(NSString *)url withParameters:(NSDictionary *)params
{
    NSString *query   = [self queryStringForParameters:params];
    NSURL    *fulLURL = [NSURL URLWithString:[url stringByAppendingString:query]];
    
    NSURLRequest *request   = [NSURLRequest requestWithURL:fulLURL];
    NSData       *data      = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
    
    return data;
}

- (id)fetchPaginatedURL:(NSString *)url withParameters:(NSDictionary *)params
{
    NSMutableArray *result = [NSMutableArray new];
    
    BOOL      more     = YES;
    NSString *beforeID = nil;
    while (more)
    {
        NSMutableDictionary *pParams = [params mutableCopy];
        pParams[@"count"] = @"200";
        if (beforeID) { pParams[@"before_id"] = beforeID; }
        
        NSData       *response  = [self _fetchURL:url withParameters:pParams];
        NSDictionary *json      = [NSJSONSerialization JSONObjectWithData:response options:0 error:NULL];
        
        for (NSDictionary *object in json[@"data"])
        {
            [result addObject:object];
        }
        
        more     = [json[@"meta"][@"more"] boolValue];
        beforeID = json[@"meta"][@"min_id"];
    }
    
    return result;
}

- (id)fetchURL:(NSString *)url withParameters:(NSDictionary *)params
{
    NSData       *response = [self _fetchURL:url withParameters:params];
    NSDictionary *json     = [NSJSONSerialization JSONObjectWithData:response options:0 error:NULL];
    return json[@"data"];
}

- (NSString *)queryStringForParameters:(NSDictionary *)params
{
    NSMutableString *result = [@"?" mutableCopy];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result appendFormat:@"%@=%@&", [self URLEncodeString:key], [self URLEncodeString:obj]];
    }];
    
    [result appendFormat:@"access_token=%@", self.accessToken];
    
    return result;
}

- (NSString *)URLEncodeString:(NSString *)string
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8 ));
}

@end
