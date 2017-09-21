//
//  INatAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "ExploreObservation.h"
#import "INatAPI.h"
#import "NSLocale+INaturalist.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

@implementation INatAPI

- (NSString *)apiBaseUrl {
    return @"https://api.inaturalist.org/v1";
}

- (void)fetch:(NSString *)path classMapping:(Class)classMapping handler:(INatAPIFetchCompletionCountHandler)done {
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if ([login jwtToken]) {
        [request addValue:[login jwtToken]
       forHTTPHeaderField:@"Authorization"];
    }

    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    } else {
                        [self extractObjectsFromData:data
                                        classMapping:classMapping
                                             handler:done];
                    }
                }] resume];
    }
}

// extract objects from server response data
- (void)extractObjectsFromData:(NSData *)data classMapping:(Class)ClassForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            done(nil, 0, error);
        });
    } else {
        NSMutableArray *results = [NSMutableArray array];
        NSInteger totalResults = [[json valueForKey:@"total_results"] integerValue];
        
        for (NSDictionary *resultJSON in [json valueForKey:@"results"]) {
            NSError *error;
            MTLModel *result = [MTLJSONAdapter modelOfClass:ClassForMapping
                                         fromJSONDictionary:resultJSON
                                                      error:&error];
            
            if (result) {
                [results addObject:result];
            } else {
                // skip this one
                NSLog(@"MANTLE ERROR: %@", error);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            done([NSArray arrayWithArray:results], totalResults, nil);
        });
    }
}

@end
