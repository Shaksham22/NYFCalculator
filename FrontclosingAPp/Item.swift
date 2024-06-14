//
//  Item.swift
//  FrontclosingAPp
//
//  Created by Shaksham Shubham on 2024-06-14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
