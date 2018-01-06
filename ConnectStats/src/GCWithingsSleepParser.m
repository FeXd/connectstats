//  MIT Licence
//
//  Created on 09/10/2014.
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

#import "GCWithingsSleepParser.h"

@implementation GCWithingsSleepParser


+(GCWithingsSleepParser*)sleepParserFor:(NSData*)data{
    GCWithingsSleepParser * rv = [[[GCWithingsSleepParser alloc] init] autorelease];
    if (rv) {
        [rv parse:data];
    }
    return rv;
}
-(void)dealloc{
    [_blocks release];
    [super dealloc];
}

-(void)parse:(NSData*)data{
    NSError * err = nil;
    self.success = false;
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err ];
    if (json==nil) {
        RZLog(RZLogError, @"json parsing failed %@", err);
    }else {
        NSArray * raw = json[@"body"][@"series"];
        NSMutableArray * parsed = [NSMutableArray arrayWithCapacity:raw.count];
        GCHealthSleepMeasure * prev = nil;
        NSMutableArray * blockMeasures = [NSMutableArray arrayWithCapacity:raw.count];
        for (NSDictionary * one in raw) {
            NSDate * from = [NSDate dateWithTimeIntervalSince1970:[one[@"startdate"] doubleValue]];
            NSDate * to   = [NSDate dateWithTimeIntervalSince1970:[one[@"enddate"] doubleValue]];
            gcSleepState state = [one[@"state"] integerValue];

            //GCNumberWithUnit * nu = [GCNumberWithUnit numberWithUnitName:@"second" andValue:[to timeIntervalSinceDate:from]];
            GCHealthSleepMeasure * measure = [GCHealthSleepMeasure measureFor:from elapsed:[to timeIntervalSinceDate:from] state:state previous:prev];

            if (prev != nil && ![prev.blockId isEqualToString:measure.blockId]) {
                // new block, save old one
                GCHealthSleepBlock * block = [GCHealthSleepBlock blockWithMeasures:blockMeasures];
                [parsed addObject:block];
                [blockMeasures removeAllObjects];

            }

            [blockMeasures addObject:measure];
            prev = measure;
        }
        self.blocks = parsed;
    }
}
@end