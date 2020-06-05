//
//  LeaderBoardController.swift
//  TestApp
//
//  Created by Jose Torres on 3/16/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit


class LeaderBoardController: UIViewController {

    @IBOutlet weak var singlePlayerButton: UIButton!
    @IBOutlet weak var MultiPlayerButton: UIButton!
    @IBOutlet weak var leaderBoardTable: UITableView!
    var isSinglePlayerVisible = true
    var leaderBoard: LeaderBoard?!
    var mpLeaderBoard: MultiPlayerLeaderBoard?!
    let SELECTED_COLOR = UIColor.black
    let UNSELECTED_COLOR = UIColor.systemGray4
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        singlePlayerButton.backgroundColor = SELECTED_COLOR
        MultiPlayerButton.backgroundColor = UNSELECTED_COLOR
        
        leaderBoardTable.delegate = self
        leaderBoardTable.dataSource = self
        leaderBoardTable.allowsSelection = false
        
        //Attempt to load a leader board
        print("Loading LeaderBoard")
        leaderBoard = LeaderBoard.loadLeaderBoard()
    }
    
    
    @IBAction func doneViewing(_ sender: UIButton) {
        print("Returing to home screen.")
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    @IBAction func toggleSinglePlayer(_ sender: Any) {
        isSinglePlayerVisible = true
        leaderBoard = LeaderBoard.loadLeaderBoard()
        DispatchQueue.main.async {
            self.leaderBoardTable.reloadData()
        }
    }
    
    @IBAction func toggleMultiPlayer(_ sender: Any) {
        isSinglePlayerVisible = false
        mpLeaderBoard = MultiPlayerLeaderBoard(self)
    }
}

extension LeaderBoardController: UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count: Int!
        if (isSinglePlayerVisible) {
            count = leaderBoard??.scoreBoard.count
        }
        else {
            count = mpLeaderBoard?.scoreBoard.count
        }
        
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var scoreboard: [LeaderBoardCell]?
        if (isSinglePlayerVisible) {
            scoreboard = self.leaderBoard??.scoreBoard
        }
        else {
            scoreboard = self.mpLeaderBoard?.scoreBoard
        }
        
        guard let sb = scoreboard else{
            fatalError("ScoreBoard was empty")
        }
        
        let lbCell = sb[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "leaderBoardCell") as! LeaderBoardViewCell
        
        let t = LeaderBoard.playerNamesString(lbCell)
        
        cell.setCell(team: t, score: lbCell.gameScore, gameName: lbCell.gameName)
        
        return cell
    }
    
}
