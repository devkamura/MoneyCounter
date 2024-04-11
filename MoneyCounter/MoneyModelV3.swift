//
//  MoneyModelV3.swift
//  MoneyCounter
//
//  Created by 嘉村勇輝 on 2023/07/01.
//

import Foundation
import RealmSwift

class MoneyModelV3: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var date: String = ""
    @objc dynamic var money: Int = 0
    @objc dynamic var deleted: Bool = false
}
