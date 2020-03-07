//
//  Player.swift
//  TestApp
//
//  Created by Jose Torres on 2/29/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation

class Player {
    var name: String
    var isSelected: Bool    //Any other Plaer Attributes Here
    var score: Int
    
    
    init(name: String) {
        self.name = name
        self.isSelected = false
        self.score = 0
    }
    
    

}
