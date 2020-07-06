//  MIT Licence
//
//  Created on 13/07/2014.
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

#import "GCStatsMultiFieldConfig.h"
#import "GCViewIcons.h"
#import "GCHistoryFieldDataSerie.h"
#import "GCSimpleGraphCachedDataSource+Templates.h"
#import "GCDerivedGroupedSeries.h"
#import "GCAppGlobal.h"

@interface GCStatsMultiFieldConfig ()
@property (nonatomic,retain) NSString * filterButtonTitle;
@property (nonatomic,retain) UIImage * filterButtonImage;

@property (nonatomic,assign) gcFieldFlag summaryCumulativeFieldFlag;
@property (nonatomic,retain) GCStatsCalendarAggregationConfig * calendarConfig;
@end

@implementation GCStatsMultiFieldConfig

-(GCStatsMultiFieldConfig*)init{
    self = [super init];
    if( self ){
        self.viewConfig = gcStatsViewConfigAll;
        self.viewChoice = gcViewChoiceSummary;
        self.calendarConfig = [GCStatsCalendarAggregationConfig globalConfigFor:NSCalendarUnitWeekOfYear];
    }
    return self;
}

-(void)dealloc{
    [_filterButtonImage release];
    [_filterButtonTitle release];
    [_activityType release];
    [super dealloc];
}

+(GCStatsMultiFieldConfig*)fieldListConfigFrom:(GCStatsMultiFieldConfig*)other{
    GCStatsMultiFieldConfig * rv = [[[GCStatsMultiFieldConfig alloc] init] autorelease];
    if (rv) {
        if (other!=nil) {
            rv.activityType = other.activityType;
            rv.viewChoice = other.viewChoice;
            rv.useFilter = other.useFilter;
            rv.viewConfig = other.viewConfig;
            rv.calendarConfig = [GCStatsCalendarAggregationConfig configFrom:other.calendarConfig];
        }else{
            rv.viewConfig = gcStatsViewConfigAll;
            rv.calendarConfig = [GCStatsCalendarAggregationConfig globalConfigFor:NSCalendarUnitWeekOfYear];
        }
    }
    return rv;
}

-(GCStatsMultiFieldConfig*)sameFieldListConfig{
    return [GCStatsMultiFieldConfig fieldListConfigFrom:self];
}
-(NSString *)viewDescription{
    return [GCViewConfig viewChoiceDesc:self.viewChoice calendarConfig:self.calendarConfig];
}
-(NSString*)description{
    return [NSString stringWithFormat:@"<%@: %@ view:%@ calUnit:%@ config:%@>", NSStringFromClass([self class]),
            self.activityType,
            self.viewChoiceKey,
            self.calendarConfig.calendarUnitKey,
            self.viewConfigKey
            ];
}

-(BOOL)isEqualToConfig:(GCStatsMultiFieldConfig*)other{
    return [self.activityType isEqualToString:other.activityType] && self.viewChoice==other.viewChoice && self.useFilter == other.useFilter
    && self.viewConfig==other.viewConfig && self.historyStats==other.historyStats && [self.calendarConfig isEqualToConfig:other.calendarConfig];
}

-(gcHistoryStats)historyStats{
    return self.calendarConfig.historyStats;
}

-(NSString*)viewChoiceKey{
    return [GCViewConfig viewChoiceKey:self.viewChoice];
}
-(void)setViewChoiceKey:(NSString *)viewChoiceKey{
    self.viewChoice = [GCViewConfig viewChoiceFromKey:viewChoiceKey];
}

-(NSString*)viewConfigKey{
    return [GCViewConfig viewConfigKey:self.viewConfig];
}

-(void)setViewConfigKey:(NSString *)viewConfigKey{
    self.viewConfig = [GCViewConfig viewConfigFromKey:viewConfigKey];
}

-(BOOL)nextView{
    switch (self.viewChoice) {
        case gcViewChoiceAll:
        {
            self.viewChoice = gcViewChoiceCalendar;
            self.viewConfig = gcStatsViewConfigAll;
            self.calendarConfig.calendarUnit = NSCalendarUnitWeekOfYear;
            break;
        }
        case gcViewChoiceCalendar:
        {
            BOOL done = [self.calendarConfig nextCalendarUnit];
            if( done ){
                self.viewChoice = gcViewChoiceSummary;
                self.viewConfig = gcStatsViewConfigUnused;
                self.calendarConfig.calendarUnit = NSCalendarUnitWeekOfYear;
            }
            break;
        }
        case gcViewChoiceSummary:
        {
            self.viewChoice = gcViewChoiceAll;
            self.viewConfig = gcStatsViewConfigUnused;
            self.calendarConfig.calendarUnit = NSCalendarUnitWeekOfYear;
            break;
        }
    }
    // summary is the first
    return (self.viewChoice == gcViewChoiceSummary);
}

-(BOOL)nextViewConfig{
    BOOL rv = false;
    
    switch (self.viewChoice ){
        case gcViewChoiceSummary:
        {
            // no config for summary;
            self.viewConfig = gcStatsViewConfigAll;
            rv = true;
            break;
        }
        case gcViewChoiceAll:
        {
            // View all Fields, then rotate between view week or month
            // if comes as anything but end, next is end nd use calendarUnit
            // (if was switch to all then next is End/CalUnit)
            self.viewConfig = gcStatsViewConfigUnused;
            if( [self.calendarConfig nextCalendarUnit] ){
                rv = true;
            }
            break;
        }
        case gcViewChoiceCalendar:
        { // View monthly, weekly or yearly aggregated stats
            gcStatsViewConfig start = gcStatsViewConfigAll;
            NSCalendarUnit calUnit = self.calendarConfig.calendarUnit;
            if (calUnit == NSCalendarUnitWeekOfYear) {
                start = gcStatsViewConfigLast3M;
            }else if(calUnit == NSCalendarUnitMonth){
                start = gcStatsViewConfigLast6M;
            }else{
                start = gcStatsViewConfigToDate;
            }
            if (self.viewConfig==gcStatsViewConfigAll) {
                self.viewConfig = start;
            }else{
                self.viewConfig++;
            }
            if (self.viewConfig >= gcStatsViewConfigUnused) {
                self.viewConfig = gcStatsViewConfigAll;
                rv = true;
            }
            break;
        }
    }

    return rv;
}

#pragma mark - Setups


-(UIBarButtonItem*)buttonForTarget:(id)target action:(SEL)sel{
    [self setupButtonInfo];
    UIBarButtonItem * cal = nil;

    if (self.filterButtonImage) {
        cal = [[[UIBarButtonItem alloc] initWithImage:self.filterButtonImage
                                                style:UIBarButtonItemStylePlain
                                               target:target
                                               action:sel] autorelease];
    }else if (self.filterButtonTitle){
        cal = [[[UIBarButtonItem alloc] initWithTitle:self.filterButtonTitle
                                                style:UIBarButtonItemStylePlain
                                               target:target
                                               action:sel] autorelease];
    }
    return cal;
}

-(void)setupButtonInfo{
    UIImage * image = nil;
    if (self.viewChoice==gcViewChoiceAll ) {
        switch (self.historyStats) {
            case gcHistoryStatsMonth:
                image = [GCViewIcons navigationIconFor:gcIconNavMonthly];
                break;
            case gcHistoryStatsWeek:
                image = [GCViewIcons navigationIconFor:gcIconNavWeekly];
                break;
            case gcHistoryStatsYear:
                image = [GCViewIcons navigationIconFor:gcIconNavYearly];
                break;
            case gcHistoryStatsAll:
            case gcHistoryStatsEnd:
                image = [GCViewIcons navigationIconFor:gcIconNavAggregated];
                break;
        }
    }else if (self.viewChoice==gcViewChoiceSummary){
        image = nil;
    }else{
        switch (self.viewConfig) {
            case gcStatsViewConfigLast3M:
                image = [GCViewIcons navigationIconFor:gcIconNavQuarterly];
                break;
            case gcStatsViewConfigLast6M:
                image = [GCViewIcons navigationIconFor:gcIconNavSemiAnnually];
                break;
            case gcStatsViewConfigLast1Y:
                image = [GCViewIcons navigationIconFor:gcIconNavYearly];
                break;
            case gcStatsViewConfigToDate:
            case gcStatsViewConfigAll:
            case gcStatsViewConfigUnused:
                image = nil;//[GCViewIcons navigationIconFor:gcIconNavAggregated];
                break;

        }
    }
    NSString * calTitle = NSLocalizedString(@"All", @"Button Calendar");
    if (self.viewChoice == gcViewChoiceSummary) {
        calTitle = nil;
    }
    if (self.viewConfig == gcStatsViewConfigToDate) {
        NSCalendarUnit calUnit = self.calendarConfig.calendarUnit;
        if (calUnit == NSCalendarUnitYear) {
            calTitle = NSLocalizedString(@"YTD", @"Button Calendar");
        }else if (calUnit == NSCalendarUnitWeekOfYear){
            calTitle= NSLocalizedString(@"WTD", @"Button Calendar");
        }else if (calUnit == NSCalendarUnitMonth){
            calTitle= NSLocalizedString(@"MTD", @"Button Calendar");
        }
    }

    self.filterButtonImage = image;
    self.filterButtonTitle = calTitle;
}

-(GCSimpleGraphCachedDataSource*)dataSourceForFieldDataSerie:(GCHistoryFieldDataSerie*)fieldDataSerie{
    GCField * field = fieldDataSerie.activityField;
    GCSimpleGraphCachedDataSource * cache = nil;
    gcGraphChoice choice = self.calendarConfig.calendarUnit == NSCalendarUnitYear ? gcGraphChoiceCumulative : gcGraphChoiceBarGraph;

    NSDate * afterdate = nil;
    NSString * compstr = nil;
    NSCalendarUnit calunit =NSCalendarUnitWeekOfYear;
    if (self.viewChoice == gcViewChoiceAll ||self.viewChoice == gcViewChoiceSummary) {
        switch (self.historyStats) {
            case gcHistoryStatsMonth:
                compstr = @"-1Y";
                calunit = NSCalendarUnitMonth;
                break;
            case gcHistoryStatsWeek:
                compstr = @"-3M";
                calunit = NSCalendarUnitWeekOfYear;
                break;
            case gcHistoryStatsYear:
                compstr = @"-5Y";
                calunit = NSCalendarUnitYear;
                break;
            case gcHistoryStatsAll:
            case gcHistoryStatsEnd:
                compstr = nil;
                calunit = NSCalendarUnitYear;
                if ([field canSum]){
                    choice = gcGraphChoiceCumulative;
                }else{
                    compstr = @"-1Y";
                    choice = gcGraphChoiceBarGraph;
                    calunit = NSCalendarUnitMonth;
                }
                break;
        }
    }else{
        calunit = self.calendarConfig.calendarUnit;
        switch (self.viewConfig) {
            case gcStatsViewConfigLast1Y:
                compstr = @"-1Y";
                break;
            case gcStatsViewConfigLast3M:
                compstr = @"-3M";
                break;
            case gcStatsViewConfigLast6M:
                compstr = @"-6M";
                break;
            case gcStatsViewConfigAll:
            case gcStatsViewConfigUnused:
            case gcStatsViewConfigToDate:
                break;
        }
    }

    if (compstr) {
        afterdate = [[fieldDataSerie lastDate] dateByAddingGregorianComponents:[NSDateComponents dateComponentsFromString:compstr]];
    }

    cache = [GCSimpleGraphCachedDataSource historyView:fieldDataSerie
                                        calendarConfig:[self.calendarConfig equivalentConfigFor:calunit]
                                           graphChoice:choice
                                                 after:afterdate];
    if (self.viewConfig == gcStatsViewConfigToDate &&  self.viewChoice == gcViewChoiceCalendar) {
        [cache setupAsBackgroundGraph];
        GCHistoryFieldDataSerie * cut = [fieldDataSerie serieWithCutOff:fieldDataSerie.lastDate inCalendarUnit:calunit withReferenceDate:nil];
        GCSimpleGraphCachedDataSource * main = [GCSimpleGraphCachedDataSource historyView:cut
                                                                           calendarConfig:self.calendarConfig
                                                                              graphChoice:choice
                                                                                    after:afterdate];
        [main addDataSource:cache];
        cache = main;
    }
    return cache;
}

-(void)nextSummaryCumulativeField{
    if( self.summaryCumulativeFieldFlag != gcFieldFlagSumDuration ){
        self.summaryCumulativeFieldFlag = gcFieldFlagSumDuration;
    }else{
        self.summaryCumulativeFieldFlag = gcFieldFlagSumDistance;
    }

}


#pragma mark - cumulative Summary Field

-(GCField*)currentCumulativeSummaryField{
    // Ignore any value other than sumDuration or SumDistance
    gcFieldFlag which = self.summaryCumulativeFieldFlag == gcFieldFlagSumDuration ? gcFieldFlagSumDuration : gcFieldFlagSumDistance;
    return [GCField fieldForFlag:which andActivityType:self.activityType];
}
@end
