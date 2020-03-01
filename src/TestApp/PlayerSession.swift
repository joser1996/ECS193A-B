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
    @IBOutlet weak var tableView: UITableView!
    
    var players: [Player] = []
    var previousVC: BasePlacementController!
    var mpService: MultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        mpService = previousVC.mcService
        players = makePlayerArray()
        tableView.allowsMultipleSelection = true
        
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
                tempArr.append(Player(name: peer.displayName))
            }
        }
        
        return tempArr
    }
}

extension PlayerSession: UITableViewDataSource, UITableViewDelegate {
    
    // number of rows to show
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //function called every time a new cell is created
        
        let player = players[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell") as! PlayerCell
        
        
        cell.setName(name: player.name)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        players[indexPath.row].isSelected = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        players[indexPath.row].isSelected = false
    }
    
}
