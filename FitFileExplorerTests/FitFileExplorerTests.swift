//
//  FitFileExplorerTests.swift
//  FitFileExplorerTests
//
//  Created by Brice Rosenzweig on 08/11/2016.
//  Copyright © 2016 Brice Rosenzweig. All rights reserved.
//

import XCTest
@testable import FitFileExplorer


class FitFileExplorerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFastFitFile() {
        let filenames = [ "activity_1378220136.fit", "activity_1382772474.fit" ]
        
        for filename in filenames {
            let decode = FITFitFileDecode(forFile:RZFileOrganizer.bundleFilePath(filename, for: type(of:self)))
            decode?.parse()
            
            
            if let fit = decode?.fitFile,
                let fastfit = RZFitFile(file: URL(fileURLWithPath: RZFileOrganizer.bundleFilePath(filename, for: type(of:self)))) {
                let origfit = RZFitFile(fitFile: fit)
                let fittypes = fit.allMessageTypes()
                let fasttypes = fastfit.messageTypes
                let rebuild = RZFitFile(fitFile: fit)
                XCTAssertNotNil(fasttypes)
                XCTAssertNotNil(fittypes)
                XCTAssertNotNil(rebuild)
                
                XCTAssertGreaterThan(origfit.messages.count, 0)
                
                if let fittypes = fittypes {
                    for mesgtype in fastfit.messageTypes{
                        let strmesgtype = fastfit.messageTypeDescription(messageType: mesgtype) ?? "ERROR"
                        XCTAssertTrue(fittypes.contains(strmesgtype))
                    }
                    for mesgtype in fittypes {
                        
                        if( mesgtype != "unknown"){
                            let fasttype = RZFitFile.messageType(forDescription: mesgtype) ?? FIT_MESG_NUM_INVALID
                            XCTAssertTrue(fasttypes.contains(fasttype))
                        }
                    }
                }
                
                for type in fastfit.messageTypes {
                    if let typeStr = rzfit_mesg_num_string(input: type){
                        let fastmessages = fastfit.messages(forMessageType: type)
                        if let fitmessages = fit.message(forType: typeStr){
                            XCTAssertEqual(Int(fitmessages.count()), fastmessages.count)
                            var diffs : Int = 0
                            for (offset,fields) in fastmessages.enumerated(){
                                if let rawfitfields = fitmessages.field(for: UInt(offset)),
                                    let fitfields = RZFitMessage( with: rawfitfields){
                                    let fastfields = fields.interpretedFields()
                                    let origfields = fitfields.interpretedFields()
                                    
                                    if( origfields.count != fastfields.count){
                                        diffs+=1
                                    }
                                }
                            }
                            if( diffs > 0){
                                print( "\(typeStr):\(diffs)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /*
    func testInterp() {
        //"activity_1378220136.fit"
        //"activity_1382772474.fit"
        
        if let manager = RZRegressionManager(forTest: type(of: self)) {
            manager.recordMode = false
            
            let filenames = [ "activity_1378220136.fit", "activity_1382772474.fit" ]
            
            for filename in filenames {
                let fit = RZFitFile(file: URL(fileURLWithPath: RZFileOrganizer.bundleFilePath(filename, for: type(of:self))))
                if let fit = fit {
                    let interpret = FITFitFileInterpret(fitFile: fit)
                    
                    let messages = fit.messages(forMessageType: FIT_MESG_NUM_SESSION)
                    let sumValues = interpret.summaryValues(fitMessage: messages[0])
                    //let retrieved = manager.retrieveReferenceObject(sumValues, selector: #selector(FitFileExplorerTests.testInterp), identifier: filename)
                    for (field,val) in sumValues {
                        print( " \"\(field)\":\"\(val)\"")
                    }
                    
                    if let laps = interpret.statsDataSerie(messageType: FIT_MESG_NUM_LAP, fieldX: "timestamp", fieldY: "avg_speed") {
                        print( "\(laps)")
                    }
                    if let records = interpret.statsDataSerie(messageType: FIT_MESG_NUM_RECORD, fieldX: "timestamp", fieldY: "speed") {
                        print( "\(records)")
                    }
                    
                    if let records = interpret.statsDataSerie(messageType: FIT_MESG_NUM_RECORD, fieldX: "heart_rate", fieldY: "speed") {
                        print( "\(records)")
                    }
                    let res = interpret.mapFields(from: fit., to: fit["lap"].allAvailableFieldKeys())
                    let res2 = interpret.mapFields(from: fit["lap"].allAvailableFieldKeys(), to: fit["record"].allAvailableFieldKeys())
                    print( "====\(res)")
                    print( "====\(res2)")
                    
                    _ = interpret.statsForMessage(message: "record", interval: nil)
                }
            }
        }else{
            XCTAssert(false, "Failed to access regression manager")
        }
    }
 */
    
    /*
    func testMapFields(){
        let filenames = [ "activity_1378220136.fit", "activity_1382772474.fit" ]
        
        for filename in filenames {
            let fit = RZFitFile(file: URL(fileURLWithPath:  RZFileOrganizer.bundleFilePath(filename, for: type(of:self))))
            
            if let fit = fit {
                let interpret = FITFitFileInterpret(fitFile: fit)
                
                if let messageSession = fit["session"], let messageLap = fit["lap"], let messageRecord = fit["record"]{
                    var mapped = interpret.mapFields(from: messageSession.allNumberKeys(), to: messageRecord.allNumberKeys())
                    
                    for (field,val) in mapped {
                        if val.count == 0{
                            print("session -> record \(field)");
                        }
                    }
                    mapped = interpret.mapFields(from: messageSession.allNumberKeys(), to: messageLap.allNumberKeys())
                    for (field,val) in mapped {
                        if val.count == 0{
                            print("session -> lap \(field)");
                        }
                    }
                    print("\(mapped.count)");
                    mapped = interpret.mapFields(from: messageRecord.allNumberKeys(), to: messageSession.allNumberKeys())
                    for (field,val) in mapped {
                        if val.count == 0{
                            print("record -> session \(field)");
                        }
                    }
                }
            }
        }
    }*/
    
    /*
    func testSelectionContext(){
        let filename = "activity_1378220136.fit"//, "activity_1382772474.fit" ]
        
        let decode = FITFitFileDecode(forFile:RZFileOrganizer.bundleFilePath(filename, for: type(of:self)))
        decode?.parse()

        if let fitFile = decode?.fitFile {
            let context = FITSelectionContext(fitFile: fitFile)
            context.push()
            context.selectedMessage = "record"
            context.push()
            XCTAssertEqual(context.queue.count, 2)
            context.push()
            XCTAssertEqual(context.queue.count, 2)
            XCTAssertEqual(context.selectedYField, "speed")
            XCTAssertEqual(context.selectedLocationField, "position")
            XCTAssertEqual(context.selectedXField, "timestamp")
            
            XCTAssertEqual(context.dependentMessage, "lap")
            XCTAssertEqual(context.dependentField, "avg_speed")
            context.dependentMessage = "session"
            XCTAssertEqual(context.dependentField, "avg_speed")
            
            // change index
            if let selectedYField = context.selectedYField,
                let val = context.selectedMessageFields![selectedYField]?.numberWithUnit{
                context.selectedMessageIndex = 10
                if let newval = context.selectedMessageFields![selectedYField]?.numberWithUnit{
                    XCTAssertNotEqual(newval, val)
                }
            }
            
            // change message
            let old = context.availableNumberFields()
            context.selectedMessage = "lap"
            let new = context.availableNumberFields()
            XCTAssertNotEqual(old.count, new.count)
            XCTAssertEqual(context.dependentMessage, "record")
            context.selectedYField = "avg_speed"
            XCTAssertEqual(context.dependentField, "speed")
            context.selectedYField = "max_speed"
            XCTAssertEqual(context.dependentField, "speed")
            context.selectedYField = "max_heart_rate"
            XCTAssertEqual(context.dependentField, "heart_rate")
            
        }
    }
    */
    
    func testExamples() {
        let filename = "DeveloperData.fit"
        let filepath = RZFileOrganizer.bundleFilePath(filename, for: type(of:self))
        
        
        let decode = FITFitFileDecode(forFile:filepath)
        decode?.parse()
        var done : Bool = false
        if let cppfit = decode?.fitFile,
            let cpprecords = cppfit["record"],
            let fastfit = RZFitFile(file: URL(fileURLWithPath:  filepath))
        {
            let fastrecords = fastfit.messages(forMessageType: FIT_MESG_NUM_RECORD)
            XCTAssertEqual(fastrecords.count, Int(cpprecords.count()))
            if let fastfirst = fastrecords.first,
                let cppfirst = cpprecords[0]{
                let fastkeys = fastfirst.preferredOrderFieldKeys()
                for one in cppfirst.allFieldNames(){
                    if (one != "enhanced_speed") { // dont understand why enhanced_speed not showing up
                        XCTAssertTrue( fastkeys.contains(one), "Missing \(one)" )
                    }
                }
                done = true
            }
        }
        XCTAssertTrue(done)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        
        //let filenames = [ "activity_1378220136.fit", "activity_1382772474.fit", "activity_2477200414.fit", "activity_2944936628.fit" ]
        let filenames = [ "activity_1378220136.fit",
                          "activity_1382772474.fit",
                          "activity_2477200414.fit",
                          //"activity_2944936628.fit",
                          "activity_2545022458.fit"
        ]
        let datas = filenames.map {
            try? Data(contentsOf: URL(fileURLWithPath: RZFileOrganizer.bundleFilePath($0, for: type(of:self))))
        }
        
        self.measure {
            for data in datas{
                if let data = data {
                    let fastfit = RZFitFile(data: data)
                    let records = fastfit.messages(forMessageType: FIT_MESG_NUM_RECORD)
                    XCTAssertGreaterThan(records.count, 0)
                }else{
                    XCTAssertTrue(false)
                }
            }
            
            if let one = datas.first, let data = one {
                let fastfit = RZFitFile(data: data)
                let records = fastfit.messages(forMessageType: FIT_MESG_NUM_RECORD)
                let interp = records.map {
                    $0.interpretedFields()
                }
                XCTAssertGreaterThan(interp.count, 0)
            }else{
                XCTAssertTrue(false)
            }

        }
    }
    
}
