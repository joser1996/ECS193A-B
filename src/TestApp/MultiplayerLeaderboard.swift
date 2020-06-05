//
//  MultiplayerLeaderboard.swift
//  TestApp
//
//  Created by Jacob Smith on 6/4/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation

let BASE_SERVER_URL: String = "http://server162.site:59435"

//MARK: LeaderBoard Class
class MultiPlayerLeaderBoard: NSObject{
    
    //MARK: Properties
    
    var scoreBoard: [LeaderBoardCell] = []
    
    //MARK: Methods
    
    init(_ controller: LeaderBoardController! = nil) {
        super.init()
        self.loadLeaderBoard(controller)
    }
    
    func printScoreBoard() {
        for cell in scoreBoard {
            print(cell.teamName)
            print(cell.gameScore)
            print()
        }
    }
    
//    static func playerNamesString(_ cell: LeaderBoardCell) -> String {
//        let names = cell.teamName
//        let oneName = names.joined(separator: ", ")
//        return oneName
//    }
    
    static func setMultiplayerScore(gameId: Int, score: Int) {
        let url = URL(string: "\(BASE_SERVER_URL)/set-score/\(gameId)/\(score)")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
        }
    }
    
    func loadLeaderBoard(_ controller: LeaderBoardController! = nil) {
        let url = URL(string: "\(BASE_SERVER_URL)/get-scores")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            do {
                var cells: [LeaderBoardCell] = []
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    if let rows = json["rows"] as? [[String: Any]] {
                        for row in rows {
                            let score = row["final_score"] as? Int
                            let gameName = row["game_name"] as? String
                            
                            var players: [Player] = []
                            for i in 1...5 {
                                if let playerName = row["player\(i)_username"] as? String {
                                    players.append(Player(name: playerName))
                                }
                                else {
                                    break
                                }
                            }
                            
                            players[0].score = score!
                            let cell = LeaderBoardCell(players, gameName)
                            cells.append(cell)
                        }
                        
                        cells.sort(by: { $0.gameScore > $1.gameScore })
                    }
                    
                    self.scoreBoard = cells
                    
                    if let lbc = controller {
                        DispatchQueue.main.async {
                            lbc.leaderBoardTable.reloadData()
                        }
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
}
