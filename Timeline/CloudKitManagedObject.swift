//
//  CloudKitManagedObject.swift
//  Timeline
//
//  Created by Emily Mearns on 6/16/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

protocol CloudKitManagedObject {
    
    var timestamp: NSDate {get set}
    var recordIDData: NSData? {get set}
    var recordName: String {get set}
    var recordType: String {get}
    var cloudKitRecord: CKRecord? {get}
    
    func updateWithRecord(record: CKRecord)
    
}

extension CloudKitManagedObject {
    
    var isSynced: Bool {
        return recordIDData != nil
    }
    
    var cloudKitRecordID: CKRecordID? {
        guard let recordIDData = recordIDData else { return nil}
        
        
    }
    
}