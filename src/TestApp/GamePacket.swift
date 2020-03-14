//
//  GamePacket.swift
//  TestApp
//
//  Created by Jacob Smith on 3/14/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation

class GamePacket: NSObject, NSCoding {
    
    var zombie: Zombie?
    var action: String?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.action, forKey:"action")
        aCoder.encode(self.zombie, forKey:"zombie")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.action = aDecoder.decodeObject(forKey:"action") as? String
        self.zombie = aDecoder.decodeObject(forKey:"zombie") as? Zombie
    }
    
    init(zombie: Zombie? = nil, action: String? = nil) {
        self.action = action
        self.zombie = zombie
    }
}
