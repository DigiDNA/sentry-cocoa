//
//  SentryContext.m
//  Sentry
//
//  Created by Daniel Griesser on 18/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryContext.h>
#import <Sentry/SentryDefines.h>

#else
#import "SentryContext.h"
#import "SentryDefines.h"
#endif

#if __has_include(<KSCrash/KSCrash.h>)
#import <KSCrash/KSCrash.h>
#elif __has_include("KSCrash.h")
#import "KSCrash.h"
#endif

#if SENTRY_HAS_UIKIT
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryContext

- (instancetype)init {
    return [super init];
}

+ (instancetype)new {
    return [super new];
}

- (NSDictionary<NSString *, id> *)serialize {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];

    if (nil == self.osContext) {
        self.osContext = [self generatedOsContext];
    }
    [serializedData setValue:self.osContext forKey:@"os"];

    if (nil == self.appContext) {
        self.appContext = [self generatedAppContext];
    }
    [serializedData setValue:self.appContext forKey:@"app"];

    if (nil == self.deviceContext) {
        self.deviceContext = [self generatedDeviceContext];
    }
    [serializedData setValue:self.deviceContext forKey:@"device"];

    return serializedData;
}

- (NSDictionary<NSString *, id> *)generatedOsContext {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];

#if TARGET_OS_IPHONE
    [serializedData setValue:@"iOS" forKey:@"name"];
#elif TARGET_OS_OSX
    [serializedData setValue:@"macOS" forKey:@"name"];
#elif TARGET_OS_TV
    [serializedData setValue:@"tvOS" forKey:@"name"];
#elif TARGET_OS_WATCH
    [serializedData setValue:@"watchOS" forKey:@"name"];
#endif

#if SENTRY_HAS_UIDEVICE
    [serializedData setValue:[UIDevice currentDevice].systemVersion forKey:@"version"];
#else
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    NSString *systemVersion = [NSString stringWithFormat:@"%d.%d.%d", (int) version.majorVersion, (int) version.minorVersion, (int) version.patchVersion];
    [serializedData setValue:systemVersion forKey:@"version"];
#endif

#if WITH_KSCRASH
    NSDictionary *systemInfo = [self systemInfo];
    [serializedData setValue:systemInfo[@"osVersion"] forKey:@"build"];
    [serializedData setValue:systemInfo[@"kernelVersion"] forKey:@"kernel_version"];
    [serializedData setValue:systemInfo[@"isJailbroken"] forKey:@"rooted"];
#endif
    return serializedData;
}

- (NSDictionary<NSString *, id> *)generatedDeviceContext {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];

#if TARGET_OS_SIMULATOR
    [serializedData setValue:@(YES) forKey:@"simulator"];
#endif

#if WITH_KSCRASH
    NSDictionary *systemInfo = [self systemInfo];
    [serializedData setValue:[[systemInfo[@"systemName"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject] forKey:@"family"];
    [serializedData setValue:systemInfo[@"cpuArchitecture"] forKey:@"arch"];
    [serializedData setValue:systemInfo[@"machine"] forKey:@"model"];
    [serializedData setValue:systemInfo[@"model"] forKey:@"model_id"];
    [serializedData setValue:systemInfo[@"freeMemory"] forKey:@"free_memory"];
    [serializedData setValue:systemInfo[@"usableMemory"] forKey:@"usable_memory"];
    [serializedData setValue:systemInfo[@"memorySize"] forKey:@"memory_size"];
    [serializedData setValue:systemInfo[@"storageSize"] forKey:@"storage_size"];
    [serializedData setValue:systemInfo[@"bootTime"] forKey:@"boot_time"];
    [serializedData setValue:systemInfo[@"timezone"] forKey:@"timezone"];
#endif

    return serializedData;
}

- (NSDictionary<NSString *, id> *)generatedAppContext {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];

    [serializedData setValue:infoDict[@"CFBundleIdentifier"] forKey:@"app_identifier"];
    [serializedData setValue:infoDict[@"CFBundleName"] forKey:@"app_name"];
    [serializedData setValue:infoDict[@"CFBundleVersion"] forKey:@"app_build"];
    [serializedData setValue:infoDict[@"CFBundleShortVersionString"] forKey:@"app_version"];

#if WITH_KSCRASH
    NSDictionary *systemInfo = [self systemInfo];
    [serializedData setValue:systemInfo[@"appStartTime"] forKey:@"app_start_time"];
    [serializedData setValue:systemInfo[@"deviceAppHash"] forKey:@"device_app_hash"];
    [serializedData setValue:systemInfo[@"appID"] forKey:@"app_id"];
    [serializedData setValue:systemInfo[@"buildType"] forKey:@"build_type"];
#endif

    return serializedData;
}

#if WITH_KSCRASH
- (NSDictionary *)systemInfo {
    static NSDictionary *sharedInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInfo = KSCrash.sharedInstance.systemInfo;
    });
    return sharedInfo;
}
#endif

@end

NS_ASSUME_NONNULL_END
