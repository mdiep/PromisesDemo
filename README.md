# PromisesDemo
A demo project that goes alongside a presentation on Promises.

The demo takes an App.net username, loads that users followers and
following, and shows the differences between those two sets of users
with avatars for each user that it displays.

## Building and running the app
You need to do a couple things to build and run the app:

1. Initialized the git submodules: `git submodule update -i --recursive`.
2. Add an environment variable, ADNACCESSTOKEN, with a ADN access token.
You can set this in the Run section of the Promises scheme.

## Implementations
The project has several different implementations of the code that loads
data from ADN:

1. A synchronous version that blocks the main thread
2. An asynchronous version written with GCD
3. An asynchronous version written with Promises
4. An asynchronous version written with a client that returns Promises
5. An asynchronous version written with a ReactiveCocoa client

To switch implementations, change which version is commented out in
`[PRMAppDelegate loadUser:]`.


