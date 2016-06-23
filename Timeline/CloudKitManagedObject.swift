//
//  CloudKitManagedObject.swift
//  Timeline
//
//  Created by Emily Mearns on 6/22/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

@objc protocol CloudKitManagedObject {
    
    var timestamp: NSDate {get set}
    var recordIDData: NSData? {get set}
    var recordName: String {get set}
    var recordType: String {get}
    var cloudKitRecord: CKRecord? {get}
    
    init?(record: CKRecord, context: NSManagedObjectContext)
    
}

extension CloudKitManagedObject {
    
    var isSynced: Bool {
        return recordIDData != nil
    }
    
    var cloudKitRecordID: CKRecordID? {
        guard let recordIDData = recordIDData, let recordID = NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData) as? CKRecordID else {return nil}
        return recordID
    }
    
    var cloudKitReference: CKReference? {
        guard let cloudKitRecordID = cloudKitRecordID else {return nil}
        return CKReference(recordID: cloudKitRecordID, action: .None)
    }
    
    func update(record: CKRecord) {
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        
        let moc = Stack.sharedStack.managedObjectContext
        do {
            try moc.save()
        } catch {
            print("Updated record could not be saved")
        }
    }
    
    func nameForManagedObject() -> String {
        return NSUUID().UUIDString
    }
    
}