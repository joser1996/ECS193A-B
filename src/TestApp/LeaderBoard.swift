//
//  LeaderBoard.swift
//  TestApp
//
//  Created by Jose Torres on 3/3/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import os.log

class LeaderBoardCell {
    var teamName: [String] = []
    var gameScore: Int
    
    init(_ members: [Player]) {
        self.gameScore = 0
        for player in members {
            self.teamName.append(player.name)
            self.gameScore += player.score
        }
        
    }
    
}


//LeaderBoard must conform to NSCoding protocol
class LeaderBoard: NSObject, NSCoding{
    
    var scoreBoard:[LeaderBoardCell] = []

    init(scoreBoard: [LeaderBoardCell]) {
        self.scoreBoard = scoreBoard
    }

    
    func addToLeaderBoardMulti(_ players: [Player]) {
        
        if scoreBoard.count == 0 {
            scoreBoard.append(LeaderBoardCell(players))
        }
        else {
            scoreBoard.append(LeaderBoardCell(players))
            scoreBoard = scoreBoard.sorted(by: { $0.gameScore > $1.gameScore})
        }
        
    }
    
    func printScoreBoard() {
        for cell in scoreBoard {
            print(cell.teamName)
            print(cell.gameScore)
            print()
        }
        
    }
    
    
    //MARK: NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(scoreBoard, forKey: PropertyKey.scoreBoard)
    }
    
    
    required convenience init?(coder: NSCoder) {
        guard let sb = coder.decodeObject(forKey: PropertyKey.scoreBoard) as? [LeaderBoardCell] else {
            os_log("Unable to decode the leader board", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(scoreBoard: sb)
    }
}



struct PropertyKey {
    static let scoreBoard = "scoreBoard"
    
}
