//
//  GameSessionController.swift
//  TestApp
//
//  Created by Jacob Smith on 5/9/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class GameSessionController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startGame: UIButton!
    @IBOutlet weak var helpText: UILabel!
    
    let NUM_PLAYERS = 4
    let BASE_SERVER_URL = "http://server162.site:59435"
    let TIMER_LENGTH: Double = 3
    
    var isNewGame: Bool!
    var gameId: Int!
    var playerName: String!
    var gameSessionName: String!
    var playerNames: [String] = []
    var playerNameTimer: Timer!
    var gameStateTimer: Timer!
    var gameState: GameState! = GameState.Initial
    var client: ClientSide!
    var connectionIsAlive = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        client = ClientSide(gameID: gameId, name: playerName)
        
        fetchPlayerNames()
        
        gameName.text = gameSessionName
        if (isNewGame) {
            helpText.text = "Waiting for players to join..."
        }
        else {
            helpText.text = "Waiting for host to start game..."
            startGame.isHidden = true
            gameStateTimer = Timer.scheduledTimer(withTimeInterval: TIMER_LENGTH, repeats: true, block: { _ in
                self.checkGameState()
            })
        }
        
        playerNameTimer = Timer.scheduledTimer(withTimeInterval: TIMER_LENGTH, repeats: true, block: { _ in
            self.fetchPlayerNames()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NUM_PLAYERS
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameSessionCell") as! OnlineGameSessionTableCell
        let player = (index >= playerNames.count) ? "Empty" : playerNames[index]
        
        let text = "Player \(index + 1): \(player)"
        
        cell.label.text = text
           
        return cell
    }
    
    @objc func appMovedToBackground() {
        print("Moved to background")
        client.killClient()
        self.connectionIsAlive = false
    }
    
    @objc func appMovedToForeground() {
        if (!self.connectionIsAlive) {
            MusicPlayer.shared.stopSong()
            for controller in self.navigationController!.viewControllers as Array {
                if controller.isKind(of: FirstViewController.self) {
                    _ = self.navigationController!.popToViewController(controller, animated: false)
                }
            }
        }
    }
    
    @IBAction func sendStartGameSignal(_ sender: Any) {
            
        let url = URL(string: "\(self.BASE_SERVER_URL)/start-game/\(self.gameId!)/\(self.playerName!)")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                if (dataString == "Success") {
                    self.gameState = GameState.BasePlacing
                }
            }
            
            DispatchQueue.main.async{
                self.advanceToGame()
            }
        }
        task.resume()
    }
    
    
    func fetchPlayerNames() {

        let url = URL(string: "\(self.BASE_SERVER_URL)/host-check/\(self.gameId!)")
            
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    if let dict = json as? [String: Any] {
                        for i in 1...self.NUM_PLAYERS {
                            if let name = dict["player\(i)"] as? String {
                                if (i <= self.playerNames.count) {
                                    self.playerNames[i-1] = name
                                }
                                else {
                                    self.playerNames.append(name)
                                }
                            }
                            else {
                                break
                            }
                        }
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
        }
        task.resume()
    }
    
    func checkGameState() {

        let url = URL(string: "\(self.BASE_SERVER_URL)/game-state-check/\(self.gameId!)")
            
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            print("Data was recieved")
            
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                if let dict = json as? [String: Any] {
                    if let state = dict["gameState"] as? String {
                        switch state {
                        case "init":
                            self.gameState = GameState.Initial
                        case "bases":
                            self.gameState = GameState.BasePlacing
                        case "game":
                            self.gameState = GameState.ActiveGame
                        default:
                            self.gameState = nil
                        }
                    }
                }
                
                DispatchQueue.main.async{
                    if (self.gameState == GameState.BasePlacing) {
                        self.advanceToGame()
                    }
                }
                
                
            }catch{
                print("JSON error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func advanceToGame() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let gameVC = storyboard.instantiateViewController(withIdentifier: "OnlineGameVC") as! OnlineGameViewController
        
        gameVC.players = self.playerNames
        gameVC.gameID = self.gameId
        gameVC.playerName =  self.playerName
        if self.isNewGame {
            gameVC.isHost = true
        }
        gameVC.gameState = self.gameState
        
        self.playerNameTimer?.invalidate()
        self.gameStateTimer?.invalidate()
        
        self.navigationController!.pushViewController(gameVC, animated: true)
    }
}
