//  MIT Licence
//
//  Created on 04/10/2012.
//
//  Copyright (c) 2012 Brice Rosenzweig.
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
#import "GCFieldsCategory.h"
#import "GCFieldsDefs.h"

NS_INLINE BOOL GCActivityTypeIsDay(NSString*at){
    return [at isEqualToString:GC_TYPE_DAY];
}

NS_INLINE BOOL GCActivityTypeIsSki(NSString*at, NSString*atdetail){
    return [at isEqualToString:GC_TYPE_OTHER] && ([atdetail isEqualToString:GC_TYPE_SKI_BACK] || [atdetail isEqualToString:GC_TYPE_SKI_DOWN] || [atdetail isEqualToString:GC_TYPE_SKI_XC]);
}

@class GCFieldsForCategory;
@class GCFieldCache;

@interface GCFields : NSObject

+(GCFieldCache*)fieldCache;
+(void)setFieldCache:(GCFieldCache*)cache;

+(BOOL)fieldCanAverage:(NSString*)field;
+(BOOL)fieldCanSum:(NSString*)field;
+(BOOL)fieldIsMax:(NSString*)field;
+(BOOL)fieldAverageIsweighted:(NSString*)field;

+(NSArray*)relatedFields:(NSString*)field;
+(NSString*)calcOrFieldFor:(NSString*)field;
/**
 Will group the list of fields into appropriate categories
 The array will be sorted by category sort order and fields by field order within category
 @param fields is an array of GCField or NSString field Keys (in which case activityType is required
 @param activityType is required if a field key is passed instead of GCField
 */
+(NSArray<GCFieldsForCategory*>*)categorizeAndOrderFields:(NSArray*)fields forActivityType:(NSString*)activityType;

+(NSString*)activityTypeDisplay:(NSString*)activityType;

+(NSArray*)knownFieldsMatching:(NSString*)str;
+(BOOL)knownField:(NSString*)field activityType:(NSString*)activityType;
+(GCUnit*)fieldUnit:(NSString*)field activityType:(NSString*)activityType;
+(NSString*)fieldUnitName:(NSString*)field activityType:(NSString*)activityType;
+(NSString*)fieldDisplayName:(NSString*)field activityType:(NSString*)activityType;
+(gcUnitSystem)fieldUnitSystem;
+(NSArray*)missingPredefinedField;

+(NSString*)metaFieldDisplayName:(NSString*)metaField;

+(NSString*)field:(NSString*)field withIntensity:(gcIntensityLevel)level;

+(gcFieldFlag)trackFieldFromActivityField:(NSString*)aActivityField;
+(NSString*)activityFieldFromTrackField:(gcFieldFlag)aTrackField andActivityType:(NSString*)aAct;
+(BOOL)noisyField:(gcFieldFlag)aTrackField forActivityType:(NSString*)aType;
+(NSArray*)availableFieldsIn:(NSUInteger)flag forActivityType:(NSString*)atype;
+(NSArray*)availableTrackFieldsIn:(NSUInteger)flag;
+(NSArray*)describeTrackFields:(gcFieldFlag)flag forActivityType:(NSString*)aType;
+(gcFieldFlag)nextTrackField:(gcFieldFlag)which in:(NSUInteger)flag;
+(NSString*)trackFieldDisplayName:(gcFieldFlag)which forActivityType:(NSString*)aAct;
+(BOOL)trackFieldCanSum:(gcFieldFlag)field;

+(NSString*)lapFieldForField:(NSString*)field;
+(NSString*)fieldForLapField:(NSString*)field andActivityType:(NSString*)aType;
+(GCUnit*)unitForLapField:(NSString*)field activityType:(NSString*)aType;

+(void)registerField:(NSString*)field activityType:(NSString*)aType displayName:(NSString*)aName  andUnitName:(NSString*)uom;
+(NSString*)fieldForFlag:(gcFieldFlag)which andActivityType:(NSString*)activityType;

+(NSString*)fieldForAggregatedField:(gcAggregatedField)which andActivityType:(NSString*)actType;

+(BOOL)skipField:(NSString*)field;
+(void)ensureDbStructure:(FMDatabase*)aDb;

+(NSString*)fieldDisplayNameAndUnits:(NSString *)field activityType:(NSString*)aType;
+(NSString*)fieldDisplayNameAndUnits:(NSString *)fieldStr activityType:(NSString*)aType unit:(GCUnit*)unit;


+(NSArray*)swimLapFields;
+(NSString*)swimLapFieldFromTrackField:(gcFieldFlag)tfield;
+(gcFieldFlag)trackFieldFromSwimLapField:(NSString*)f;
+(NSString*)swimStrokeName:(gcSwimStrokeType)tp;

+(NSString*)predefinedDisplayNameForField:(NSString*)afield andActivityType:(NSString*)atype;
+(NSString*)predefinedUomForField:(NSString*)afield andActivityType:(NSString*)atype;

@end
