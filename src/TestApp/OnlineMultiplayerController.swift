//
//  OnlineMultiplayerController.swift
//  TestApp
//
//  Created by Jose Torres on 4/11/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

enum GameState {
    case BasePlacing
    case Initial
    case WaitingForGame
    case ActiveGame
}


class OnlineMultiplayerController: UIViewController {

    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var gameIDLabel: UILabel!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var hostGameButton: UIButton!
    @IBOutlet weak var joinGameButton: UIButton!
    @IBOutlet weak var gameIDButton: UIButton!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    
    
    let urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    let server: String = "http://server162.site:59435"
    var gameID: Int?
    var didConnect: Bool = false
    var playersInLobby: [String] = ["", "", "", ""]
    var timer = Timer()
    var nameEntered: Bool = false
    var idEntered: Bool = false
    var playerName: String?
    var isHost: Bool = false
    var gameState: GameState = GameState.Initial
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MusicPlayer.shared.stopBackgroundMusic()
        
        self.notificationLabel.isHidden = true
        self.hostGameButton.isEnabled = false
        self.joinGameButton.isEnabled = false
        self.gameIDButton.isEnabled = false
        self.startButton.isHidden = true
        self.startButton.isEnabled = false
    }
    
    @IBAction func enterNameAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter Name", message: "Please type in your desired display name", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) {
            (_) in
            guard let name = alertController.textFields?[0].text else {
                self.playerName = nil
                return
                
            }
            self.playerLabel.text = "Players: " + name
            self.nameEntered = true
            self.playerName = name
            
            self.hostGameButton.isEnabled = true
            self.joinGameButton.isEnabled = true
            self.gameIDButton.isEnabled = true
            self.nameButton.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) in }
        
        alertController.addTextField {(textField) in
            textField.placeholder = "Enter Name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func enterGameIDAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Enter the Game ID", message: "Please enter the Game Session ID", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default){
            (_) in
            guard let id = alertController.textFields?[0].text else{
                self.gameID = nil
                return
            }
            self.gameID = Int(id)
            //print("Game ID is: \(self.gameID)")
            self.gameIDLabel.text = "Game ID: \(self.gameID!)"
            self.idEntered = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) in }
        
        alertController.addTextField{(textField) in
            textField.placeholder = "Enter Game ID"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    //silent push notifications
    //Orientation
    //Reward System
    @IBAction func hostGameRequest(_ sender: UIButton) {
        if !nameEntered {
            print("No Name was entered")
            return
        }
        
        guard let name = self.playerName else {return}
        
        let endPoint = "/host-request/" + name
        
        let gameName = "game37"
        let pass = "pass37"
        let urlString = server + endPoint + "/" + gameName + "/" + pass
        guard let url = URL(string: urlString) else {return}

        let hostReqTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)

                if let dict = json as? [String: Any] {
                    if let id = dict["gameId"] as? Int {
                        self.gameID = id
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                if self.gameID != nil{
                    self.gameIDLabel.text = "GameID is \(self.gameID!)"
                    self.hostGameButton.isEnabled = false
                    self.joinGameButton.isEnabled = false
                    self.gameIDButton.isEnabled = false
                    self.isHost = true
                    self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
                }

            }
        }

        hostReqTask.resume()
    }
    
    @IBAction func joinGameReq(_ sender: UIButton) {
        guard let gameID = self.gameID else {
            print("Invalid Game ID")
            return
            
        }
        
        guard let name = self.playerName else {
            print("Invalide Name")
            return
        }
        
        let endPoint = "/join/" + String(gameID) + "/" + name
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let joinReqTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                if let dict = json as? [String: Any] {
                    if let confirmation = dict["didConnect"] as? Bool {
                        self.didConnect = confirmation
                    }
                }
            }catch{
                print("JSON error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if self.didConnect {
                    self.joinGameButton.isEnabled = false
                    self.hostGameButton.isEnabled = false
                    self.gameIDButton.isEnabled = false
                    self.notificationLabel.text = "Connected to server!"
                    self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
                }
            }
            
        }
        joinReqTask.resume()
    }
    

    
    @objc func checkForUpdate() {
        playerNameUpdateTask()
        checkGameState()
    }
    
    func checkGameState() {
        print("In checkGameState")
        guard let gameID = self.gameID else {return}
        
        let endPoint = "/game-state-check/"
        guard let url = URL(string: server + endPoint + String(gameID)) else {return}
        
        if self.gameState == GameState.BasePlacing {
            self.startButton.isHidden = false
            self.startButton.isEnabled = true
        }
        
        let checkGameStateTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
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
                        if(state == "bases"){
                            if self.gameState != GameState.BasePlacing{
                                self.gameState = GameState.BasePlacing
                            }
                        }
                    }
                }
            }catch{
                print("JSON error: \(error.localizedDescription)")
            }
        }
        checkGameStateTask.resume()
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameVC = segue.destination as? OnlineGameViewController {
            gameVC.players = self.playersInLobby
            gameVC.gameID = self.gameID
            gameVC.playerName =  self.playerName
            print("Invalidate Timer")
            self.timer.invalidate()
            if self.isHost {
                gameVC.isHost = true
            }
            gameVC.gameState = self.gameState
        }
    }
    

    
    func playerNameUpdateTask() {
        guard let gameID = self.gameID else{return}
        let endPoint = "/host-check/" + String(gameID)
        guard let url = URL(string: server + endPoint) else {return}
        
        let updateTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                if let dict = json as? [String: Any] {
                    if let name = dict["player1"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[0] = name
                    } else {
                        print("Didn't work")
                    }
                }
                if let dict = json as? [String: Any] {
                    if let name = dict["player2"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[1] = name
                    } else {
                        print("Didn't work")
                    }
                }
                if let dict = json as? [String: Any] {
                    if let name = dict["player3"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[2] = name
                    } else {
                        print("Didn't work")
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if !self.playersInLobby.isEmpty {
                    let namesList = self.playersInLobby.joined(separator: ", ")
                    self.playerLabel.text = "Players: " + namesList
                    if self.isHost{
                        self.startButton.isHidden = false
                        self.startButton.isEnabled = true
                    }
                }
            }
        }
        updateTask.resume()
    }
    
}
