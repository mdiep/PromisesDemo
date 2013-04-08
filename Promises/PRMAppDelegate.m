//
//  PRMAppDelegate.m
//  Promises
//
//  Created by Matt Diephouse on 4/2/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import "PRMAppDelegate.h"

#import "ADNClient.h"
#import "ADNPromiseClient.h"
#import "Promise.h"

@interface PRMAppDelegate () <NSTableViewDelegate>
@property (strong, nonatomic) IBOutlet NSTableView *doNotFollowYouTable;
@property (strong, nonatomic) IBOutlet NSTableView *youDoNotFollowTable;

@property (strong, nonatomic) IBOutlet NSTextField *usernameField;

@property (strong, nonatomic) NSArray *doNotFollowYou;
@property (strong, nonatomic) NSArray *youDoNotFollow;

@property (strong, nonatomic) ADNClient *client;
@property (strong, nonatomic) NSMutableDictionary *avatars;
@end

@implementation PRMAppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *token = NSProcessInfo.processInfo.environment[@"ADNACCESSTOKEN"];
    self.client  = [[ADNClient alloc] initWithAccessToken:token];
    self.avatars = [NSMutableDictionary new];
}

#pragma mark NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    NSArray *users = tableView == self.doNotFollowYouTable ? self.doNotFollowYou : self.youDoNotFollow;
    ADNUser *user  = users[row];
    view.imageView.objectValue = self.avatars[user.username];
    view.textField.stringValue = user.username;
    
    return view;
}

#pragma mark Actions

- (IBAction)loadUser:(id)sender
{
    self.doNotFollowYou = @[ ];
    self.youDoNotFollow = @[ ];
    [self.avatars removeAllObjects];
    
    //[self loadUserSynchronously];
    //[self loadUserWithGCD];
    //[self loadUserWithPromises];
    [self loadUserWithPromisesClient];
}

#pragma mark Private Methods

- (NSSet *)objectsInSet:(NSSet *)set1 notInSet:(NSSet *)set2
{
    NSMutableSet *result = [set1 mutableCopy];
    [result minusSet:set2];
    return result;
}

- (void)updateWithAvatar:(NSImage *)avatar forUser:(ADNUser *)user
{
    self.avatars[user.username] = avatar;
    
    NSTableView *tableView = [self.doNotFollowYou containsObject:user] ? self.doNotFollowYouTable : self.youDoNotFollowTable;
    [tableView reloadData];
}

// Returns the users that are displayed
- (NSSet *)updateWithFollowers:(NSSet *)followers following:(NSSet *)following
{
    NSSet *doNotFollowYou = [self objectsInSet:following notInSet:followers];
    NSSet *youDoNotFollow = [self objectsInSet:followers notInSet:following];
    
    NSArray *descriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES] ];
    self.doNotFollowYou = [doNotFollowYou.allObjects sortedArrayUsingDescriptors:descriptors];
    self.youDoNotFollow = [youDoNotFollow.allObjects sortedArrayUsingDescriptors:descriptors];
    
    return [doNotFollowYou setByAddingObjectsFromSet:youDoNotFollow];
}

#pragma mark Concurrency

- (void)loadUserSynchronously
{
    ADNUser *user = [self.client fetchUserWithUsername:self.usernameField.stringValue];
    
    NSSet *followers = [self.client fetchFollowersForUser:user];
    NSSet *following = [self.client fetchFollowingForUser:user];
    
    NSSet *displayedUsers = [self updateWithFollowers:followers following:following];
    
    for (ADNUser *u in displayedUsers)
    {
        NSImage *avatar = [self.client fetchAvatarForUser:u];
        [self updateWithAvatar:avatar forUser:u];
    }
}

- (void)loadUserWithGCD
{
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue    = dispatch_get_main_queue();
    
    dispatch_async(defaultQueue, ^{
        ADNUser *user = [self.client fetchUserWithUsername:self.usernameField.stringValue];
        
        __block NSSet *followers = nil;
        __block NSSet *following = nil;
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, defaultQueue, ^{
            followers = [self.client fetchFollowersForUser:user];
        });
        dispatch_group_async(group, defaultQueue, ^{
            following = [self.client fetchFollowingForUser:user];
        });
        
        dispatch_group_notify(group, mainQueue, ^{
            NSSet *displayedUsers = [self updateWithFollowers:followers following:following];
            
            dispatch_semaphore_t limitSemaphore = dispatch_semaphore_create(3);
            
            for (ADNUser *u in displayedUsers)
            {
                dispatch_async(defaultQueue, ^{
                    dispatch_semaphore_wait(limitSemaphore, DISPATCH_TIME_FOREVER);
                    
                    NSImage *avatar = [self.client fetchAvatarForUser:u];
                    dispatch_async(mainQueue, ^{
                        dispatch_semaphore_signal(limitSemaphore);
                        
                        [self updateWithAvatar:avatar forUser:u];
                    });
                });
            }
        });
    });
}

- (void)loadUserWithPromises
{
    Promise *fetchUser = [Promise of:^{ return [self.client fetchUserWithUsername:self.usernameField.stringValue]; }];
    
    [[Promise
        when:@[
            [fetchUser thenPromise:^(id user) { return [self.client fetchFollowersForUser:user]; }],
            [fetchUser thenPromise:^(id user) { return [self.client fetchFollowingForUser:user]; }],
        ]]
        finally:^(id result, NSError *error) {
            NSSet *displayedUsers = [self updateWithFollowers:result[0] following:result[1]];
            
            [Promise map:displayedUsers.allObjects
                   limit:3
               withBlock:^(id object) {
                   ADNUser *user = object;
                   return [[Promise
                            of:^{ return [self.client fetchAvatarForUser:user]; }]
                            finally:^(id result, NSError *error) {
                                [self updateWithAvatar:result forUser:user];
                           }];
               }];
        }];
}

- (void)loadUserWithPromisesClient
{
    ADNPromiseClient *client = [[ADNPromiseClient alloc] initWithClient:self.client];
    
    Promise *fetchUser = [client fetchUserWithUsername:self.usernameField.stringValue];
    
    [[Promise
        when:@[
            [fetchUser then:^(id user) { return [self.client fetchFollowersForUser:user]; }],
            [fetchUser then:^(id user) { return [self.client fetchFollowingForUser:user]; }],
        ]]
        finally:^(id result, NSError *error) {
            NSSet *displayedUsers = [self updateWithFollowers:result[0] following:result[1]];
         
            [Promise map:displayedUsers.allObjects
                   limit:3
               withBlock:^(id object) {
                   ADNUser *user = object;
                   return [[client fetchAvatarForUser:user]
                           finally:^(id result, NSError *error) {
                               [self updateWithAvatar:result forUser:user];
                           }];
               }];
        }];
}

@end
