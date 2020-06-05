//
//  OnlineGameSessionListController.swift
//  TestApp
//
//  Created by Jacob Smith on 5/8/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class OnlineGameSessionListController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createGameButton: UIButton!
    @IBOutlet weak var joinGameButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    
    var data: [String] = []
    var gameInfo: [String: Int] = [:]
    
    var playerName: String!
    var gameSessionName: String!
    var newGameId: Int!
    var gameSessionPassword: String!
    var refreshTimer: Timer!
    var selectedRow: IndexPath!
    
    let BASE_SERVER_URL = "http://server162.site:59435"
    let TIMER_LENGTH: Double = 3
    
    @IBAction func returnMenu(_ sender: UIButton) {
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        
        joinGameButton.isEnabled = false
        joinGameButton.setTitleColor(UIColor.gray, for: .normal)
        
        fetchSessionList()
              
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TIMER_LENGTH, repeats: true, block: { _ in
            self.fetchSessionList()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! OnlineGameSessionTableCell
        let text = data[indexPath.row]
        cell.label.text = text
           
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        gameSessionName = data[indexPath.row]
        joinGameButton.isEnabled = true
        joinGameButton.setTitleColor(UIColor.systemRed, for: .normal)
        selectedRow = indexPath
    }
    
    @IBAction func createNewGame(_ sender: Any) {
        getGameInfo(isNewGame: true)
    }
    
    @IBAction func joinGame(_ sender: Any) {
        getGameInfo(isNewGame: false)
    }
    
    func getGameInfo(isNewGame: Bool) {
        let alertController = UIAlertController(title: "Game information", message: nil, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) {
            (_) in
            
            if (alertController.textFields?[0].text == "" ||   // Check for empty fields
                alertController.textFields?[1].text == "" ||
                (isNewGame && alertController.textFields?[2].text == "")) {
                self.notify("Error: please fill out all fields")
                return
            }
            
            self.playerName = alertController.textFields?[0].text
            self.playerName = self.playerName.replacingOccurrences(of: " ", with: "-")
            self.gameSessionPassword = alertController.textFields?[1].text
            
            var url = URL(string: "")
            if (isNewGame) {
                self.gameSessionName = alertController.textFields?[2].text
                self.gameSessionName = self.gameSessionName.replacingOccurrences(of: " ", with: "-")
                url = URL(string: "\(self.BASE_SERVER_URL)/host-request/\(self.playerName!)/\(self.gameSessionName!)/\(self.gameSessionPassword!)")
            }
            else {
                let gameId = self.gameInfo[self.gameSessionName]
                url = URL(string: "\(self.BASE_SERVER_URL)/join/\(gameId!)/\(self.playerName!)/\(self.gameSessionPassword!)")
            }
            
            guard let requestUrl = url else { fatalError() }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
                
                var error: String!
                
                do {
                    if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                        if let id = convertedJsonIntoDict["gameId"] as? Int {
                            self.newGameId = id
                        }
                        if let didConnect = convertedJsonIntoDict["didConnect"] as? Int, didConnect == 0 {
                            error = "Failed to join game"
                        }
                        if let err = convertedJsonIntoDict["err"] as? String {
                            error = err
                        }
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                
                if (error != nil) {
                    DispatchQueue.main.async{
                        self.notify(error!)
                    }
                }
                else {
                    DispatchQueue.main.async{
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! GameSessionController
                        vc.isNewGame = isNewGame
                        vc.gameId = isNewGame ? self.newGameId : self.gameInfo[self.gameSessionName]
                        vc.playerName = self.playerName
                        vc.gameSessionName = self.gameSessionName
                        self.refreshTimer?.invalidate()
                        self.navigationController!.pushViewController(vc, animated: true)
                    }
                }
            }
            task.resume()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) in }
        
        alertController.addTextField {(textField) in
            textField.placeholder = "Enter Player Name"
        }
        alertController.addTextField {(textField) in
            textField.placeholder = "Enter Game Password"
        }
        if (isNewGame) {
            alertController.addTextField {(textField) in
                textField.placeholder = "Enter Game Name"
            }
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    func fetchSessionList() {
        let url = URL(string: "\(BASE_SERVER_URL)/fetch-active-games")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            do {
                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {

                    self.gameInfo = convertedJsonIntoDict as! [String : Int]
                    
                    for name in self.gameInfo.keys {
                        if (!self.data.contains(name)) {
                            self.data.append(name)
                        }
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async{
                self.tableView.reloadData()
                if (self.selectedRow != nil) {
                    self.tableView.selectRow(at: self.selectedRow!, animated: true, scrollPosition: UITableView.ScrollPosition.none)
                }
            }
        }
        task.resume()
    }
    
    func notify(_ text: String) {
        let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) {(_) in }
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
}

enum GameState {
    case BasePlacing
    case Initial
    case WaitingForGame
    case ActiveGame
}
