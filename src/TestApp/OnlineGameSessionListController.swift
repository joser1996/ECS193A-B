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
    
    var data: [String] = []
    var gameInfo: [String: Int] = [:]
    
    var playerName: String!
    var gameSessionName: String!
    var newGameId: Int!
    var gameSessionPassword: String!
    
    let BASE_SERVER_URL = "http://server162.site:59435"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        
        joinGameButton.isEnabled = false
        
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

                    print(convertedJsonIntoDict)
                    self.gameInfo = convertedJsonIntoDict as! [String : Int]
                    self.data = Array(self.gameInfo.keys)
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
            self.playerName = alertController.textFields?[0].text
            self.gameSessionPassword = alertController.textFields?[1].text
            
            var url = URL(string: "")
            if (isNewGame) {
                self.gameSessionName = alertController.textFields?[2].text
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
                
                var didJoinSuccessfully = 0
                var error: String!
                
                do {
                    if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                        if let id = convertedJsonIntoDict["gameId"] as? Int {
                            self.newGameId = id
                        }
                        if let didConnect = convertedJsonIntoDict["didConnect"] as? Int {
                            didJoinSuccessfully = didConnect
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
    
    func notify(_ text: String) {
        let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) {(_) in }
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
}
