//
//  OnlineMultiplayerController.swift
//  TestApp
//
//  Created by Jose Torres on 4/11/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class OnlineMultiplayerController: UIViewController {

    @IBOutlet weak var notificationLabel: UILabel!
    let urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    let server: String = "http://server162.site:59435"
    var gameID: Int = 1
    var didConnect: Bool = false
    var playersInLobby: [String] = ["", "", "", ""]
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

    @IBAction func hostGameRequest(_ sender: UIButton) {
        let endPoint = "/host-request/PlayerA"
        let urlString = server + endPoint
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
                self.notificationLabel.text = "GameID is \(self.gameID)"
                self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
            }
        }

        hostReqTask.resume()
    }
    
    @IBAction func joinGameReq(_ sender: UIButton) {
        let endPoint = "/join/" + String(self.gameID) + "/PlayerB"
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
                    self.notificationLabel.text = "Connected to server!"
                    self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
                }
            }
            
        }
        joinReqTask.resume()
    }
    
    
    @objc func checkForUpdate() {
        let endPoint = "/host-check/" + String(self.gameID)
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
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if !self.playersInLobby.isEmpty {
                    
                    self.notificationLabel.text = self.playersInLobby.joined(separator: ", ")
                } else {
                    self.notificationLabel.text = "No Players"
                }
            }
        }
        updateTask.resume()
    }
    
}
