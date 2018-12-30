//
//  fit_message.swift
//  fittestswift
//
//  Created by Brice Rosenzweig on 19/12/2018.
//  Copyright © 2018 Brice Rosenzweig. All rights reserved.
//

import Foundation


class RZFitMessage {
    
    let messageType : RZFitMessageType
    private let values : [RZFitFieldKey:Double]
    private let enums : [RZFitFieldKey:String]
    
    var messageTypeDescription : String?{
        return rzfit_mesg_num_string(input: messageType)
    }

    private var cacheInterpretation : [RZFitFieldKey:RZFitFieldValue]
    
    init(mesg_num  : FIT_MESG_NUM, mesg_values : [RZFitFieldKey:Double], mesg_enums : [RZFitFieldKey:String]) {
        messageType = mesg_num
        values = mesg_values
        enums = mesg_enums
        cacheInterpretation = [:]
        
    }
    
    convenience init(mesg_num : FIT_MESG_NUM, withFitFields:[RZFitFieldKey:RZFitFieldValue]) {
        var ivalues : [RZFitFieldKey:Double] = [:]
        var ienums  : [RZFitFieldKey:String] = [:]
        
        for (key,field) in withFitFields {
            if let coord = field.coordinate{
                ivalues[ key + "_lat" ] = coord.latitude
                ivalues[ key + "_long" ] = coord.longitude
            }else if let d = field.value {
                ivalues[ key ] = d
            }else if let e = field.name {
                ienums[ key ] = e
            }else if let du = field.valueUnit {
                ivalues[ key ] = du.value
            }else if let da = field.time {
                // Fit file are in seconds since UTC 00:00 Dec 31 1989 = -347241600
                ivalues[ key ] = da.timeIntervalSinceReferenceDate+347241600
            }
        }
        self.init(mesg_num: mesg_num, mesg_values: ivalues, mesg_enums: ienums)
    }
    
    func interpretedFieldKeys() -> [RZFitFieldKey] {
        let interp = self.interpretedFields()
        var rv : [RZFitFieldKey] = []
        
        for (key,_) in interp {
            rv.append(key)
        }
        return rv
    }
    
    func interpretedField(key:RZFitFieldKey) -> RZFitFieldValue? {
        var interp = self.interpretedFields()
        
        return interp[key]
    }
    
    func interpretedFields() -> [RZFitFieldKey:RZFitFieldValue] {
        if self.cacheInterpretation.count > 0 {
            return self.cacheInterpretation
        }
        
        var rv :[String:RZFitFieldValue] = [:]
        
        for (key,val) in values {
            if( key.hasSuffix("_lat") ) {
                let lon = key.replacingOccurrences(of: "_lat", with: "_long")
                let newkey = key.replacingOccurrences(of: "_lat", with:"")
                let latitude = val * 180.0/2147483648.0 // SEMICIRCLE_TO_DEGREE
                if var longitude = values[lon] {
                    longitude = longitude * 180.0/2147483648.0 // SEMICIRCLE_TO_DEGREE
                    rv[ newkey ] = RZFitFieldValue(latitude: latitude, longitude: longitude)
                }
            }else if( key.hasSuffix( "_long") ){
                // handled by _lat
                continue
            }
            else if( key == "timestamp" || key == "start_time" || key == "local_timestamp"){
                // Fit file are in seconds since UTC 00:00 Dec 31 1989 = -347241600
                let date = Date(timeIntervalSinceReferenceDate: -347241600+val)
                rv[key] = RZFitFieldValue(withTime: date )
            }
            else if let unit = rzfit_unit_for_field(field: key) {
                rv[key] =  RZFitFieldValue(withValue: val, andUnit: unit)
            }else if( key == "product" ){
                let product_int : FIT_UINT16 = FIT_UINT16(val)
                if let mapped = rzfit_garmin_product_string(input: product_int ) {
                    rv[key] = RZFitFieldValue(withName:  mapped)
                }else{
                    rv[key] = RZFitFieldValue(withName: "\(product_int)")
                }
            }else if( key == "device_type" ){
                let device_type_int = FIT_UINT8(val)
                if let mapped = rzfit_antplus_device_type_string(input: device_type_int) {
                    rv[key] = RZFitFieldValue(withName: mapped)
                }else{
                    rv[key] = RZFitFieldValue(withName: "\(device_type_int)")
                }
            }else{
                rv[key] = RZFitFieldValue(withValue: val )
            }
        }
        
        for (key,val) in enums {
            rv[ key ] = RZFitFieldValue(withName: val )
        }
        self.cacheInterpretation = rv
        return self.cacheInterpretation
    }
    
    func description() -> String {
        var rv = [ "FitMessage(" ]
        if let name = self.messageTypeDescription {
            rv.append(name)
        }else{
            rv.append("Unknown")
        }
        rv.append(",")
        rv.append(",\(values.count),\(enums.count))")
        
        return rv.joined(separator: "")
    }
    
    func units() -> [RZFitFieldKey:String] {
        var rv : [String:String] = [:]
        
        for field in values.keys {
            if let unit = rzfit_unit_for_field(field: field) {
                rv[field] = unit
            }
        }
        return rv
    }
}
