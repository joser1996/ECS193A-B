//
//  ClientSide.swift
//  TestApp
//
//  Created by Jose Torres on 5/6/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class ClientSide {
    
    let gameID: Int?
    let playerName: String?
    let server: String = "http://server162.site:59435"
    var gameState: GameState!
    var recievedZombies: Bool = false
    var currentWave: Int = 0
    var doneSpawning: Bool = false
    var taskTimer = Timer()
    var zombieWave: [String : ZombieSeed] = [:]
    var zombies: [String : Zombie] = [:]
    let urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)
        
    let referenceVC: OnlineGameViewController!
    
    init(gameID: Int?, name: String?, vc: OnlineGameViewController) {
        self.gameID = gameID
        self.playerName = name
        self.referenceVC = vc
    }
    
    
    func sendGameStartMessage() {
        guard let gameID = self.gameID else { return }
        guard let name = self.playerName else {return}
        
        let endPoint = "/start-game/" + String(gameID) + "/" + name
        guard let url = URL(string: server + endPoint) else {return}
        
        let gameStartMessageTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            let dataString = String(decoding: data, as: UTF8.self)
            print("sendGameStartMessage::\(dataString)")
            if dataString != "Success" {
                print("Error: sendGameStartMessage:: dataString")
            }
            //MARK: Debugging
            DispatchQueue.main.async {
                print("Move on to base Placing State")
            }
        }
        gameStartMessageTask.resume()
    }
    
    func confirmBaseTask(this: OnlineGameViewController){
        guard let gameID = self.gameID else {return }
        guard let name = self.playerName else {return }
        
        let endPoint = "/place-base/" + String(gameID) + "/" + name
        
        let urlStirng = self.server + endPoint
        guard let url = URL(string: urlStirng) else {return }
        
        let confirmBaseTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            let dataString = String(decoding: data, as: UTF8.self)
            
            if dataString == "Success" {
                self.waitForGame(this: this)
            }
        }
        confirmBaseTask.resume()
    }
    
    func waitForGame(this: OnlineGameViewController) {
        print("Wait for game")
        self.gameState = GameState.WaitingForGame
        
        DispatchQueue.main.async {
            self.taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkGameState), userInfo: this, repeats: true)
        }
    }
    
    @objc func checkGameState() {
        print("Update")
        let endPoint = "/game-state-check/"
        guard let gameID = self.gameID else {return}
        let urlString = self.server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        let checkStateTask = self.urlSession.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("Game State JSON: \(json)")
                guard let dict = json as? [String: Any] else {return}
                guard let state = dict["gameState"] as? String else {return}
                
                if self.gameState == GameState.WaitingForGame {
                    if state == "game"{
                        self.taskTimer.invalidate()
                        
                        DispatchQueue.main.async {
                           self.syncCrosshair()
                        }
                    }
                }
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        checkStateTask.resume()
    }
    
    func syncCrosshair() {
        print("Syncing")
        referenceVC.changePrompt(text: "Tap on Screen!")
        referenceVC.showPrompt()
        referenceVC.isSyncing = true
    }
    
    func mainGamePrep() {
        self.listenForWaveTask()
        while(!self.recievedZombies) {
            print("Waiting for zombies")
        }
    }
    
    
    func listenForWaveTask() {
        guard let gameID = self.gameID else {return}
        print("Waiting for zombie wave!")
        
        let endPoint = "/request-wave/"
        let urlString = self.server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
   
        let waveRequestTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                print(json)
                //want to extract data(wave) and store in global
                guard let dict = json as? [String: Any] else {return}
                print("Dictionary: \(dict)")
                guard let waveNum = dict["waveNumber"] as? Int else {return}
                self.currentWave = waveNum
                print("Current Wave Number: \(self.currentWave)")
                
                guard let wave = dict["zombieWave"] as? [String: Any] else {
                    fatalError("Failed to get zombie wave!!")
                }
                
                for (key, _) in wave {
                    guard let seed = wave[key] as? [String: Any] else {
                        fatalError("Failed to get seed!")
                    }
                    guard let angle = seed["angle"] as? Float else {
                         print("Failed at angle")
                         return

                     }
                     guard let distance = seed["distance"] as? Double else {
                         print("fail distance")
                         return

                     }
                     guard let id = seed["id"] as? Int else {
                         print("fail id")
                         return

                     }
                     guard let x = seed["positionX"] as? Double else {
                         print("fail x")
                         return

                     }
                     guard let y = seed["positionY"] as? Double else {
                         fatalError("Fail y")
                     }
                     guard let z = seed["positionZ"] as? Double else {
                         fatalError("Fail x")
                     }

                    let tempSeed = ZombieSeed(angle: angle, distance: Float(distance), id: id, positionX: Float(x), positionY: Float(y), positionZ: Float(z), hasSpawned: false)
                    self.zombieWave[String(tempSeed.id)] = tempSeed
                }
                //print("Final Wave: \(self.zombieWave)")
                DispatchQueue.main.async {
                    self.recievedZombieWave()
                }
            } catch {
                print("JSON error \(error.localizedDescription)")
            }
        }
        waveRequestTask.resume()
    }
    
    func recievedZombieWave() {
        print("In recievedZombieWave")
        guard let gameID = self.gameID else {return}
        let endPoint = "/received-zombie/" + String(gameID)
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let recZombieTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
         
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            print("JSON From recZombieTask")
            print(data)
            
            DispatchQueue.main.async {
                self.listenForStartTaskHelper()
            }
        }
        recZombieTask.resume()
    }
    
    func listenForStartTaskHelper() {
        self.taskTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.listenForStartTask), userInfo: nil, repeats: true)
    }
    
    
    @objc func listenForStartTask() {
        let endPoint = "/game-ready/"
        guard let gameID = self.gameID else {return}
        let urlString = server + endPoint + String(gameID)
        print("Game: game-ready")
        guard let url = URL(string: urlString) else {return}
        
        let listenForStartTask = self.urlSession.dataTask(with: url){
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                guard let dict = json as? [String: Any] else {
                    fatalError("Failed in lisenForTask:convert JSON to Dict")
                }
                
                guard let isReady = dict["isReady"] as? Bool else {
                    fatalError("Failed in listenForStartTask: extracting isReady")
                }
                if isReady {
                    DispatchQueue.main.async {
                        self.taskTimer.invalidate()
                        self.startGameNow()
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        }
        listenForStartTask.resume()
    }
    
    func startGameNow() {
        print("Setting up background task")
        self.taskTimer = Timer.scheduledTimer(timeInterval:1, target: self, selector: #selector(self.zombieSpawningTask), userInfo: nil, repeats: true)
        self.gameState = GameState.ActiveGame
    }
    
    func getZombieSeedKey() -> String? {
        for (key, seed) in self.zombieWave {
            if !seed.hasSpawned {
                return key
            }
        }
        self.doneSpawning = true
        return nil
    }
    
    @objc func zombieSpawningTask() {
        let k = self.getZombieSeedKey()
        guard let key = k else {
            if self.doneSpawning {
                print("Deactivating zombie spawning")
                self.taskTimer.invalidate()
            }
            return
        }
        guard let node = loadZombie(seedKey: key) else {
            print("Failed to get Zombie Node")
            return
        }
        node.name = key
        let zombie = Zombie(name: node.name!, health: 1, node: node)
        zombies[node.name!] = zombie
        referenceVC.arView.scene.rootNode.addChildNode(node)
    }
    
    
    func loadZombie(seedKey sk: String) -> SCNNode? {
        guard let zScene = SCNScene(named: "art.scnassets/minecraftupdate2.dae") else {
            fatalError("Couldn't load zombie")
        }
        let parentNode = SCNNode()
        let nodeArray = zScene.rootNode.childNodes
        
        for child in nodeArray {
            parentNode.addChildNode(child as SCNNode)
        }
        
        //Add physics to node
        parentNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        parentNode.physicsBody?.isAffectedByGravity = false
        
        //collision
        parentNode.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
        parentNode.physicsBody?.contactTestBitMask = CollisionCategory.bulletCategory.rawValue
        
        let basePosition = SCNVector3(
            referenceVC.baseObj.anchorPoint.transform.columns.3.x,
            referenceVC.baseObj.anchorPoint.transform.columns.3.y,
            referenceVC.baseObj.anchorPoint.transform.columns.3.z
        )
        
        //Movement
        let moveAction = SCNAction.move(to: basePosition, duration: 150)
        let deletion = SCNAction.removeFromParentNode()
        let zombieSequence = SCNAction.sequence([moveAction, deletion])
        
        parentNode.runAction(zombieSequence, completionHandler:{
            //decrease player health
            
            // TODO: send update to server to update health
            print("Base has been hit!!!")
            
            // if health is 0 go to game over state
        })
        
        let sd = self.zombieWave[sk]
        guard let seed = sd else {
            print("Couldn't find seed in dictionary")
            return nil
        }
        parentNode.position = SCNVector3(seed.positionX, seed.positionY, seed.positionZ)
        
        //mark seed as spawned
        self.zombieWave[sk]?.hasSpawned = true
        return parentNode
    }
    
    
    
}
