//
//  GCTestsSamples.m
//  GarminConnect
//
//  Created by Brice Rosenzweig on 01/02/2014.
//  Copyright (c) 2014 Brice Rosenzweig. All rights reserved.
//

#import "GCTestsSamples.h"
@implementation GCTestsSamples


// {1.2,1.3,2.1}
// {3.2,2.1,3.2,2.3,2.9,3.0,2.1,1.5,5.2,4.2,3.7}
// {0.2}
+(NSDictionary*)aggregateSample{
    // CutOff November 13 (last):
    //    Nov -> Cnt 1, Sum 0.2
    //    Oct -> Cnt 2, Sum 3.2+2.1=5.3
    //    Sep -> Cnt 1, Sum 1.2
    NSDictionary * sample = @{
                              @"2012-09-13T18:48:16.000Z":@(1.2), //thu
                              @"2012-09-14T19:10:16.000Z":@(1.3), //fri
                              @"2012-09-21T18:10:01.000Z":@(2.1), //fri
                              @"2012-10-10T15:00:01.000Z":@(3.2), //wed
                              @"2012-10-11T15:00:01.000Z":@(2.1), //thu
                              @"2012-10-21T15:00:01.000Z":@(3.2), //sun
                              @"2012-10-22T15:00:01.000Z":@(2.3), //mon
                              @"2012-10-23T15:00:01.000Z":@(2.9), //tue
                              @"2012-10-24T15:00:01.000Z":@(3.0), //wed
                              @"2012-10-25T15:00:01.000Z":@(2.1), //thu
                              @"2012-10-26T15:00:01.000Z":@(1.5), //fri
                              @"2012-10-27T15:00:01.000Z":@(5.2), //sat
                              @"2012-10-28T15:00:01.000Z":@(4.2), //sun
                              @"2012-10-29T15:00:01.000Z":@(3.7), //mon
                              @"2012-11-13T16:01:02.000Z":@(0.2), //tue
                              };
    return sample;
}
+(NSDictionary*)aggregateExpected{
    NSDictionary * expected = @{
                                @"2012-09-09T18:48:16.000Z":@[  @(1.25),        @(2.5),     @(1.3) ],
                                @"2012-09-16T18:48:16.000Z":@[  @(2.1),         @(2.1),     @(2.1) ],
                                @"2012-10-07T15:00:01.000Z":@[  @(2.65),        @(5.3),     @(3.2) ],
                                @"2012-10-21T15:00:01.000Z":@[  @(2.885714286), @(20.2),    @(5.2) ],
                                @"2012-10-28T18:48:16.000Z":@[  @(3.95),        @(7.9),     @(4.2) ],
                                @"2012-11-11T18:48:16.000Z":@[  @(0.2),         @(0.2),     @(0.2) ]
                                };
    return expected;
}


+(GCActivity*)sampleCycling{
    GCActivity * rv = [[[GCActivity alloc] init] autorelease];
    rv.activityType = GC_TYPE_CYCLING;
    rv.activityId = @"100";
    rv.activityName = @"Untitled";
    rv.activityTypeDetail = [GCActivityType activityTypeForKey:GC_TYPE_CYCLING];
    rv.trackFlags = gcFieldFlagWeightedMeanSpeed|gcFieldFlagWeightedMeanHeartRate;
    rv.flags = gcFieldFlagWeightedMeanHeartRate|gcFieldFlagWeightedMeanSpeed;

    rv.date = [NSDate dateForRFC3339DateTimeString:@"2012-11-11T18:48:16.000Z"];
    rv.location = @"London, GC";
    
    /*
    double speedKph = 15.;
    double durationSecond = 60.;
    double distanceKph = speedKph*durationSecond/3600.;
    double heartRateBpm = 130.;
    NSArray * metaDataInfo = @[ @[@"eventType", @"Uncategorized", @"uncategorized"], @[@"device", @"Garmin Edge 510", @"edge510"]];
    NSArray * summaryDataInfo = @[@[@"WeightedMeanSpeed",@"kph",@(speedKph)],
                                  @[@"SumDistance", @"kilometer", @(distanceKph)],
                                  @[@"WeightedMeanHeartRate", @"bpm", @(heartRateBpm)]
                                  
                                  ];
    */
    return rv;
}



@end
