//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Emily Mearns on 6/14/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation

@objc protocol SearchableRecord: class {
    
    func matchesSearchTerm(searchTerm: String) -> Bool
    
}