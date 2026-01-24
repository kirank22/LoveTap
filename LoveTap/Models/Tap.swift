//
//  Tap.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import Foundation

enum TapType: String, Codable {
    case quickTap
    case longTap
    case scheduledTap
}

struct Tap {
    let id: String // Using String to align with CKRecord.ID.recordName
    let type: TapType
    let pairId: String
    let senderId: String
    let createdAt: Date
}
