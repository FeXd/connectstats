//  MIT Licence
//
//  Created on 01/03/2014.
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

#import "GCWebConnect+Requests.h"

#import "GCService.h"
#import "GCWebUrl.h"
#import "GCAppGlobal.h"
#import "GCActivityTennis.h"

#import "GCGarminRequestActivityReload.h"
#import "GCGarminActivityTrack13Request.h"
#import "GCGarminRequestModernActivityTypes.h"
#import "GCGarminLoginSimulatorRequest.h"
#import "GCGarminLoginSSORequest.h"
#import "GCGarminRequestModernSearch.h"
#import "GCGarminRequestHeartRateZones.h"

#import "GCConnectStatsRequestSearch.h"
#import "GCConnectStatsRequestFitFile.h"
#import "GCConnectStatsRequestLogin.h"
#import "GCConnectStatsRequestWeather.h"

#import "GCWithingsBodyMeasures.h"

#import "GCHealthKitBodyRequest.h"
#import "GCHealthKitActivityRequest.h"
#import "GCHealthKitWorkoutsRequest.h"
#import "GCHealthKitDailySummaryRequest.h"
#import "GCHealthKitDayDetailRequest.h"
#import "GCHealthKitExportActivity.h"
#import "GCHealthKitSourcesRequest.h"

#import "GCStravaActivityList.h"
#import "GCStravaActivityStreams.h"
#import "GCStravaSegmentListStarred.h"
#import "GCStravaAthlete.h"
#import "GCStravaSegmentEfforts.h"
#import "GCStravaSegmentEffortStream.h"

#import "GCBabolatLoginRequest.h"

#import "GCDerivedRequest.h"
#import "GCHealthOrganizer.h"

@implementation GCWebConnect (Requests)

#pragma mark - search activity list

-(void)downloadMissingActivityDetails:(NSUInteger)n{
    NSArray * activities = [[GCAppGlobal organizer] activities];
    NSUInteger i = 0;
    NSDate * mostRecent = nil;
    NSDate * oldest = nil;
    for (GCActivity * activity in activities) {
        if ([activity trackPointsRequireDownload]) {
            NSTimeInterval since = [[activity date] timeIntervalSinceNow];
            // Only load the last year
            if (since > -3600. * 24.0 * 365.) {
                if( mostRecent == nil){
                    mostRecent = activity.date;
                    oldest = activity.date;
                }else{
                    if( [activity.date compare:oldest] == NSOrderedAscending){
                        oldest = activity.date;
                    }
                }
                [activity trackpoints];
            }
            i++;
        }
        if (i >= n) {
            break;
        }
    }
    if( oldest != nil && mostRecent != nil){
        RZLog(RZLogInfo, @"Download %lu Missing Details from %@ to %@", (unsigned long)i+1, oldest.YYYYdashMMdashDD, mostRecent.YYYYdashMMdashDD);
    }else{
        RZLog(RZLogInfo, @"Download Missing Details (none required out of %lu activities", (unsigned long)activities.count);
    }
}

-(void)nonGarminSearch:(BOOL)reloadAll{
    if ([[GCAppGlobal profile] configGetBool:CONFIG_STRAVA_ENABLE defaultValue:NO]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[GCStravaActivityList stravaActivityList:[GCAppGlobal currentNavigationController] start:0 andMode:reloadAll]];
        });
    }
    // For testing
    if([[GCAppGlobal profile] configGetBool:CONFIG_STRAVA_SEGMENTS defaultValue:NO]){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[GCStravaAthlete stravaAthlete:[GCAppGlobal currentNavigationController]]];
            [self addRequest:[GCStravaSegmentListStarred segmentListStarred:[GCAppGlobal currentNavigationController]]];
        });
    }

    if ([[GCAppGlobal profile] configGetBool:CONFIG_BABOLAT_ENABLE defaultValue:false]) {
        [self addRequest:[GCBabolatLoginRequest babolatLoginRequest]];
    }
    if ([[GCAppGlobal profile] configGetBool:CONFIG_WITHINGS_AUTO defaultValue:false]) {
        [self withingsUpdate];
    }
    if ([GCHealthKitRequest isSupported]) {
        if ([[GCAppGlobal profile] configGetBool:CONFIG_HEALTHKIT_ENABLE defaultValue:[GCAppGlobal healthStatsVersion]]) {
            if (![[GCAppGlobal profile] sourceIsSet]) {
                [self healthStoreCheckSource];
            }
            [self healthStoreUpdate];
        }
    }
    if ([[GCAppGlobal profile] configGetBool:CONFIG_ENABLE_DERIVED defaultValue:[GCAppGlobal connectStatsVersion]]) {
        [self derivedComputations:1];
    }
    // If on wifi, try to download extra missing details
    if ([[GCAppGlobal profile] configGetBool:CONFIG_WIFI_DOWNLOAD_DETAILS defaultValue:false] &&  [RZSystemInfo wifiAvailable]) {
        [self downloadMissingActivityDetails:15];
    }
}

-(void)garminSearchFrom:(NSUInteger)aStart reloadAll:(BOOL)reloadAll{
    if( ([[GCAppGlobal profile] configGetBool:CONFIG_CONNECTSTATS_ENABLE defaultValue:NO])){
        // Run on main queue as it accesses a navigation Controller
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[GCConnectStatsRequestLogin requestNavigationController:[GCAppGlobal currentNavigationController]]];
            [self addRequest:[GCConnectStatsRequestSearch requestWithStart:0 mode:reloadAll andNavigationController:[GCAppGlobal currentNavigationController]]];
        });
        
    }
    
    if ([[GCAppGlobal profile] configGetBool:CONFIG_GARMIN_ENABLE defaultValue:NO]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[[[GCGarminRequestModernActivityTypes alloc] init] autorelease]];
            [self addRequest:[[[GCGarminRequestModernSearch alloc] initWithStart:aStart andMode:reloadAll] autorelease]];
            [self addRequest:[[[GCGarminRequestModernActivityTypes alloc] init] autorelease]];
        });
    }
}
-(void)servicesSearchActivitiesFrom:(NSUInteger)aStart reloadAll:(BOOL)rAll{
    [self servicesLogin];
    [self garminSearchFrom:aStart reloadAll:rAll];
    [self nonGarminSearch:rAll];
}

-(void)servicesSearchRecentActivities{
    [self servicesLogin];
    [self garminSearchFrom:0 reloadAll:false];
    [self nonGarminSearch:false];
}

-(void)servicesSearchAllActivities{
    [self servicesLogin];
    [self garminSearchFrom:0 reloadAll:true];
    [self nonGarminSearch:true];
}

-(void)servicesResetLogin{
    [self resetSuccessfulLogin];
    [self servicesLogin];
}
-(void)servicesLogin{
    if (![self didLoginSuccessfully:gcWebServiceGarmin]&& [[GCAppGlobal profile] configGetBool:CONFIG_GARMIN_ENABLE defaultValue:NO]) {
        [self garminLogin];
    }
    
    // other services are automatic
}


#pragma mark - withings
-(void)withingsChangeUser:(NSString*)shortname{
    NSArray * users = [[GCAppGlobal profile] configGetArray:CONFIG_WITHINGS_USERSLIST defaultValue:@[]];
    NSString * current = [[GCAppGlobal profile] configGetString:CONFIG_WITHINGS_USER defaultValue:@""];
    if (users && ![shortname isEqualToString:current]) {
        NSDictionary * found = nil;
        for (NSDictionary * one in users) {
            if ([one[@"shortname"] isEqualToString:current]) {
                found = one;
                break;
            }
        }
        if (found) {
            [[GCAppGlobal profile] configSet:CONFIG_WITHINGS_USER stringVal:shortname];
            [GCAppGlobal saveSettings];
            [[GCAppGlobal health] clearAllMeasures];
            [[GCAppGlobal profile] serviceSuccess:gcServiceWithings set:NO];
            [self withingsUpdate];
        }
    }
}
-(void)withingsUpdate{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self addRequest:[GCWithingsBodyMeasures measuresSinceDate:nil with:[GCAppGlobal currentNavigationController]]];
    });
}
#pragma mark - download track details

-(void)garminDownloadActivityTrackPoints13:(GCActivity*)act{
    // If the service for garmin was successfull, download anyway.
    // it's possible it's the detail of an old activities, downloaded before the service was turned off.
    if( [[GCAppGlobal profile] serviceSuccess:gcServiceGarmin] || [[GCAppGlobal profile] configGetBool:CONFIG_GARMIN_ENABLE defaultValue:NO] ){
        [self addRequest:[GCGarminActivityTrack13Request requestWithActivity:act]];
    }
}

-(void)garminDownloadActivitySummary:(NSString*)aId{
    if(  [[GCAppGlobal profile] configGetBool:CONFIG_GARMIN_ENABLE defaultValue:NO] ){
        [self addRequest:[[[GCGarminRequestActivityReload alloc] initWithId:aId] autorelease]];
    }
}


-(BOOL)isGarminSimulatorAccount:(NSString*)username andPassword:(NSString*)password{
    return ([username hasPrefix:@"simulator"] || [username hasPrefix:@"testaccount"]) && ([password isEqualToString:@"iamatesterfromapple"] || [password isEqualToString:@"iamafriendofbrice"]);
}

-(void)garminLogin{
    if (!self.isProcessing && [[GCAppGlobal profile] configGetBool:CONFIG_GARMIN_ENABLE defaultValue:NO]) {
        gcGarminLoginMethod method = (gcGarminLoginMethod)[[GCAppGlobal profile] configGetInt:CONFIG_GARMIN_LOGIN_METHOD defaultValue:GARMINLOGIN_DEFAULT];

        NSString * username = [[GCAppGlobal profile] currentLoginNameForService:gcServiceGarmin];
        NSString * password = [[GCAppGlobal profile] currentPasswordForService:gcServiceGarmin];

        bool simulatorAccount = [self isGarminSimulatorAccount:username andPassword:password];

        if( simulatorAccount ){
            method = gcGarminLoginMethodSimulator;
            RZLog(RZLogInfo, @"Test Username Detected <%@> entering simulator mode", username);
        }
        if (method == gcGarminLoginMethodSimulator) {
            [self clearCookies];
            GCGarminLoginSimulatorRequest * first  = [[[GCGarminLoginSimulatorRequest alloc] init] autorelease];
            GCGarminLoginSimulatorRequest * second = [[[GCGarminLoginSimulatorRequest alloc] initWithName:username andPwd:password] autorelease];
            if ( simulatorAccount ) {
                GCWebUseSimulator(true, [GCAppGlobal simulatorUrl]);
            }else{
                GCWebUseSimulator(false, nil);
            }
            //GCWebUseSimulator(true);
            [self.requests removeAllObjects];
            [self resetStatus];
            [self.requests addObject:first];
            [self.requests addObject:second];
            self.status = GCWebStatusOK;
        }else if (method == gcGarminLoginMethodDirect){
            [self clearCookies];
            [self.requests removeAllObjects];
            [self resetStatus];
            [self.requests addObject:[GCGarminLoginSSORequest requestWithUser:[[GCAppGlobal profile] currentLoginNameForService:gcServiceGarmin]
                                                                       andPwd:[[GCAppGlobal profile] currentPasswordForService:gcServiceGarmin]]];
        }
    }
}

-(void)garminLogout{
    return;
    /*if (!self.processing) {
        [self clearCookies];
        [self.requests removeAllObjects];
        [self.requests addObject:[[[GCGarminLogout alloc] init] autorelease]];
        [self next];
    }*/
}

-(void)garminTestLogin{
    if (!self.isProcessing) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *each in cookieStorage.cookies) {
            [cookieStorage deleteCookie:each];
        }
        GCGarminLoginSimulatorRequest * first  = [[[GCGarminLoginSimulatorRequest alloc] init] autorelease];
        GCGarminLoginSimulatorRequest * second = [[[GCGarminLoginSimulatorRequest alloc] initWithName:[[GCAppGlobal profile] currentLoginNameForService:gcServiceGarmin]
                                                                                         andPwd:[[GCAppGlobal profile] currentPasswordForService:gcServiceGarmin]] autorelease];

        bool simulatorAccount = [self isGarminSimulatorAccount:second.uname andPassword:second.pwd];
        if (simulatorAccount) {
            GCWebUseSimulator(true,[GCAppGlobal simulatorUrl]);
        }else{
            GCWebUseSimulator(false,nil);
        }
        //GCWebUseSimulator(true);
        [self.requests removeAllObjects];
        [self.requests addObject:first];
        [self.requests addObject:second];
        self.status = GCWebStatusOK;
    }
}
#pragma mark - connectstats

-(void)connectStatsDownloadActivityTrackpoints:(GCActivity*)act{
    if( [GCAppGlobal currentNavigationController] && ( [[GCAppGlobal profile] serviceSuccess:gcServiceConnectStats] || [[GCAppGlobal profile] configGetBool:CONFIG_CONNECTSTATS_ENABLE defaultValue:NO] )){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[GCConnectStatsRequestFitFile requestWithActivity:act andNavigationController:[GCAppGlobal currentNavigationController]]];
        });
    }
}
-(void)connectStatsDownloadWeather:(GCActivity *)act{
    if( [GCAppGlobal currentNavigationController] && ( [[GCAppGlobal profile] serviceSuccess:gcServiceConnectStats] || [[GCAppGlobal profile] configGetBool:CONFIG_CONNECTSTATS_ENABLE defaultValue:NO] )){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self addRequest:[GCConnectStatsRequestWeather requestWithActivity:act andNavigationController:[GCAppGlobal currentNavigationController]]];
        });
    }

}
#pragma mark - strava

-(void)stravaDownloadActivityTrackPoints:(GCActivity*)act{
    dispatch_async(dispatch_get_main_queue(), ^(){
        if ([GCAppGlobal currentNavigationController] && [[GCAppGlobal profile] configGetBool:CONFIG_STRAVA_ENABLE defaultValue:NO]) {
            [self addRequest:[GCStravaActivityStreams stravaActivityStream:[GCAppGlobal currentNavigationController] for:act]];
        }
    });
}

#pragma mark - healthstore

-(void)healthStoreUpdate{
    NSDate * startDate = [NSDate date];
    if( [[GCAppGlobal profile] configGetBool:CONFIG_HEALTHKIT_DAILY defaultValue:[GCAppGlobal healthStatsVersion]]){
        [self addRequest:[GCHealthKitDailySummaryRequest requestFor:startDate]];
        [self addRequest:[GCHealthKitDayDetailRequest requestForDate:startDate to:[[NSDate date] dateByAddingTimeInterval:-3600*24*7]]];
    }
    
    if ([[GCAppGlobal profile] configGetBool:CONFIG_HEALTHKIT_WORKOUT defaultValue:[GCAppGlobal healthStatsVersion]]) {
        if( [GCAppGlobal healthStatsVersion] ){
            GCHealthKitWorkoutsRequest * req = [GCHealthKitWorkoutsRequest request];
            //[req resetAnchor];
            [self addRequest:req];
        }else{
            RZLog(RZLogWarning, @"Disabled Workout from healthkit");
        }
    }
    [self addRequest:[GCHealthKitBodyRequest request]];
}

-(void)healthStoreExportActivity:(GCActivity*)act{
    [self addRequest:[GCHealthKitExportActivity healthKitExportActivity:act]];
}

-(void)healthStoreDayDetails:(NSDate * )day{
    [self addRequest:[GCHealthKitDayDetailRequest requestForDate:day]];
}

-(void)healthStoreCheckSource{
    [self addRequest:[GCHealthKitSourcesRequest request]];
}

#pragma mark - Babolat

-(void)babolatDownloadTennisActivityDetails:(NSString*)aId{
    if ([GCActivityTennis isTennisActivityId:aId]) {
        GCBabolatLoginRequest * req = [GCBabolatLoginRequest babolatLoginRequest];
        req.sessionId = [[GCService service:gcServiceBabolat] serviceIdFromActivityId:aId];
        [self addRequest:req];
    }
}

#pragma mark - derived
-(void)derivedComputations:(NSUInteger)n{
    [self addRequest:[GCDerivedRequest requestFor:n]];
}


@end
