//
//  GCField+FitFile.swift
//  GarminConnect
//
//  Created by Brice Rosenzweig on 08/11/2016.
//  Copyright © 2016 Brice Rosenzweig. All rights reserved.
//

import Foundation

public extension GCField {
    
    static let fitToFieldMap = ["cadence":"WeightedMeanCadence",
                                "distance":"SumDistance",
                                "speed":"WeightedMeanSpeed",
                                "temperature":"WeightedTemperature",
                                "heart_rate": "WeightedHeartRate",
                      ]

    public static func field(fitKey:String, activityType:String) -> GCField? {
        let fieldKey = fitToFieldMap[fitKey]
        if fieldKey == nil{
            print("Missing \(fitKey)")
            return nil
        }
        return GCField(forKey: fieldKey, andActivityType: activityType)
    }
}
