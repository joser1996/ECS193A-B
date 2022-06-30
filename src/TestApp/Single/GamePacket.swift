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
    var health: Int?
    var score: Int?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.action, forKey:"action")
        aCoder.encode(self.zombie, forKey:"zombie")
        aCoder.encode(self.health, forKey:"health")
        aCoder.encode(self.score, forKey:"score")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.action = aDecoder.decodeObject(forKey:"action") as? String
        self.zombie = aDecoder.decodeObject(forKey:"zombie") as? Zombie
        self.health = aDecoder.decodeObject(forKey:"health") as? Int
        self.score = aDecoder.decodeObject(forKey:"score") as? Int
    }
    
    init(zombie: Zombie? = nil, action: String? = nil, health: Int? = nil, score: Int? = nil) {
        self.action = action
        self.zombie = zombie
        self.health = health
        self.score = score
    }
}
