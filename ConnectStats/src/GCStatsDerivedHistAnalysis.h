//  MIT License
//
//  Created on 07/06/2020 for ConnectStats
//
//  Copyright (c) 2020 Brice Rosenzweig
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



#import <Foundation/Foundation.h>
#import "GCHistoryPerformanceAnalysis.h"
#import "GCLagPeriod.h"

NS_ASSUME_NONNULL_BEGIN

/// which value to consider
/// for the analysis: absolute value of the best of or drop from the max
typedef NS_ENUM(NSUInteger,gcDerivedHistMode) {
    gcDerivedHistModeAbsolute,
    gcDerivedHistModeDrop,
};

typedef NS_ENUM(NSUInteger,gcDerivedHistSmoothing){
    gcDerivedHistSmoothingMax,
    gcDerivedHistSmoothingMovingAverage,
};

@interface GCStatsDerivedHistAnalysis : NSObject
@property (nonatomic,assign) gcDerivedHistSmoothing smoothing;
@property (nonatomic,assign) gcDerivedHistMode mode;
@property (nonatomic,retain) GCLagPeriod * longTermPeriod;
@property (nonatomic,retain) GCLagPeriod * shortTermPeriod;

@property (nonatomic,readonly) NSDate * fromDate;
@property (nonatomic,retain) GCLagPeriod * lookbackPeriod;

/// An array of number corresponding to the X to display
/// by default @[ @0, @60, @1800 ] which are seconds.
@property (nonatomic,retain) NSArray<NSNumber*>*pointsForGraphs;

+(GCStatsDerivedHistAnalysis*)config;
@end

NS_ASSUME_NONNULL_END
