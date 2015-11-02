//
//  AFUIAnalytics.h
//  Pods
//
//  Created by Борис on 02.11.15.
//
//

#import <Foundation/Foundation.h>

@interface AFUIAnalytics : NSObject

// Request for analytics
+ (void)sessionRequestForAction;

// For testing
//+ (void)testingAnalytics;

@end
