//  MIT Licence
//
//  Created on 10/01/2016.
//
//  Copyright (c) 2016 Brice Rosenzweig.
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

@class GCField;


@interface GCTrackPointExtraIndex : NSObject

@property (nonatomic,assign) size_t idx;
@property (nonatomic,retain) GCUnit * unit;
@property (nonatomic,retain) GCField* field;

@property (nonatomic,readonly) NSString * dataColumnName;

+(GCTrackPointExtraIndex*)extraIndex:(size_t)idx field:(GCField*)field andUnit:(GCUnit*)unit;
+(GCTrackPointExtraIndex*)extraIndexForField:(GCField*)field withUnit:(GCUnit*)unit in:(NSDictionary*)cache;
@end

@protocol GCTrackPointDelegate
@required
-(NSDictionary<GCField*,GCTrackPointExtraIndex*> * )cachedExtraTracksIndexes;
-(void )setCachedExtraTracksIndexes:(NSDictionary<GCField*,GCTrackPointExtraIndex*> *)dict;
-(NSString*)activityType;
@end
