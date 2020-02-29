//
//  PlayerSession.swift
//  TestApp
//
//  Created by Jose Torres on 2/29/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class PlayerSession: UIViewController {

    @IBOutlet weak var playerTableView: UITableView!
    
    var players: [Player] = []
    var previousVC: BasePlacementController!
    var mpService: MultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mpService = previousVC.mcService
        players = makePlayerArray()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    
    func makePlayerArray() -> [Player] {
        var tempArr: [Player] = []
        
        //populate array here
        let peers = mpService.connectedPeers
        if !peers.isEmpty {
            for peer in peers {
                tempArr.append(Player(name: peer))
            }
        }
        
        return tempArr
    }
}

