//
//  SwiftyDBTests.swift
//  SwiftyDBTests
//
//  Created by zouxu on 13/6/16.
//  Copyright © 2016 team.bz. All rights reserved.
//


@testable import SwiftyDB
import Quick
import Nimble

class SwiftXDbMutiThread: SwiftyDBSpec {
    override func spec() {
        super.spec()
        let database = SwiftXDbReset(databaseName: "test_database")
        describe("Data in database is updated") {
            context("object added test sample data") {
                it("only muti thread add, add in a queue") {
                    var dataOrg : Set<Int> = []
                    let maxItem = 1000
                    var doneCount : Int32 = 0
                    let curRunloop = CFRunLoopGetCurrent()
                    for i in 0..<maxItem{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        object.num = NSNumber(value:i)
                        dataOrg.insert(Int(object.primaryKey))
                        DispatchQueue.global().async{
                            let done = OSAtomicAdd32(Int32(1), &doneCount)
                            Swift.print("add start: \(done)")
                            database.transaction({(db:SwiftyDb) in
                                expect(db.addObject(object, true).isSuccess).to(beTrue())
                                expect(db.addObject(object, true).isSuccess).to(beTrue())
                            })
                            Swift.print("add done: \(done)")
                            if done == Int32(maxItem){
                                CFRunLoopStop(curRunloop)
                            }
                        }
                    }
                    CFRunLoopRun();
                    expect(database.dataFor(TestClassSimple()).value?.count) == maxItem
                    let items = database.objectsFor(TestClassSimple()).value
                    let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
                    expect(names == dataOrg) == true
                }
                
                
                it("only muti thread get, get not in queue") {
                    var dataOrg : Set<Int> = []
                    let maxItem = 1000
                    var doneCount : Int32 = 0
                    let curRunloop = CFRunLoopGetCurrent()
                    for i in 0..<maxItem{
                        let object = TestClassSimple()
                        object.primaryKey = NSNumber(value:i)
                        // object.num = NSNumber(value:i)
                        dataOrg.insert(Int(object.primaryKey))
                        DispatchQueue.global().async{
                            let done = OSAtomicAdd32(Int32(1), &doneCount)
                            Swift.print("get start: \(done)")
                            let filter = Filter.equal("primaryKey", value:object.primaryKey)
                            let ret = database.objectsFor(object, filter)
                            expect(ret.isSuccess).to(beTrue())
                            expect(ret.value?.count) == 1
                            expect(ret.value?[0].num) == object.primaryKey
                            expect(database.objectsFor(object).isSuccess).to(beTrue())
                            Swift.print("get done: \(done)")
                            if done == Int32(maxItem){
                                CFRunLoopStop(curRunloop)
                            }
                        }
                    }
                    CFRunLoopRun();
                    expect(database.dataFor(TestClassSimple()).value?.count) == maxItem
                    let items = database.objectsFor(TestClassSimple()).value
                    let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
                    expect(names == dataOrg) == true
                }
                
                
                it("muti thread get and add") {
                    var dataOrg : Set<Int> = []
                    let maxItem = 1000
                    var addDoneCount : Int32 = 0
                    var getDoneCount : Int32 = 0
                    let curRunloop = CFRunLoopGetCurrent()
                    for i in 0..<maxItem{
                        let read = true
                        let write = true
                        
                        if read{
                            let object = TestClassSimple()
                            object.primaryKey = NSNumber(value:i)
                            dataOrg.insert(Int(object.primaryKey))
                            
                            DispatchQueue.global().async{
                                let done = OSAtomicAdd32(Int32(1), &getDoneCount)
                                Swift.print("get start: \(done)")
                                let filter = Filter.equal("primaryKey", value:object.primaryKey)
                                let ret = database.objectsFor(object, filter)
                                expect(ret.isSuccess).to(beTrue())
                                expect(ret.value?.count) == 1
                                expect(ret.value?[0].num) == object.primaryKey
                                expect(database.objectsFor(object).isSuccess).to(beTrue())
                                Swift.print("get done: \(done)")
                                if done == Int32(maxItem){
                                    CFRunLoopStop(curRunloop)
                                }
                            }
                        }
                        
                        if write{
                            let iii = 2000+i
                            let object = TestClassSimple()
                            object.primaryKey = NSNumber(value:iii)
                            object.num = NSNumber(value:iii)
                            dataOrg.insert(Int(object.primaryKey))
                            DispatchQueue.global().async{
                                let done = OSAtomicAdd32(Int32(1), &addDoneCount)
                                Swift.print("add start: \(done)")
                                database.transaction({(db:SwiftyDb) in
                                    expect(db.addObject(object, true).isSuccess).to(beTrue())
                                    expect(db.addObject(object, true).isSuccess).to(beTrue())
                                })
                                Swift.print("add done: \(iii)")
                                if done == Int32(maxItem){
                                    CFRunLoopStop(curRunloop)
                                }
                            }
                        }
                    }
                    CFRunLoopRun();
                    expect(database.dataFor(TestClassSimple()).value?.count) == maxItem*2
                    let items = database.objectsFor(TestClassSimple()).value
                    let names : Set<Int> = Set(items!.map{Int($0.primaryKey)})
                    expect(names == dataOrg) == true
                }
            }
        }
    }
}

































