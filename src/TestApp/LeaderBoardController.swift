//
//  LeaderBoardController.swift
//  TestApp
//
//  Created by Jose Torres on 3/16/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit


class LeaderBoardController: UIViewController {

    @IBOutlet weak var leaderBoardTable: UITableView!
    var leaderBoard: LeaderBoard?!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leaderBoardTable.delegate = self
        leaderBoardTable.dataSource = self
        
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
    
    

}

extension LeaderBoardController: UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var lb = leaderBoard?.scoreBoard.count
        if lb == nil{
            lb = 0
        }
        return lb!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let scoreArr = self.leaderBoard?.scoreBoard
        
        guard let sa = scoreArr else{
            fatalError("ScoreBoard was empty")
        }
        let lbCell = sa[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "leaderBoardCell") as! LeaderBoardViewCell
        
        let t = LeaderBoard.playerNamesString(lbCell)
        cell.setCell(team: t, score: lbCell.gameScore)
        
        
        return cell
    }
    
}
