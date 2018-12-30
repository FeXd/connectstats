//
//  FITSelectionContext.swift
//  GarminConnect
//
//  Created by Brice Rosenzweig on 28/11/2016.
//  Copyright © 2016 Brice Rosenzweig. All rights reserved.
//

import Foundation

class FITSelectionContext {
    
    
    static let kFITNotificationConfigurationChanged = Notification.Name( "kFITNotificationConfigurationChanged" )
    static let kFITNotificationMessageChanged       = Notification.Name( "kFITNotificationMessageChanged" )
    static let kFITNotificationFieldChanged         = Notification.Name( "kFITNotificationFieldChanged" )

    // MARK: - Stored Properties
    
    /// Selected numbers fields in order, lastObject is latest
    fileprivate var selectedNumberFields : [RZFitFieldKey] = []
    /// Selected location fields in order, lastObject is latest
    fileprivate var selectedLocationFields : [RZFitFieldKey] = []
    
    let fitFile : RZFitFile
    
    var speedUnit : GCUnit = GCUnit.kph()
    var distanceUnit : GCUnit = GCUnit.meter()
    
    var enableY2 : Bool = false
    var prettyField : Bool = false;
    
    var queue : [FITSelectionContext] = []
    
    var selectedMessageTypeDescription : String {
        if let type = self.fitFile.messageTypeDescription(messageType: self.selectedMessageType) {
            return type
        }else{
            return "Unknown Message Type"
        }
    }
    var selectedMessageType: RZFitMessageType {
        didSet{
            // If new message does not exist, do nothing
            // else update with some defaults
            if fitFile.hasMessageType(messageType: selectedMessageType) {
                self.selectedMessageType = oldValue;
            }else{
                if(selectedMessageType != oldValue){
                    self.updateWithDefaultForCurrentMessageType()
                }
            }
        }
    }
    lazy var interp : FITFitFileInterpret = FITFitFileInterpret(fitFile: self.fitFile)

    /// Last few selected Fields
    var selectedMessageIndex : Int = 0 {
        didSet {
            if selectedMessageIndex >= self.messages.count {
                selectedMessageIndex = 0;
            }
        }
    }
    var selectedXField : RZFitFieldKey = "timestamp"

    var preferredDependendMessage : [RZFitMessageType] = [FIT_MESG_NUM_RECORD, FIT_MESG_NUM_LAP, FIT_MESG_NUM_SESSION]
    var dependentMessage : RZFitMessageType?
    
    var statsFor : RZFitMessageType? {
        get {
            return dependentMessage
        }
        set {
            dependentMessage = newValue
        }
    }
    
    //MARK: - Computed Properties
    
    var selectedMessage :RZFitMessage? {
        let useIdx = self.selectedMessageIndex < self.messages.count ? self.selectedMessageIndex : 0
        var rv : RZFitMessage?
        
        if useIdx < messages.count {
            rv = messages[useIdx]
        }
        return rv
    }

    var selectedYField :RZFitFieldKey? {
        get {
            return self.selectedNumberFields.last
        }
        set {
            if let val = newValue {
                if self.selectedNumberFields.count > 0 {
                    self.selectedNumberFields[self.selectedNumberFields.count-1] = val
                }else{
                    self.selectedNumberFields.append(val)
                }
            }
        }
    }

    var selectedY2Field :RZFitFieldKey? {
        get {
            let cnt = self.selectedNumberFields.count
            return cnt > 1 ? self.selectedNumberFields[cnt-2] : nil
        }
        set {
            if let val = newValue {
                let cnt = self.selectedNumberFields.count
                if cnt > 1 {
                    self.selectedNumberFields[cnt-2] = val
                }else if( cnt > 0){
                    self.selectedNumberFields.insert(val, at: 0)
                }
            }
        }
    }
    
    var selectedLocationField :RZFitFieldKey?{
        get {
            return self.selectedLocationFields.last
        }
        set {
            if let val = newValue {
                if self.selectedLocationFields.count > 0 {
                    self.selectedLocationFields[self.selectedLocationFields.count-1] = val
                }else{
                    self.selectedLocationFields.append(val)
                }
            }
        }
    }

    var messages :[RZFitMessage] {
        return self.fitFile.messages(forMessageType: self.selectedMessageType)
    }
    
    var dependentField :RZFitFieldKey? {
        var rv : RZFitFieldKey? = nil
        if let dmessagetype = self.dependentMessage,
            let fy = self.selectedYField{
            let dmessage = self.fitFile.messages(forMessageType: dmessagetype)
            // check first if yfield exist in dependent
            if let first = dmessage.first {
                if first.numberWithUnit(field: fy) != nil {
                    rv = self.selectedYField
                } else if let f = self.interp.mapFields(from: [fy], to: first.interpretedFieldKeys())[fy]{
                    if f.count > 0 {
                        rv = f[0]
                    }
                }
            }
        }
        return rv
    }
    
    // MARK: Initialization and Queue management
    

    init(fitFile:RZFitFile){
        self.fitFile = fitFile;
        self.selectedMessageType = self.fitFile.preferredMessageType()
        updateDependent()
    }
    
    init(withCopy other:FITSelectionContext){
        self.fitFile = other.fitFile
        self.selectedMessageType = other.selectedMessageType
        self.enableY2 = other.enableY2
        self.distanceUnit = other.distanceUnit
        self.speedUnit = other.speedUnit
        self.prettyField = other.prettyField
        self.selectedXField = other.selectedXField
        self.selectedLocationFields = other.selectedLocationFields
        self.selectedNumberFields = other.selectedNumberFields
        //self.dependentField = other.dependentField
        self.dependentMessage = other.dependentMessage
        self.preferredDependendMessage = other.preferredDependendMessage
        
    }
    
    func push(){
        if queue.count == 0 || queue.last != self{
            let saved = FITSelectionContext(withCopy:self)
            queue.append(saved)
        }
    }
    
    // MARK: - change selection
    
    func notify(){
        NotificationCenter.default.post(name: FITSelectionContext.kFITNotificationConfigurationChanged, object: nil)
    }

    /// Update selection for index and record if number or location field selected
    func selectMessageField(field:RZFitFieldKey, atIndex idx: Int){
        let messages = self.messages
        
        let useIdx = idx < messages.count ? idx : 0
        
        if useIdx < messages.count {
            self.selectedMessageIndex = useIdx
            if let message = self.selectedMessage{
                if message.numberWithUnit(field: field) != nil{
                    selectedNumberFields.append(field)
                }else if( message.coordinate(field: field) != nil){
                    selectedLocationFields.append(field)
                }
            }
        }
    }
    
    private func updateDependent(){
        for one in self.preferredDependendMessage {
            if one != self.selectedMessageType && self.fitFile.messages(forMessageType: one).count != 0{
                self.dependentMessage = one
                break
            }
        }
    }
    
    /// Setup fields if new message selected
    private func updateWithDefaultForCurrentMessageType(){
        selectedMessageIndex = 0
        selectedNumberFields = []
        if let first = self.selectedMessage?.fieldKeysWithNumberWithUnit().first{
            selectedNumberFields.append(first)
        }
        selectedLocationFields = []
        if let first = self.selectedMessage?.fieldKeysWithCoordinate().first{
            selectedLocationFields.append(first)
        }
        if( selectedXField == "timestamp" && self.selectedMessage?.time(field: "start_time") != nil){
            selectedXField = "start_time"
        }else if( self.selectedMessage?.time(field: selectedXField) == nil){
            selectedXField = "timestamp"
        }
        self.updateDependent()
    }
    
    // MARK: - Display
    
    /// Convert to relevant unit or just description
    ///
    /// - Parameter fieldValue: value to display
    /// - Returns: string
    func display( fieldValue : RZFitFieldValue) -> String {
        if let nu = fieldValue.numberWithUnit {
            for unit in [self.speedUnit, self.distanceUnit] {
                if nu.unit.canConvert(to: unit) {
                    return nu.convert(to: unit).description
                }
            }
        }
        return fieldValue.displayString()
    }
    
    func display( numberWithUnit nu: GCNumberWithUnit) -> String{
        for unit in [self.speedUnit, self.distanceUnit] {
            if nu.unit.canConvert(to: unit) {
                return nu.convert(to: unit).description
            }
        }
        return nu.description;
    }
    
    func displayField( fieldName : String ) -> NSAttributedString {
        var displayText = fieldName
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        var attr = [ NSAttributedString.Key.font:NSFont.systemFont(ofSize: 12.0),
                     NSAttributedString.Key.foregroundColor:NSColor.black,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        if self.prettyField {
            if let field = self.interp.fieldKey(fitField: fieldName){
                displayText = field.displayName()
            }else{
                attr = [NSAttributedString.Key.font:NSFont.systemFont(ofSize: 12.0),
                        NSAttributedString.Key.foregroundColor:NSColor.lightGray,
                        NSAttributedString.Key.paragraphStyle:paragraphStyle]
            }
        }
        return NSAttributedString(attr, with: displayText)
    }
    
    // MARK: - Extract Information about current selection
    
    func availableNumberFields() -> [String] {
        if let message = self.selectedMessage {
            return message.fieldKeysWithNumberWithUnit()
        }
        return []
    }
    func availableDateFields() -> [String] {
        if let message = self.selectedMessage {
            return message.fieldKeysWithTime()
        }
        return []
    }

}

extension FITSelectionContext: Equatable {
    static func ==(lhs: FITSelectionContext, rhs: FITSelectionContext) -> Bool {
        return lhs.selectedNumberFields == rhs.selectedNumberFields && lhs.selectedLocationFields == rhs.selectedLocationFields
    }
}
