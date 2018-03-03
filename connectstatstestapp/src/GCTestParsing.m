//  MIT Licence
//
//  Created on 22/03/2014.
//
//  Copyright (c) 2014 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "GCTestParsing.h"
#import "GCActivity+Import.h"
#import "GCStravaActivityListParser.h"
#import "GCStravaActivityStreamsParser.h"
#import "GCSportTracksActivityDetailParser.h"
#import "GCSportTracksActivityListParser.h"
#import "GCStravaActivityLapsParser.h"
#import "GCFitBitActivitiesParser.h"
#import "GCFitBitActivityTypesParser.h"
#import "GCActivity+Database.h"
#import "GCGarminRequestActivityReload.h"
#import "GCGarminActivityTrack13Request.h"


@implementation GCTestParsing

-(NSArray*)testDefinitions{
    return @[@{TK_SEL: NSStringFromSelector(@selector(sportTracksParsing)),
               TK_DESC:@"Test parsing of sporttracks",
               TK_SESS:@"GC Parsing SportTracks"},
             @{TK_SEL:NSStringFromSelector(@selector(garminExtraFieldsTests)),
               TK_DESC:@"Test parsing of garmin track with extra fields",
               TK_SESS:@"GC Parsing Extra Fields"},

             /*@{TK_SEL:NSStringFromSelector(@selector(fitbitParsing)),
               TK_DESC:@"Test parsing of FitBit files",
               TK_SESS: @"GC FitBit Parsing"},*/
             ];
}

/*
-(void)runTests{

    [self sportTracksParsing];
    [self stravaParsing];
}
*/


-(void)garminExtraFieldsTests{
    [self startSession:@"GC Parsing Extra Fields"];
    NSString * aId = @"1008868846";
    NSString * fpath = [RZFileOrganizer bundleFilePath:@""];

    GCActivity * act = [GCGarminRequestActivityReload testForActivity:aId withFilesIn:fpath];

    [GCGarminActivityTrack13Request testForActivity:act withFilesIn:fpath];

    NSArray * available = [act availableTrackFields];


    NSArray * expected = @[ @"WeightedMeanPace",
                            @"GainElevation",
                            @"WeightedMeanRunCadence",
                            @"WeightedMeanHeartRate",
                            @"WeightedMeanGroundContactTime",
                            @"WeightedMeanVerticalOscillation",
                            @"WeightedMeanAirTemperature",
                            @"WeightedMeanVerticalRatio",
                            @"WeightedMeanGroundContactBalanceLeft",
                            ];

    for (NSString * expect in expected) {
        NSInteger found = [available indexOfObject:[GCField field:expect forActivityType:act.activityType]];
        RZ_ASSERT(found != NSNotFound, @"%@ available in %@", expect, act);
    }
    NSUInteger count = 0;

    BOOL started = false;
    for (GCField * field in available) {
        GCStatsDataSerieWithUnit * serie = [act timeSerieForField:field];
        if (started) {
            RZ_ASSERT(serie.count > 0, @"%@ has points", field);
        }else{
            count = serie.count;
            started = true;
            RZ_ASSERT(count > 0, @"%@ has points", field);
        }
    }

    RZ_ASSERT(started, @"Found some fields");

    FMDatabase * db = [FMDatabase databaseWithPath:[RZFileOrganizer writeableFilePath:@"fullsave_1008868846.db"]];
    [db open];
    [act fullSaveToDb:db];
    
    /*
     GCActivity * act2 = [GCActivity activityWithId:aId andDb:db];
    if (started) {
        GCStatsDataSerieWithUnit * serie = [act timeSerieForField:[GCField field:CALC_VERTICAL_SPEED forActivityType:act.activityType]];
        RZ_ASSERT(serie.count==count, @"%@ found in %@", CALC_VERTICAL_SPEED, act );
    }*/

    [self endSession:@"GC Parsing Extra Fields"];
}

-(void)fitbitParsing{
    [self startSession:@"GC Parsing FitBit"];

    //NSData * types = [NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:@"fitbit_activity_types.json"]];
    //GCFitBitActivityTypesParser * tparser = [ GCFitBitActivityTypesParser activityTypesParser:types];
#ifdef GC_USE_HEALTHKIT
    NSData * actfile = [NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:@"fitbit_list.json"]];
    GCFitBitActivitiesParser * lparser = [GCFitBitActivitiesParser activitiesParser:actfile forDate:[NSDate date]];

    GCActivity * act = lparser.activity;
    NSString * fn =[RZFileOrganizer writeableFilePath:@"test_fitbit_act.db"];
    FMDatabase * db = [FMDatabase databaseWithPath:fn];
    [db open];
    [GCActivity ensureDbStructure:db];
    [act setDb:db];
    [act saveToDb:db];
    [act setDb:nil];
    [db close];
#endif
    [self endSession:@"GC Parsing FitBit"];
}

-(void)sportTracksParsing{
    [self startSession:@"GC Parsing SportTracks"];
    GCSportTracksActivityListParser * parser = [GCSportTracksActivityListParser activityListParser:[NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:@"sporttracks_list_0.json"]]];
    [self assessTestResult:@"SportTracks List Parsed" result:parser.parsedCount == 25];
    NSError * e = nil;
    NSData  * input = [NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:@"sporttracks_track_5556610.json"]];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:input options:NSJSONReadingMutableContainers error:&e];
    GCActivity * act = [[GCActivity alloc] initWithId:@"5556610" andSportTracksData:json];
    GCSportTracksActivityDetailParser * detailParser = [GCSportTracksActivityDetailParser activityDetailParser:json forActivity:act];
    RZLog(RZLogInfo,@"Parsed points %d", (int)detailParser.points.count);
    [self endSession:@"GC Parsing SportTracks"];
}

@end
