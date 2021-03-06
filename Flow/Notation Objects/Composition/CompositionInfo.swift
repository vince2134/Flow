//
//  CompositionInfo.swift
//  Flow
//
//  Created by Kevin Chan on 05/12/2017.
//  Copyright © 2017 MusicG. All rights reserved.
//

import Foundation

struct CompositionInfo: Codable, Equatable {
    var name: String
    var lastEdited: Date
    var id: String

    var lastEditedString: String {
        return lastEdited.toString(withFormat: "E, MMM d, yyyy h:mm a")
    }
    
    init(name: String = "Untitled Composition", lastEdited: Date = Date(), id: String = UUID().uuidString) {
        self.name = name
        self.lastEdited = lastEdited
        self.id = id
    }
    
    static func == (lhs: CompositionInfo, rhs: CompositionInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func != (lhs: CompositionInfo, rhs: CompositionInfo) -> Bool {
        return lhs.id != rhs.id
    }
}
