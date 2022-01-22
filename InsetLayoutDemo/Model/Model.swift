//
//  Model.swift
//  InsetLayoutDemo
//
//  Created by iWw on 2022/1/22.
//

import UIKit

enum Section: String {
    case one
    case two
    case three
}

struct Item: Hashable {
    
    var id: IndexPath
    
    init(indexPath: IndexPath) {
        self.id = indexPath
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}
