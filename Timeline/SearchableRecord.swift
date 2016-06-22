//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Emily Mearns on 6/22/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation

@objc protocol SearchableRecord {
    
    func matchesSearchTerm(searchTerm: String) -> Bool
    
}