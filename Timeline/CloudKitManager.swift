//
//  CloudKitManager.swift
//  Timeline
//
//  Created by Emily Mearns on 6/15/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class CloudKitManager {
    
    private let keyCreationDate = "creationDate"
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    
    init() {
        checkCloudKitAvailability()
        requestDiscoverabilityPermission()
    }
    
    // MARK: - User Info Discovery
    
    func fetchLoggedInUserRecord(completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler { (recordID, error) in
            if let error = error, let completion = completion {
                completion(record: nil, error: error)
            }
            if let recordID = recordID, let completion = completion {
                self.fetchRecordWithID(recordID, completion: { (record, error) in
                    completion(record: record, error: error)
                })
            }
        }
    }
    
    func fetchUsernameFromRecordID(recordID: CKRecordID, completion: ((firstName: String?, lastname: String?) -> Void)?) {
        let operation = CKDiscoverUserInfosOperation(emailAddresses: nil, userRecordIDs: [recordID])
        
        operation.discoverUserInfosCompletionBlock = { (emailsToUserInfos, userRecordsIDsToUserInfos, operationError) -> Void in
            if let userRecordsIDsToUserInfos = userRecordsIDsToUserInfos, let userInfo = userRecordsIDsToUserInfos[recordID], let completion = completion {
                completion(firstName: userInfo.displayContact?.givenName, lastname: userInfo.displayContact?.familyName)
            } else if let completion = completion {
                completion(firstName: nil, lastname: nil)
            }
        }
        CKContainer.defaultContainer().addOperation(operation)
    }
    
    func fetchAllDiscoverableUsers(completion: ((userInfoRecords: [CKDiscoveredUserInfo]?) -> Void)?) {
        let operation = CKDiscoverAllContactsOperation()
        
        operation.discoverAllContactsCompletionBlock = { (discoveredUserInfos, error) -> Void in
            if let completion = completion {
                completion(userInfoRecords: discoveredUserInfos)
            }
        }
        CKContainer.defaultContainer().addOperation(operation)
    }
    
    // MARK: - Fetch Records
    
    func fetchRecordWithID(recordID: CKRecordID, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        publicDatabase.fetchRecordWithID(recordID) { (record, error) in
            //Handle error
            if let completion = completion {
                completion(record: record, error: error)
            }
        }
    }
    
    func fetchRecordsWithType(type: String, predicate: NSPredicate = NSPredicate(value: true), recordFetchedBlock: ((record: CKRecord) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        let query = CKQuery(recordType: type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { (fetchedRecord) -> Void in
            fetchedRecords.append(fetchedRecord)
            if let recordFetchedBlock = recordFetchedBlock {
                recordFetchedBlock(record: fetchedRecord)
            }
        }
        
        queryOperation.queryCompletionBlock = { (queryCursor, error) -> Void in
            if let queryCursor = queryCursor {
                //more results in the cloud, go fetch them
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                continuedQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                self.publicDatabase.addOperation(continuedQueryOperation)
            } else {
                //finished getting results, only runs once
                if let completion = completion {
                    completion(records: fetchedRecords, error: error)
                }
            }
        }
        self.publicDatabase.addOperation(queryOperation)
    }
    
    func fetchCurrentUserRecords(type: String, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        fetchLoggedInUserRecord { (record, error) in
            //Handle error
            if let record = record {
                //search for all objects in cloud. taking in string and recordID. if they are equal.
                let predicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", record.recordID])
                self.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
                    //Handle error
                    if let completion = completion {
                        completion(records: records, error: error)
                    }
                })
            }
        }
    }
    
    func fetchRecordsFromDateRange(type: String, fromDate: NSDate, toDate: NSDate, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        let startDatePredicate = NSPredicate(format: "%K > %@", argumentArray: [keyCreationDate, fromDate])
        let endDatePredicate = NSPredicate(format: "%K < %@", argumentArray: [keyCreationDate, toDate])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, endDatePredicate])
        
        self.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil) { (records, error) in
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
    }
    
    // MARK: - Delete
    
    func deleteRecordWithID(recordID: CKRecordID, completion: ((recordID: CKRecordID?, error: NSError?) -> Void)?) {
        publicDatabase.deleteRecordWithID(recordID) { (recordID, error) in
            if let completion = completion {
                completion(recordID: recordID, error: error)
            }
        }
    }
    
    func deleteRecordsWithID(recordIDs: [CKRecordID], completion: ((records: [CKRecord]?, recordIDs: [CKRecordID]?, error: NSError?) -> Void)?) {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.queuePriority = .High
        operation.savePolicy = .IfServerRecordUnchanged
        operation.qualityOfService = .UserInitiated
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            if let completion = completion {
                completion(records: records, recordIDs: recordIDs, error: error)
            }
        }
        //runs on all devices
        publicDatabase.addOperation(operation)
    }
    
    // MARK: - Save & Modify
    
    func saveRecords(records: [CKRecord], perRecordCompletion: ((record: CKRecord?, error: NSError?) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        modifyRecords(records, perRecordCompletion: perRecordCompletion) { (records, error) in
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
    }
    
    func saveRecord(record: CKRecord, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        publicDatabase.saveRecord(record) { (record, error) in
            if let completion = completion {
                completion(record: record, error: error)
            }
        }
    }
    
    func modifyRecords(records: [CKRecord], perRecordCompletion: ((record: CKRecord?, error: NSError?) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.queuePriority = .High
        operation.savePolicy = .ChangedKeys
        operation.qualityOfService = .UserInteractive
        
        operation.perRecordCompletionBlock = { (record, error) -> Void in
            if let perRecordCompletion = perRecordCompletion {
                perRecordCompletion(record: record, error: error)
            }
        }
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
        
        publicDatabase.addOperation(operation)
    }
    
    // MARK: - CloudKit Permissions
    
    func checkCloudKitAvailability() {
        CKContainer.defaultContainer().accountStatusWithCompletionHandler { (accountStatus: CKAccountStatus, error: NSError?) in
            switch accountStatus {
            case .Available:
                print("Account is available")
            default:
                self.handleCloudKitUnavailable(accountStatus, error: error)
            }
        }
    }
    
    func handleCloudKitUnavailable(accountStatus: CKAccountStatus, error: NSError?) {
        var errorText = "Sync is disabled. \n"
        if let error = error {
            errorText += error.localizedDescription
        }
        switch accountStatus {
        case .Restricted:
            errorText += "iCloud is not available due to restrictions."
        case .NoAccount:
            errorText += "There is no iCloud account set up."
        default:
            break
        }
        displayCloudKitNotAvailableError(errorText)
    }
    
    func displayCloudKitNotAvailableError(errorText: String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alertController = UIAlertController(title: "iCloud Sync Error", message: errorText, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            
            if let appDelegate = UIApplication.sharedApplication().delegate, let appWindow = appDelegate.window!, let rootViewController = appWindow.rootViewController {
                rootViewController.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - CloudKit Discoverability
    
    func requestDiscoverabilityPermission() {
        CKContainer.defaultContainer().statusForApplicationPermission(.UserDiscoverability) { (permissionStatus, error) in
            if permissionStatus == .InitialState {
                CKContainer.defaultContainer().requestApplicationPermission(.UserDiscoverability, completionHandler: { (permissionStatus, error) in
                    self.handleCloudKitPermissionStatus(permissionStatus, error: error)
                })
            } else {
                self.handleCloudKitPermissionStatus(permissionStatus, error: error)
            }
        }
    }
    
    func handleCloudKitPermissionStatus(permissionStatus: CKApplicationPermissionStatus, error: NSError?) {
        if permissionStatus == .Granted {
            print("User Discoverability permission granted. User may proceed with full access.")
        } else {
            var errorText = "Sync is disabled \n"
            if let error = error {
                errorText += error.localizedDescription
            }
            switch permissionStatus {
            case .Denied:
                errorText += "You have denied User Discoverability permissions. You may be unable to use certain features that require User Discoverability."
            case .CouldNotComplete:
                errorText += "Unable to verify User Discoverability permissions. You may have a connectivity issue. Please try again."
            default:
                break
            }
            displayCloudKitNotAvailableError(errorText)
        }
    }
    
    func displayCloudKitPermissionNotGrantedError(errorText: String) {
        dispatch_async(dispatch_get_main_queue(), {
            let alertController = UIAlertController(title: "CloudKit Permissions Error", message: errorText, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            
            if let appDelegate = UIApplication.sharedApplication().delegate, let appWindow = appDelegate.window!, let rootViewController = appWindow.rootViewController {
                rootViewController.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
    
    
}









