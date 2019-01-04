//  MIT License
//
//  Created on 25/12/2018 for ConnectStats
//
//  Copyright (c) 2018 Brice Rosenzweig
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



import Foundation

extension RZFitFile {
    
    convenience init(fitFile file: FITFitFile){
        var messages :[RZFitMessage] = []
        
        for one in file.allMessageFields() {
            if let field = RZFitMessage(with: one) {
                messages.append(field)
            }
        }
        
        self.init(messages: messages)
    }
    
    func preferredMessageType() -> RZFitMessageType {
        let preferred = [ FIT_MESG_NUM_SESSION, FIT_MESG_NUM_RECORD, FIT_MESG_NUM_FILE_ID]
        for one in preferred {
            if self.messageTypes.contains(one) {
                return one
            }
        }
        return FIT_MESG_NUM_FILE_ID
    }
    
    func orderedMessageTypes() -> [RZFitMessageType] {
        return self.messageTypes
        /*
        let count = self.countByMessageType()
        let fields = Array( self.messageTypes)
        
        return fields.sorted {
            if let l = count[$0], let r = count[$1] {
                return l < r
            }
            return false
        }*/
    }
    
    func orderedFieldKeys(messageType: RZFitMessageType) -> [RZFitFieldKey] {
        
        let all = Array(self.fieldKeys(messageType:messageType))
        let samples = self.sampleValues(messageType: messageType)
        
        let typeOrder = [  RZFitFieldValue.ValueType.time,
                           RZFitFieldValue.ValueType.coordinate,
                           RZFitFieldValue.ValueType.name,
                           RZFitFieldValue.ValueType.valueUnit,
                           RZFitFieldValue.ValueType.value,
                           RZFitFieldValue.ValueType.invalid
            ]
        
        var byType : [RZFitFieldValue.ValueType:[RZFitFieldKey]] = [:]
        for type in typeOrder{
            byType[type] = []
        }
        
        for key in all {
            if let val = samples[key] {
                byType[val.one.type]?.append(key)
            }else{
                byType[RZFitFieldValue.ValueType.invalid]?.append(key)
            }
        }
        
        var rv : [RZFitFieldKey] = []
        for type in typeOrder {
            if let keys = byType[type] {
                let orderedKeys = keys.sorted {
                    if let l = samples[$0], let r = samples[$1] {
                        return r.count < l.count
                    }
                    return false
                }
                rv.append(contentsOf: orderedKeys)
            }
        }
        
        return rv
    }
    
}
