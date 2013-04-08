//
//  Promise.h
//  Promises
//
//  Created by Matt Diephouse on 4/6/13.
//  Copyright (c) 2013 Matt Diephouse. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Promise : NSObject

@property (assign, nonatomic, readonly, getter=isResolved) BOOL resolved;
@property (assign, nonatomic, readonly, getter=isRejected) BOOL rejected;

#pragma mark Creation

// Return a new Promise that executes multiple promises in parallel.
//
// promises - An array of Promises to be fulfilled in parallel.
//
// Returns a Promise that is fulfilled when all of the promises are fulfilled.
+ (instancetype)when:(NSArray *)promises;

// Return a promise that executes a block for each input but limits concurrency.
//
// inputs - The objects that are used as inputs to the block.
// limit  - The number of concurrent operations that are allowed at a time.
// block  - A block that returns a promise from an input object.
//
// Returns a new promise that is fulfilled when all the promises returned from the block have
// completed.
+ (instancetype)map:(NSArray *)inputs
              limit:(NSUInteger)limit
          withBlock:(Promise *(^)(id object))block;

// Execute a synchronous block asynchronously.
//
// Returns a new promise that is fulfilled when the block finishes.
+ (instancetype)of:(id (^)())block;

// Return a promise of a value that is immediately fulfilled.
+ (instancetype)value:(id)object;

// Return a promise that immediately errors out.
+ (instancetype)error:(NSError *)error;

#pragma mark Handlers

// Execute a block with the result of the promise and return a new Promise.
//
// block - A block that is executed with the result of the promise and returns a new value.
//
// Returns a Promise from the result of the block. If that result is a promise, it is returned
// directly. Otherwise, the result is wrapped in a promise.
- (instancetype)then:(id (^)(id result))block;

// Shortcut for then:^(id result){ return [Promise of:^{ block(result) ]; }
//
// block - A synchronous block that takes the result of the promise.
//
// Returns a new promise that is fulfilled after the block is executed synchronously.
- (instancetype)thenPromise:(id (^)(id result))block;

// Execute a block with the result or error of the promise.
//
// block - A block that takes the result and the error of the promise.
//
// Returns self.
- (instancetype)finally:(void (^)(id result, NSError *error))block;

@end
