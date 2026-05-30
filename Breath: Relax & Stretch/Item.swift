//
//  Item.swift
//  Breath: Relax & Stretch
//
//  Created by Jason Lu on 5/30/26.
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
