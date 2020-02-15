//  MIT Licence
//
//  Created on 23/12/2013.
//
//  Copyright (c) 2013 Brice Rosenzweig.
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

#import "GCActivity+CachedTracks.h"
#import "GCFields.h"
#import "GCAppGlobal.h"
#import "GCActivity+Fields.h"

@interface GCCalculactedCachedTrackInfo : NSObject

@property (nonatomic,assign) gcCalculatedCachedTrack track;
@property (nonatomic,retain) GCField * field;
@property (nonatomic,retain) GCStatsDataSerieWithUnit * serie;
@property (nonatomic,retain) NSArray * trackpoints;

+(GCCalculactedCachedTrackInfo*)info:(gcCalculatedCachedTrack)track field:(GCField*)field;
-(gcFieldFlag)fieldFlag;
@end

@implementation GCCalculactedCachedTrackInfo

/**

 */
+(GCCalculactedCachedTrackInfo*)info:(gcCalculatedCachedTrack)atrack field:(GCField*)afield{
    GCCalculactedCachedTrackInfo * rv = [[[GCCalculactedCachedTrackInfo alloc] init] autorelease];
    if (rv) {
        rv.track = atrack;
        rv.field = afield;
        rv.serie = nil;
    }
    return rv;
}

-(gcFieldFlag)fieldFlag{
    return _field.fieldFlag;
}

-(void)dealloc{
    [_serie release];
    [_field release];
    [_trackpoints release];

    [super dealloc];
}




@end

#define MAX_FILL_POINTS 28800
#define X_FOR(p) (timeAxis ? p.elapsed : p.distanceMeters)

@implementation GCActivity (CachedTracks)


-(nonnull NSArray<GCTrackPoint*>*)resample:(nonnull NSArray<GCTrackPoint*>*)points forUnit:(double)unit useTimeAxis:(BOOL)timeAxis{

    GCTrackPoint * first_p = points[0];
    size_t last_i   = 0;
    double first_x  =  X_FOR(first_p);

    BOOL inconsistentPoint=false;

    NSUInteger n = points.count;

    double accrued = 0.;

    GCTrackPoint * currentPoint = [[GCTrackPoint alloc] init];

    NSMutableArray * rv = [NSMutableArray arrayWithCapacity:n];
    [rv addObject:currentPoint];

    for (NSUInteger idx_p = 1;idx_p <= n;idx_p++) {
        GCTrackPoint * from_p = points[idx_p-1];
        GCTrackPoint * to_p   = idx_p < n ? points[idx_p] : nil;

        //double elapsed  = [to_p.time timeIntervalSinceDate:from_p.time];
        //double distance = to_p.validCoordinate && from_p.validCoordinate ? [to_p distanceMetersFrom:from_p] : to_p.distanceMeters-from_p.distanceMeters;

        double from_x  = X_FOR(from_p)-first_x;
        double to_x    = to_p ? X_FOR(to_p)-first_x : from_x;

        NSUInteger from_i = MIN(from_x/unit,MAX_FILL_POINTS-1);
        NSUInteger to_i   = MIN(to_x/unit,MAX_FILL_POINTS-1);

        if (from_i!=last_i) {
            inconsistentPoint = true;
        }

        //last_i = to_i;

        if (to_p == nil) {
            // last point allocated to last
            [currentPoint add:from_p withAccrued:(unit-accrued)/unit timeAxis:timeAxis];
            // values[from_i] += from_p.y_data * (unit - accrued)/unit;
        }else if ( to_i==from_i) {
            // didn't cross to next point yet, weighted allocation to current i
            //      f     t
            // I: --|aa---|---
            // P: ----X-X-----
            //        f t
            [currentPoint add:from_p withAccrued:(to_x-from_x)/unit timeAxis:timeAxis];
            // values[from_i] += from_p.y_data * (to_x-from_x)/unit;
            accrued += (to_x-from_x);
        }else{
            // got to next
            //
            //    f     t
            // I: |aaa--|-----|-----|-----|
            // P:  --X-----X----------
            //       f     t
            //
            //    f     s     s     t
            // I: |aaa--|-----|-----|-----|
            // P:  --X----------------X---
            //       f                t

            for (size_t step_i = from_i; step_i<to_i; step_i++) {
                size_t next_i = step_i+1;
                double next_x = unit*next_i;

                double step_x = step_i == from_i ? from_x : unit*step_i;

                double weight =(next_x-step_x)/unit;
                // fill steps to far from last with zero (else with last value)
                // could impose limit: fill w zero when more than L since last
                /* if (step_i!=from_i && fill == gcStatsZero) {
                 step_v = 0.;
                 }*/

                [currentPoint add:from_p withAccrued:weight timeAxis:timeAxis];
                last_i = step_i;

                if (next_i < MAX_FILL_POINTS && next_i == to_i) {
                    [currentPoint release];
                    currentPoint = [[GCTrackPoint alloc] init];
                    [rv addObject:currentPoint];
                    [currentPoint add:from_p withAccrued:(to_x-next_x)/unit timeAxis:timeAxis];
                    last_i = to_i;
                    accrued = (to_x-next_x);
                }
            }
        }
    }
    [currentPoint release];
    if (inconsistentPoint) {
        RZLog(RZLogError, @"Logic Error: Inconsistent x");
    }

    return rv;
}

-(NSString*)calculatedCachedTrackKey:(gcCalculatedCachedTrack)track forField:(GCField*)field{
    if (track == gcCalculatedCachedTrackDataSerie) {
        return field.key;
    }else{
        NSString * prefix = @"__RollingBest";
        if (track==gcCalculatedCachedTrackDistanceResample) {
            prefix = @"__DistanceResample";
        }
        return [NSString stringWithFormat:@"%@%@", prefix, field.key];
    }
}

-(void)calculatedCachedTrackCalculations{
    NSMutableDictionary * rv = [NSMutableDictionary dictionaryWithCapacity:(self.cachedCalculatedTracks).count];
    RZPerformance * perf = [RZPerformance start];
    NSUInteger i = 0;
    NSUInteger pts = 0;
    GCCalculactedCachedTrackInfo * info = nil;
    for (NSString * key in self.cachedCalculatedTracks) {
        id obj = (self.cachedCalculatedTracks)[key];
        if ([obj isKindOfClass:[GCCalculactedCachedTrackInfo class]]) {
            info = obj;

            if (info.track==gcCalculatedCachedTrackRollingBest) {
                BOOL timeAxis = info.fieldFlag != gcFieldFlagWeightedMeanSpeed;
                BOOL useElapsed = false;
                if( info.fieldFlag == gcFieldFlagWeightedMeanSpeed){

                    if( useElapsed ){
                        GCField * elapsedfield = [GCField fieldForFlag:gcFieldFlagSumDuration andActivityType:self.activityType];
                        GCStatsDataSerieWithUnit * serie = [self distanceSerieForField:elapsedfield];
                        if( serie.serie.count > 0 && serie.serie.firstObject.x_data > 0 ){
                            [serie.serie addDataPointWithX:0.0 andY:0.0];
                            [serie.serie sortByX];
                        }
                        [[serie.serie asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"distance.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        GCStatsDataSerie * diffSerie = [serie.serie differenceSerieForLag:0.0];
                        [[diffSerie asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"distance_diff.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];

                        pts += diffSerie.count;
                        gcStatsSelection select = gcStatsMin;
                        GCStatsDataSerie * filled = [diffSerie filledSerieForUnit:10. fillMethod:gcStatsZero statistic:gcStatsSum];
                        [[filled asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"distance_filled.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];

                        double //unitstride = [GCAppGlobal configGetDouble:CONFIG_CRITICAL_CALC_UNIT defaultValue:5.];
                        unitstride = 10;
                        serie.serie = [diffSerie movingBestByUnitOf:unitstride fillMethod:gcStatsZero select:select statistic:gcStatsSum];
                        for (GCStatsDataPoint * point in serie.serie) {
                            if( point.y_data > 0.){
                                point.y_data = point.x_data/point.y_data; // convert in mps
                            }
                        }
                        serie.unit = [GCUnit mps];
                        [serie convertToUnit:[GCUnit minperkm]];
                        if( serie.serie.count > 1 && [serie.serie dataPointAtIndex:0].x_data == 0){
                            [serie.serie dataPointAtIndex:0].y_data = [serie.serie dataPointAtIndex:1].y_data;
                        }

                        rv[key] = serie;
                    }else{
                        
                        GCField * distancefield = [GCField fieldForFlag:gcFieldFlagSumDistance andActivityType:self.activityType];
                        GCStatsDataSerieWithUnit * serie = [self timeSerieForField:distancefield];
                        if( serie.serie.count > 0 && serie.serie.firstObject.x_data > 0 ){
                            [serie.serie addDataPointWithX:0.0 andY:0.0];
                            [serie.serie sortByX];
                        }
                        [[serie.serie asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"time.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];

                        GCStatsDataSerie * diffSerie = [serie.serie differenceSerieForLag:0.0];
                        [[serie.serie asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"time_diff.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        pts += diffSerie.count;
                        gcStatsSelection select = gcStatsMax;
                        
                        GCStatsDataSerie * filled = [diffSerie filledSerieForUnit:10. fillMethod:gcStatsZero statistic:gcStatsSum];
                        [[filled asCSVString:false] writeToFile:[RZFileOrganizer writeableFilePath:@"time_filled.csv"]
                                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];


                        double //unitstride = [GCAppGlobal configGetDouble:CONFIG_CRITICAL_CALC_UNIT defaultValue:5.];
                        unitstride = 10;
                        serie.serie = [diffSerie movingBestByUnitOf:unitstride fillMethod:gcStatsZero select:select statistic:gcStatsSum];
                        [serie convertToUnit:[GCUnit meter]];
                        for (GCStatsDataPoint * point in serie.serie) {
                            if( point.x_data > 0.){
                                point.y_data /= point.x_data; // convert in mps
                            }
                        }
                        serie.unit = [GCUnit mps];
                        [serie convertToUnit:[GCUnit minperkm]];
                        if( serie.serie.count > 1 && [serie.serie dataPointAtIndex:0].x_data == 0){
                            [serie.serie dataPointAtIndex:0].y_data = [serie.serie dataPointAtIndex:1].y_data;
                        }
                        rv[key] = serie;
                    }
                }else{
                    
                    GCStatsDataSerieWithUnit * serie = timeAxis?[self timeSerieForField:info.field]:[self distanceSerieForField:info.field];
                    pts += serie.serie.count;
                    gcStatsSelection select = gcStatsMax;
                    if (info.fieldFlag == gcFieldFlagWeightedMeanSpeed && [serie.unit isKindOfClass:[GCUnitInverseLinear class]]) {
                        select = gcStatsMin;
                    }
                    
                    double unitstride = [GCAppGlobal configGetDouble:CONFIG_CRITICAL_CALC_UNIT defaultValue:5.];
                    if (info.fieldFlag == gcFieldFlagWeightedMeanSpeed) {
                        unitstride = 10.;
                    }
                    
                    // HACK serie that are missing zero, as otherwise the best of may not start consistently
                    // and doing max over multiple will have weird quirks at the beginning.
                    if( serie.serie.count > 0 && serie.serie.firstObject.x_data > 0 ){
                        [serie.serie addDataPointWithX:0.0 andY:serie.serie.firstObject.y_data];
                        [serie.serie sortByX];
                    }
                    
                    serie.serie = [serie.serie movingBestByUnitOf:unitstride fillMethod:gcStatsZero select:select statistic:gcStatsWeightedMean];
                    rv[key] = serie;
                }
            }else if(info.track == gcCalculatedCachedTrackDataSerie){
                if ([info.field.key isEqualToString:CALC_VERTICAL_SPEED]) {
                    NSDictionary * standard = [self calculateAltitudeDerivedFields];
                    if (standard) {
                        [rv addEntriesFromDictionary:standard];
                    }
                }
                if ([info.field.key isEqualToString:CALC_10SEC_SPEED]) {
                    NSDictionary * standard = [self calculateSpeedDerivedFields];
                    if (standard) {
                        [rv addEntriesFromDictionary:standard];
                    }
                }
            }

            i++;
        }else{
            rv[key] = obj;
        }
    }
    self.cachedCalculatedTracks = rv;
    if ([perf significant]) {
        RZLog(RZLogInfo, @"Computed %d tracks (%d pts) %@",(int)i, (int)pts, perf);
    }
    [self performSelectorOnMainThread:@selector(calculateCachedTrackNotify) withObject:nil waitUntilDone:NO];
}

-(void)calculateCachedTrackNotify{
    [[GCAppGlobal organizer] notifyForString:self.activityId];
    [self notify];
}


-(BOOL)hasCalculatedDerivedTrack:(gcCalculatedCachedTrack)track forField:(nonnull GCField*)field{
    return (self.cachedCalculatedTracks)[[self calculatedCachedTrackKey:track forField:field]]!=nil;
}

-(void)addStandardCalculatedTracks:(nullable dispatch_queue_t)threadOrNil{
    if ([self isCalculatingTracks]) {
        return;
    }

    NSMutableDictionary * rv = [NSMutableDictionary dictionaryWithDictionary:self.cachedCalculatedTracks];
    NSString * key = nil;

    BOOL hasMissing = false;

    if (RZTestOption(self.trackFlags, gcFieldFlagAltitudeMeters)) {
        GCField * field = [GCField field:CALC_VERTICAL_SPEED forActivityType:self.activityType];
        key = [self calculatedCachedTrackKey:gcCalculatedCachedTrackDataSerie forField:field];
        if (rv[key] == nil) {
            GCCalculactedCachedTrackInfo * info = [GCCalculactedCachedTrackInfo info:gcCalculatedCachedTrackDataSerie field:field];
            rv[key] = info;
            hasMissing = true;
        }
    }
    if (RZTestOption(self.trackFlags, gcFieldFlagSumDistance)) {
        GCField * field = [GCField fieldForKey:CALC_10SEC_SPEED andActivityType:self.activityType];
        key = [self calculatedCachedTrackKey:gcCalculatedCachedTrackDataSerie forField:field];
        if (rv[key] == nil) {
            GCCalculactedCachedTrackInfo * info = [GCCalculactedCachedTrackInfo info:gcCalculatedCachedTrackDataSerie field:field];
            rv[key] = info;
            hasMissing = true;
        }
    }
    if (hasMissing) {
        self.cachedCalculatedTracks = rv;
    }

    if (threadOrNil) {
        dispatch_async(threadOrNil,^(){
            [self calculatedCachedTrackCalculations];
        });
    }else{
        [self calculatedCachedTrackCalculations];
    }
}

-(BOOL)isCalculatingTracks{
    BOOL calculating = false;
    if (self.cachedCalculatedTracks) {
        for (NSString * key in self.cachedCalculatedTracks) {
            if ([(self.cachedCalculatedTracks)[key] isKindOfClass:[GCCalculactedCachedTrackInfo class]]) {
                calculating = true;
            }
        }
    }
    return calculating;
}

+(nullable GCStatsDataSerieWithUnit*)standardSerieSampleForXUnit:(GCUnit*)xUnit{
    
    if( [xUnit canConvertTo:GCUnit.second] ){
        GCStatsDataSerieWithUnit * rv = nil;
        
        double xs[] = {
            5., 10., 15., 30., 45., 60.,
            2.*60., 5.*60., 10.*60., 15.*60., 20.*60., 25.0*60.,
            30.*60., 35.*60., 40.*60., 45.*60., 50.0*60., 55.0*60.,
            60.*60, 90.*60., 2*60.*60., 5*60.*60. };

        size_t n = sizeof(xs)/sizeof(double);
        rv = [GCStatsDataSerieWithUnit dataSerieWithUnit:xUnit xUnit:xUnit andSerie:RZReturnAutorelease([[GCStatsDataSerie alloc] init])];
        for (size_t i=0; i<n; ++i) {
            [rv.serie addDataPointWithX:xs[i] andY:xs[i]];
        }
        return rv;
    }else if( [xUnit canConvertTo:GCUnit.meter] ){
        GCStatsDataSerieWithUnit * rv = nil;
        
        double mile = 1609.344;
        double km = 1000.0;
        double marathon = 42.195;
        
        double small_xs[] = { 100., 200., 400., 500., 800., 1500. };
        double big_xs[]   = { 1., 2., 3., 5., 10., 15., 20., 30., 40., 50., 100. };
        double std_xs[]   = { marathon/2.*km, marathon*km };

        size_t small_n = sizeof(small_xs)/sizeof(double);
        size_t big_n = sizeof(big_xs)/sizeof(double);
        size_t std_n = sizeof(std_xs)/sizeof(double);

        rv = [GCStatsDataSerieWithUnit dataSerieWithUnit:xUnit xUnit:xUnit andSerie:RZReturnAutorelease([[GCStatsDataSerie alloc] init])];
        for (size_t i=0; i<small_n; ++i) {
            [rv.serie addDataPointWithX:small_xs[i] andY:small_xs[i]];
        }
        for (size_t i=0; i<big_n; ++i) {
            [rv.serie addDataPointWithX:big_xs[i]*km andY:big_xs[i]*km];
            [rv.serie addDataPointWithX:big_xs[i]*mile andY:big_xs[i]*mile];
        }
        for (size_t i=0; i<std_n; ++i) {
            [rv.serie addDataPointWithX:std_xs[i] andY:std_xs[i]];
        }
        [rv.serie sortByX];

        return rv;
    }else{
        return nil;
    }
}

-(nullable GCStatsDataSerieWithUnit*)standardizedBestRollingTrack:(nonnull GCField*)field
                                                           thread:(nullable dispatch_queue_t)thread{
    
    GCStatsDataSerieWithUnit * base = [self calculatedDerivedTrack:gcCalculatedCachedTrackRollingBest forField:field thread:thread];
    if( base ){
        GCStatsDataSerieWithUnit * standardSerie = [GCActivity standardSerieSampleForXUnit:base.xUnit];
        // If standard serie exist, then resample, if not, it means the xUnit likely does not have standard serie
        if( standardSerie ){
            // Make sure we reduce from a copy so we don't destroy the main serie
            base = [GCStatsDataSerieWithUnit dataSerieWithOther:base];
            [GCStatsDataSerie reduceToCommonRange:standardSerie.serie and:base.serie];
            
        }else{
            base = nil;
        }
    }
    return base;
}

-(nullable GCStatsDataSerieWithUnit*)calculatedDerivedTrack:(gcCalculatedCachedTrack)track
                                                   forField:(nonnull GCField*)field
                                                     thread:(nullable dispatch_queue_t)thread{
    if (![self trackpointsReadyOrLoad]) {//don't bother if no trackpoints
        return nil;
    }
    if (!self.cachedCalculatedTracks) {
        self.cachedCalculatedTracks = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    GCStatsDataSerieWithUnit * rv = nil;
    NSString * key = [self calculatedCachedTrackKey:track forField:field];
    id exiting = (self.cachedCalculatedTracks)[key];
    if (exiting == nil && ![self isCalculatingTracks])  {
        // start calculation

        NSMutableDictionary * next = [NSMutableDictionary dictionaryWithDictionary:self.cachedCalculatedTracks];
        next[key] = [GCCalculactedCachedTrackInfo info:track field:field];
        self.cachedCalculatedTracks = next;
        if (thread) {
            dispatch_async(thread,^(){
                [self calculatedCachedTrackCalculations];
            });

        }else{
            [self calculatedCachedTrackCalculations];
            exiting = (self.cachedCalculatedTracks)[key];
        }
    }

    if (exiting && [exiting isKindOfClass:[GCStatsDataSerieWithUnit class]]){
        rv = (GCStatsDataSerieWithUnit*) exiting;
        if (track == gcCalculatedCachedTrackDataSerie && self.settings.serieFilters[field]) {
            rv = [GCStatsDataSerieWithUnit dataSerieWithUnit:rv.unit xUnit:rv.xUnit andSerie:rv.serie];
            rv = [self applyStandardFilterTo:rv ForField:field];
        }
    }

    return rv;
}

#pragma mark - Derived TRacks

-(NSDictionary*)calculateAltitudeDerivedFields{
    GCField * altitude = [GCField fieldForFlag:gcFieldFlagAltitudeMeters andActivityType:self.activityType];
    GCField * distance = [GCField fieldForFlag:gcFieldFlagSumDistance andActivityType:self.activityType];

    GCStatsDataSerieWithUnit * serie = [GCStatsDataSerieWithUnit dataSerieWithOther:[self timeSerieForField:altitude]];
    GCStatsDataSerieWithUnit * serie_dist = [GCStatsDataSerieWithUnit dataSerieWithOther:[self timeSerieForField:distance]];
    
    [GCStatsDataSerie reduceToCommonRange:serie.serie and:serie_dist.serie];
    
    GCStatsDataSerieWithUnit * adjusted = [GCStatsDataSerieWithUnit dataSerieWithUnit:serie.unit];
    
    adjusted.xUnit = serie.xUnit;

    NSDictionary<NSString*,GCStatsDataSerieWithUnit*>*calc = @{
        CALC_ALTITUDE_GAIN : [GCStatsDataSerieWithUnit dataSerieWithUnit:serie.unit],
        CALC_ALTITUDE_LOSS : [GCStatsDataSerieWithUnit dataSerieWithUnit:serie.unit],
        CALC_ELEVATION_GRADIENT : [GCStatsDataSerieWithUnit dataSerieWithUnit:GCUnit.percent]
    };
    
    double threshold = [[GCNumberWithUnit numberWithUnit:GCUnit.meter andValue:5.0] convertToUnit:serie.unit].value;
    
    if( serie.count == 0 || serie_dist.count == 0){
        return @{};
    }
    
    double current_altitude = [serie dataPointAtIndex:0].y_data;
    double current_altitude_distance = [serie_dist dataPointAtIndex:0].y_data;
    double current_elevation_gain = 0.;
    double current_elevation_loss = 0.;
    double current_elevation_gradient = 0.;
    
        
    double elevation_unit_to_dist_unit = [serie_dist.unit convertDouble:1.0 fromUnit:serie.unit];
    
    if( [serie dataPointAtIndex:0].x_data != [serie_dist dataPointAtIndex:0].x_data ){
        RZLog(RZLogInfo, @"Oops");
    }
    NSUInteger idx = 0;
    NSUInteger idx_current_altitude = 0;
    
    BOOL reportedInconsistency = false;
    
    for (GCStatsDataPoint * point in serie) {
        GCStatsDataPoint * point_dist = [serie_dist dataPointAtIndex:idx];
        if( point.x_data != point_dist.x_data ){
            if( ! reportedInconsistency ){
                // Only report once
                RZLog(RZLogWarning, @"Inconsistency between dist and serie for %@ and %@ at %lu", point, point_dist, (unsigned long) idx);
                reportedInconsistency = true;
            }
        }
        
        if( fabs( current_altitude - point.y_data ) > threshold ){
            if( current_altitude < point.y_data){
                current_elevation_gain += ( point.y_data - current_altitude);
            }
            if( current_altitude > point.y_data){
                current_elevation_loss += (point.y_data - current_altitude);
            }
            current_elevation_gradient = 100.0 * ( point.y_data - current_altitude) * elevation_unit_to_dist_unit / (point_dist.y_data - current_altitude_distance);
            current_altitude = point.y_data;
            current_altitude_distance = point_dist.y_data;
            // Fill Gradient since last elevation
            for( NSUInteger j = idx_current_altitude+1; j <= idx; j++){
                [calc[CALC_ELEVATION_GRADIENT].serie addDataPointWithX:[serie dataPointAtIndex:j].x_data
                                                                  andY:current_elevation_gradient];
            }
            idx_current_altitude = idx;
        }
        [calc[CALC_ALTITUDE_GAIN].serie addDataPointWithX:point.x_data andY:current_elevation_gain];
        [calc[CALC_ALTITUDE_LOSS].serie addDataPointWithX:point.x_data andY:current_elevation_loss];
        [adjusted.serie addDataPointWithX:point.x_data andY:current_altitude];

        idx++;
    }
    
    // compute speed with minimum of 10 sec and report for 1min (60secs)
    GCStatsDataSerie * ascentspeed = [serie.serie deltaYSerieForDeltaX:10. scalingFactor:60.0*60.0];
    GCStatsDataSerieWithUnit * final = [GCStatsDataSerieWithUnit dataSerieWithUnit:[GCUnit unitForKey:@"meterperhour"] andSerie:ascentspeed];
    final.xUnit = [GCUnit unitForKey:@"second"];

    NSDictionary * stats = [final.serie summaryStatistics];
    NSMutableDictionary * newFields = [NSMutableDictionary dictionary];
    NSDictionary * fields = @{
                              CALC_VERTICAL_SPEED: [GCActivityCalculatedValue calculatedValue:CALC_VERTICAL_SPEED value:[stats[STATS_AVG] doubleValue] unit:final.unit],
                              CALC_ASCENT_SPEED: [GCActivityCalculatedValue calculatedValue:CALC_ASCENT_SPEED value:[stats[STATS_AVGPOS] doubleValue] unit:final.unit],
                              CALC_DESCENT_SPEED: [GCActivityCalculatedValue calculatedValue:CALC_DESCENT_SPEED value:[stats[STATS_AVGNEG] doubleValue] unit:final.unit],
                              CALC_MAX_ASCENT_SPEED: [GCActivityCalculatedValue calculatedValue:CALC_MAX_ASCENT_SPEED value:[stats[STATS_MAX] doubleValue] unit:final.unit],
                              CALC_MAX_DESCENT_SPEED: [GCActivityCalculatedValue calculatedValue:CALC_MAX_DESCENT_SPEED value:[stats[STATS_MIN] doubleValue] unit:final.unit],
                              };

    for (NSString * key in fields) {
        newFields[ [GCField fieldForKey:key andActivityType:self.activityType] ] = fields[key];
    }
    [self addEntriesToCalculatedFields:newFields];

    NSMutableDictionary * rv = [NSMutableDictionary dictionary];
    if( final.serie.count > 0){
        rv[CALC_VERTICAL_SPEED] = final;
    }
    for (NSString*key in calc) {
        GCStatsDataSerieWithUnit * su = calc[key];
        if( su.serie.count > 0){
            rv[key] = su;
        }
    }
    [GCActivity registerCalculatedFields:self.activityType];
    
    return rv;
}

-(NSDictionary*)calculateSpeedDerivedFields{
    GCField * distanceField = [GCField fieldForFlag:gcFieldFlagSumDistance andActivityType:self.activityType];

    GCStatsDataSerieWithUnit * serie = [self timeSerieForField:distanceField];

    [serie convertToUnit:[GCUnit unitForKey:@"meter"]];

    GCStatsDataSerie * speedmps = [serie.serie deltaYSerieForDeltaX:10. scalingFactor:1.];

    GCStatsDataSerieWithUnit * final = [GCStatsDataSerieWithUnit dataSerieWithUnit:[GCUnit unitForKey:@"mps"] andSerie:speedmps];
    final.xUnit = [GCUnit unitForKey:@"second"];
    if ([self.activityType isEqualToString:GC_TYPE_RUNNING]) {
        [final convertToUnit:[GCUnit unitForKey:@"minperkm"]];
    }else{
        [final convertToUnit:[GCUnit unitForKey:@"kph"]];
    }

    [GCActivity registerCalculatedFields:self.activityType];
    
    return  @{CALC_10SEC_SPEED:final};
}

+(void)registerCalculatedFields:(NSString*)activityType{
    
    
    [GCFields registerField:[GCField fieldForKey:CALC_VERTICAL_SPEED andActivityType:activityType] displayName:NSLocalizedString(@"Vertical Speed", @"Calculated Field") andUnitName:@"meterperhour"];

    if ([activityType isEqualToString:GC_TYPE_RUNNING]) {
        [GCFields registerField:[GCField fieldForKey:CALC_10SEC_SPEED andActivityType:activityType] displayName:NSLocalizedString(@"10sec Pace", @"Calculated Field") andUnitName:@"minperkm"];
    }else{
        [GCFields registerField:[GCField fieldForKey:CALC_10SEC_SPEED andActivityType:activityType] displayName:NSLocalizedString(@"10sec Speed", @"Calculated Field") andUnitName:@"kph"];
    }

}

-(NSArray<GCTrackPoint*>*)matchDistance:(CLLocationDistance)target withPoints:(NSArray<GCTrackPoint*>*)points{
    CLLocationDistance x_a = 0.0;
    CLLocationDistance x_b = 5.0;
    
    CLLocationDistance  y_a = 0.0;
    CLLocationDistance  y_b = 0.0;

    CLLocationDistance x_c = 0.0;
    CLLocationDistance y_c = 0.0;

    y_a = [self filterTrackpoints:points with:x_a addTo:nil];
    y_b = [self filterTrackpoints:points with:x_b addTo:nil];

    while( (y_a - target) * (y_b - target) < 0 && fabs(y_b-target) > 1.0 && fabs(y_a-target) > 1.0 && fabs(x_a-x_b) > 0.001){
        x_c = (x_a+x_b)/2.0;
        y_c = [self filterTrackpoints:points with:x_c  addTo:nil];
        
        if( (y_a - target) * (y_c - target) < 0){
            x_b = x_c;
            y_b = y_c;
        }else{
            x_a = x_c;
            y_a = y_c;
        }
    }
    NSMutableArray * rv = [NSMutableArray array];
    if( fabs(y_a -target ) < fabs(y_b-target)){
        y_c = [self filterTrackpoints:points with:x_a  addTo:rv];
        x_c = x_a;
    }else{
        y_c = [self filterTrackpoints:points with:x_b  addTo:rv];
        x_c = x_b;
    }
    RZLog(RZLogInfo, @"trackpoints(<%f)[%lu] = %fm, orig[%lu] = %fm",x_c,(unsigned long)rv.count, y_c, (unsigned long)points.count, target );
    return rv;
}

-(CLLocationDistance)filterTrackpoints:(NSArray<GCTrackPoint*>*)trackpoints with:(CLLocationDistance)minimumDistance addTo:(NSMutableArray*)rv{
    CLLocationDistance finalDistance = 0.0;
    CLLocationDistance baseDistance = 0.0;
    NSUInteger n = 0;
    GCTrackPoint * last = nil;
    for (GCTrackPoint * next in trackpoints) {
        if( last != nil){
            CLLocationDistance dist = last != nil ? [next distanceMetersFrom:last] : 0.0;
            baseDistance += dist;

            if( next.validCoordinate && dist > minimumDistance ){
                finalDistance += dist;
                [rv addObject:next];
                n+=1;
            }
        }
        last = next;
    }
    return finalDistance;
}


@end
