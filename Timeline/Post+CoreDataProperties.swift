//
//  Post+CoreDataProperties.swift
//  Timeline
//
//  Created by Emily Mearns on 6/14/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Post {

    @NSManaged var photoData: NSData
    @NSManaged var comments: NSSet?

}
