// Derived from rpetrich/Powercuff, revision a97c445a4a8fd2ce1cfe9fbc16fdf82a930b62d1.
// Original author: Ryan Petrich. See SOURCES.md for provenance.
#import <Foundation/Foundation.h>
#import <notify.h>
#import <objc/runtime.h>

@interface CommonProduct : NSObject
- (void)putDeviceInThermalSimulationMode:(NSString *)mode;
@end

static NSString *const PreferencesDomain = @"com.rpetrich.powercuff";
static const char *const ThermalNotification = "com.rpetrich.powercuff.thermals";
static CommonProduct *currentProduct; // Non-owning; cleared by the dealloc hook.
static int thermalToken = NOTIFY_TOKEN_INVALID;

static NSString *StringForMode(uint64_t mode) {
    switch (mode) {
        case 1: return @"nominal";
        case 2: return @"light";
        case 3: return @"moderate";
        case 4: return @"heavy";
        default: return @"off";
    }
}

static void ApplyThermals(void) {
    uint64_t mode = 0;
    if (thermalToken == NOTIFY_TOKEN_INVALID ||
        notify_get_state(thermalToken, &mode) != NOTIFY_STATUS_OK) return;
    if ([currentProduct respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) {
        [currentProduct putDeviceInThermalSimulationMode:StringForMode(mode)];
    }
}

// Only SpringBoard publishes settings; thermalmonitord only consumes them.
static void LoadSettings(void) {
    CFStringRef domain = (CFStringRef)PreferencesDomain;
    CFPreferencesAppSynchronize(domain);
    uint64_t mode = 0;
    CFPropertyListRef value = CFPreferencesCopyValue(
        CFSTR("PowerMode"), domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (value) {
        if ([(id)value isKindOfClass:[NSNumber class]]) {
            NSInteger candidate = [(NSNumber *)value integerValue];
            if (candidate >= 0 && candidate <= 4) mode = (uint64_t)candidate;
        }
        CFRelease(value);
    }
    value = CFPreferencesCopyValue(CFSTR("RequireLowPowerMode"), domain,
        kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (value) {
        if ([(id)value isKindOfClass:[NSNumber class]] && [(NSNumber *)value boolValue] &&
            ![[NSProcessInfo processInfo] isLowPowerModeEnabled]) mode = 0;
        CFRelease(value);
    }
    if (notify_set_state(thermalToken, mode) == NOTIFY_STATUS_OK) {
        notify_post(ThermalNotification);
    }
}

static void SettingsChanged(CFNotificationCenterRef center, void *observer,
                            CFStringRef name, const void *object, CFDictionaryRef info) {
    (void)center; (void)observer; (void)name; (void)object; (void)info;
    dispatch_async(dispatch_get_main_queue(), ^{ LoadSettings(); });
}

%group ThermalDaemon
%hook CommonProduct
- (id)initProduct:(id)data {
    self = %orig(data);
    if ([self respondsToSelector:@selector(putDeviceInThermalSimulationMode:)]) {
        currentProduct = self;
        ApplyThermals();
    }
    return self;
}
- (void)dealloc {
    if (currentProduct == self) currentProduct = nil;
    %orig;
}
%end
%end

%ctor {
    @autoreleasepool {
        NSString *process = [[NSProcessInfo processInfo] processName];
        if ([process isEqualToString:@"thermalmonitord"]) {
            uint32_t status = notify_register_dispatch(ThermalNotification, &thermalToken,
                dispatch_get_main_queue(), ^(int token) { (void)token; ApplyThermals(); });
            if (status != NOTIFY_STATUS_OK) return;
            Class productClass = NSClassFromString(@"CommonProduct");
            if (productClass && class_getInstanceMethod(productClass, @selector(initProduct:)) &&
                class_getInstanceMethod(productClass, @selector(putDeviceInThermalSimulationMode:))) {
                %init(ThermalDaemon);
            } else {
                NSLog(@"[Powercuff] Thermal API unavailable; no thermal hooks installed.");
            }
        } else if ([process isEqualToString:@"SpringBoard"]) {
            if (notify_register_check(ThermalNotification, &thermalToken) != NOTIFY_STATUS_OK) return;
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                SettingsChanged, CFSTR("com.rpetrich.powercuff.settingschanged"), NULL,
                CFNotificationSuspensionBehaviorCoalesce);
            [[NSNotificationCenter defaultCenter]
                addObserverForName:NSProcessInfoPowerStateDidChangeNotification
                object:nil queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) { (void)note; LoadSettings(); }];
            LoadSettings();
        }
    }
}
