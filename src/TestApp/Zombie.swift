//
//  Zombie.swift
//  TestApp
//
//  Created by Jacob Smith on 3/14/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import SceneKit

class Zombie: NSObject, NSCoding {
    var name: String?
    var health: Int?
    var maxHealth: Int?
    var node: SCNNode?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey:"name")
        aCoder.encode(self.health, forKey:"health")
        aCoder.encode(self.maxHealth, forKey:"maxHealth")
        aCoder.encode(self.node, forKey:"node")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey:"name") as? String
        self.health = aDecoder.decodeObject(forKey:"health") as? Int
        self.maxHealth = aDecoder.decodeObject(forKey:"maxHealth") as? Int
        self.node = aDecoder.decodeObject(forKey:"node") as? SCNNode
    }
    
    init(name: String, health: Int, node: SCNNode) {
        self.name = name
        self.health = health
        self.maxHealth = health
        self.node = node
    }
}

