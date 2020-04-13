//  MIT Licence
//
//  Created on 26/03/2016.
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
#import "GCFieldInfo.h"

@class FMDatabase;
@class GCField;

@interface GCFieldCache : NSObject

@property (nonatomic,readonly) NSArray<GCField*>*availableFields;
@property (nonatomic,readonly) NSArray<NSString*>*availableActivityTypes;

+(NSArray<NSString*>*)availableLanguagesCodes;
+(NSArray<NSString*>*)availableLanguagesNames;

+(GCFieldCache*)cacheWithDb:(FMDatabase*)db andLanguage:(NSString*)language;

-(GCFieldInfo*)infoForField:(GCField*)field;
-(GCFieldInfo*)infoForActivityType:(NSString*)activityType;

-(void)registerFields:(NSDictionary<GCField*,GCFieldInfo*>*)info;
-(void)registerField:(GCField*)field displayName:(NSString*)aName andUnitName:(NSString*)uom;

-(BOOL)knownField:(NSString*)field activityType:(NSString*)activityType;
-(NSArray<NSString*>*)knownFieldsMatching:(NSString*)str;

-(NSDictionary<GCField*,GCFieldInfo*>*)missingPredefinedField;

// Deprecated
-(GCFieldInfo*)infoForField:(NSString*)field andActivityType:(NSString*)aType DEPRECATED_MSG_ATTRIBUTE( "use infoForField:(GCField*)");
-(void)registerField:(NSString*)field activityType:(NSString*)aType displayName:(NSString*)aName  andUnitName:(NSString*)uom DEPRECATED_MSG_ATTRIBUTE( "Only use predefined");


@end
