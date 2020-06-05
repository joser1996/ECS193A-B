//
//  LeaderBoard.swift
//  TestApp
//
//  Created by Jose Torres on 3/3/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import os.log

//MARK: LeaderBoardCell Class
class LeaderBoardCell: NSObject, NSCoding {
    
    
    //MARK: Properties
    var teamName: [String] = []
    var gameScore: Int = 0
    //MARK: Methods
    
    init(_ members: [Player]) {
        self.gameScore = 0
        for player in members {
            self.teamName.append(player.name)
            self.gameScore += player.score
        }
        
    }
    
    //MARK: ARCHIVING
    
    required init?(coder Decoder: NSCoder) {
        let tn = Decoder.decodeObject(forKey: LeaderBoardCellKeys.teamName) as! [String]
        
        let gs = Decoder.decodeInteger(forKey: LeaderBoardCellKeys.gameScore)
        
        self.teamName = tn
        self.gameScore = gs
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.teamName, forKey: LeaderBoardCellKeys.teamName)
        print("Encoding game score: \(self.gameScore)")
        coder.encode(self.gameScore, forKey: LeaderBoardCellKeys.gameScore)
    }
    
}
struct LeaderBoardCellKeys {
    static let teamName = "teamName"
    static let gameScore = "gameScore"
}



//MARK: LeaderBoard Class
class LeaderBoard: NSObject, NSCoding{
    
    
    //MARK: Properties
    
    var scoreBoard: [LeaderBoardCell] = []
    
    init(scoreBoard: [LeaderBoardCell]){
        self.scoreBoard = scoreBoard
    }

    //MARK: ARCHIVING
    required convenience init?(coder Decoder: NSCoder) {
        let sb = Decoder.decodeObject(forKey: LeaderBoardKeys.scoreBoard) as! [LeaderBoardCell]
        self.init(scoreBoard: sb)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(scoreBoard, forKey: LeaderBoardKeys.scoreBoard)
    }
    
    //MARK: Methods
    
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
    
    static func playerNamesString(_ cell: LeaderBoardCell) -> String {
        let names = cell.teamName
        let oneName = names.joined(separator: ", ")
        return oneName
    }
    
    static func saveLeaderBoard(leaderBoard: LeaderBoard) {
        do{
            let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
            let archiveURL = DocumentsDirectory.appendingPathComponent("leaderboard.bin")
            
            guard let scoreBoardData = try? NSKeyedArchiver.archivedData(withRootObject: leaderBoard, requiringSecureCoding: false)
                else{
                    fatalError("Couldn't encode scoreBoard")
            }
            print("Saving Leader board to \(archiveURL)")
            try scoreBoardData.write(to: archiveURL)
        } catch {
            print(error)
        }
    }
    
    static func loadLeaderBoard() -> LeaderBoard? {
        var returnVal: LeaderBoard? = nil
        do{
            let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
            let archiveURL = DocumentsDirectory.appendingPathComponent("leaderboard.bin")
            
            var sbReadData: NSData? = try? NSData(contentsOf: archiveURL, options: .mappedIfSafe)
            
            //If No data then create new leaderBoard
            if sbReadData == nil {
                print("No Leader Board Making New One")
                let cells: [LeaderBoardCell] = []
                let lb = LeaderBoard(scoreBoard: cells)
                LeaderBoard.saveLeaderBoard(leaderBoard: lb)
                
                sbReadData = try NSData(contentsOf: archiveURL, options: .mappedIfSafe)
            }
            
            if let sb = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(sbReadData! as Data) as? LeaderBoard {
                print("Loaded LeaderBoard")
                returnVal = sb
            }
        }catch {
            print(error)
        }
        return returnVal
    }
    
}

struct LeaderBoardKeys {
    static let scoreBoard = "scoreBoard"
}


