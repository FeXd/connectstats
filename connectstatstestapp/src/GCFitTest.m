//  MIT Licence
//
//  Created on 20/03/2014.
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

#import "GCFitTest.h"
#import "ConnectStats-Swift.h"
//#import "GCAppGlobal.h"

@implementation GCFitTest

-(NSArray*)testDefinitions{
    return @[ @{TK_SEL:NSStringFromSelector(@selector(testParseFitFile)),
                TK_DESC:@"Test parsing fit files",
                TK_SESS:@"GC FitTest"}
              ];
}

-(void)testParseFitFile{
	[self startSession:@"GC FitTest"];


    NSString * fn = @"bike.fit";
    NSData * fitData = [NSData dataWithContentsOfFile:[RZFileOrganizer bundleFilePath:fn]];
    FITFitFileDecode * fitDecode = [FITFitFileDecode fitFileDecode:fitData];
    [fitDecode parse];

    GCActivity * fitAct = RZReturnAutorelease([[GCActivity alloc] initWithId:@"id" fitFile:fitDecode.fitFile]);
    [self assessTestResult:@"Parsed records" result:[fitAct.trackpoints count]==4235];

	[self endSession:@"GC FitTest"];

}



@end
