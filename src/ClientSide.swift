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
    
    
    /*
     This method is called initaly by the host and it sends a message
     to the server saying that the host has started a game and the
     lobby should be closed
     */
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
    
    /*
     Sends a message to the server saying that player has locked in
     their base position and are now waiting to hear from the server
     in waitForGame method
     */
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
    
    /*
     sets up timer that calls checkGameState method every
     second
     */
    func waitForGame(this: OnlineGameViewController) {
        print("Wait for game")
        self.gameState = GameState.WaitingForGame
        
        DispatchQueue.main.async {
            self.taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkGameState), userInfo: nil, repeats: true)
        }
    }
    
    /*
     Polling the server. Waiting for the server to return the state
     "game" which will only happen when all players have placed down
     their bases
     */
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
    
    /*
     Method acts as a way to allow the player to let the server know
     they are ready to start game.
     */
    func syncCrosshair() {
        print("Syncing")
        referenceVC.changePrompt(text: "Tap on Screen!")
        referenceVC.showPrompt()
        referenceVC.isSyncing = true
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
                DispatchQueue.main.async {
                    self.recievedZombieWave()
                }
            } catch {
                print("JSON error \(error.localizedDescription)")
            }
        }
        waveRequestTask.resume()
    }
  
    /*
     Sends message to server confirming reciept of zombie wave.
     */
    func recievedZombieWave() {
        print("Mult: In recievedZombieWave")
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
            print("Mult: ack response \(data)")
            DispatchQueue.main.async {
                self.listenForStartTaskHelper()
            }
        }
        recZombieTask.resume()
    }

    /*
     Sets up timer that polls server every 1 seconds waiting for the
     start signal that allows the spawning of zombies. Start won't be
     sent unitl all player have sent confirmation of zombie wave
     reciept
     */
    func listenForStartTaskHelper() {
        self.taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.listenForStartTask), userInfo: nil, repeats: true)
    }
    
    /*
     Once isReady message is recieved kills timer that's calling it
     and moves to startGameNow method
     */
    @objc func listenForStartTask() {
        let endPoint = "/game-ready/"
        guard let gameID = self.gameID else {return}
        let urlString = server + endPoint + String(gameID)
        print("Mult: game-ready")
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
                //print(json)
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
    
    /*
     This method starts timer that calls zombieSpawningTask every
     second
     */
    func startGameNow() {
        print("Mult: Setting up background task")
        self.doneSpawning = false
        self.taskTimer = Timer.scheduledTimer(timeInterval:1, target: self, selector: #selector(self.zombieSpawningTask), userInfo: nil, repeats: true)
        self.gameState = GameState.ActiveGame
        
        //start backgroung music
        if(!(MusicPlayer.shared.player?.isPlaying ?? true)) {
            MusicPlayer.shared.startSong()
        }
    }
    
    /*
     Method is in charge of spawning zombies onto sreen from the
     seeds that were recieved.
     */
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
        let basePosition = SCNVector3(
            referenceVC.baseObj.anchorPoint.transform.columns.3.x,
            referenceVC.baseObj.anchorPoint.transform.columns.3.y,
            referenceVC.baseObj.anchorPoint.transform.columns.3.z
        )
        node.look(at: basePosition)
        referenceVC.arView.scene.rootNode.addChildNode(node)
    }

    func updateHealthTask(health: Int) {
        let endPoint = "/update-health/"
        guard let gameID = self.gameID else {return}
        let urlString = server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        let json: [String: Any] = ["Health": health]
        var request = URLRequest(url: url)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
        } catch {
            print("Error Health: \(error.localizedDescription)")
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = self.urlSession.dataTask(with: request) {
            (data, response, error) in
            if let error = error {
                print("Error\(error)")
                return
            }
            
            guard let data = data else {return}
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dict = json as? [String: Any] else {
                    print("Failed json to dict")
                    return
                }
                guard let serverHealth = dict["Health"] as? Int else {
                    print("Failed to get Health")
                    return
                }
                
                guard let gameOver = dict["isGameOver"] as? Bool else {
                    print("Failed to get isGameOver")
                    return
                }
                DispatchQueue.main.async {
                    if gameOver && !self.referenceVC.isGameOver{
                        self.referenceVC.gameOver()
                    } else {
                        self.updateHealthFromServer(sHealth: serverHealth, cHealth: health)
                    }
                }
                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func updateHealthFromServer(sHealth: Int, cHealth: Int) {
        if (sHealth < cHealth) {
            DispatchQueue.main.async {
                self.referenceVC.setHealth(health: sHealth)
            }
        }
    }
    
    func updateZombiesTask() {
        let endPoint = "/update-wave/"
        guard let gameID = self.gameID else {return}
        let urlString = server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        
        let json = makeJSON()
        var request = URLRequest(url: url)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
        } catch {
            print(error.localizedDescription)
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = self.urlSession.dataTask(with: request) {
            (data, response, error) in
            if let error = error {
                print("error: \(error)")
                return
            }
            guard let data = data else {return}
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let obj = json as? [String : Any] else {return}
                guard let dict = obj["ZombieUpdate"] as? [String: Any] else {
                    print("MOO: ZombieUpdate key Failed")
                    return
                }
                
                guard let health = obj["Health"] as? Int else {
                    print("MOO: Health key failed")
                    return
                }
                print("MOO: Shoot server health\(health)")
                guard let isGameOver = obj["isGameOver"] as? Bool else {
                        print("MOO: Failed isGameOver key")
                        return
                }
                
                guard let waveNum = dict["waveNumber"] as? Int else {
                    return
                }
                self.currentWave = waveNum
                
                guard let wave = dict["zombieWave"] as? [String: Any] else {
                    print("Failed to get wave")
                    return
                }
                
                self.compareAndUpdate(wave: wave)
                print("Number of Zombies: \(self.zombieWave.count)")
                
                if isGameOver  && !self.referenceVC.isGameOver{
                    DispatchQueue.main.async {
                        self.referenceVC.gameOver()
                    }
                } else {
                    self.updateHealthFromServer(sHealth: health, cHealth: self.referenceVC.baseObj.health)
                }
                
                if self.zombieWave.count == 0 && !isGameOver {
                    DispatchQueue.main.async {
                        self.getNextWave()
                    }
                }
                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    /*
     Building JSON dictionary that will be sent via post to server.
     Updating zombiWave dictionary by removing zombies that are dead.
     */
    func makeJSON() -> [String: Any] {
        var json: [String: Any] = [:]
        for (key, seed) in self.zombieWave {
            if seed.isDead {
                json[key] = true
                // not sure about this step
                self.zombieWave.removeValue(forKey: key)
            }
        }
        return json
    }
    
    func compareAndUpdate(wave: [String: Any]) {
        guard let serverWave  = buildSeedDictionary(wave: wave) else {
            print("Failed to build updated wave from server")
            return
        }
        
        for (key, _) in self.zombieWave {
            // check to see if my seed is in updated wave
            let retVal = serverWave[key]
            
            //need to remove this zombie since not in updated wave
            if retVal == nil {
                //remove logically
                self.zombieWave.removeValue(forKey: key)
                DispatchQueue.main.async {
                    let node = self.zombies[key]?.node
                    node?.removeFromParentNode()
                }
            }
        }
    }
    
    
    func getNextWave() {
        print("Mult:")
        guard let gameID = self.gameID else {return}
        let endPoint = "/new-wave/" + String(self.currentWave) + "/" + String(gameID)

        let urlString =  self.server + endPoint
        print("Mult: Getting New Wave \(urlString)")
        guard let url = URL(string: urlString) else {return}
        
        let newWaveReq = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("Mult: \(json)")
                guard let dict = json as? [String: Any] else {return}
                guard let waveNum = dict["waveNumber"] as? Int else {
                    print("Mult: Failed to get waveNum")
                    return
                    
                }
                self.currentWave = waveNum
                print("Mult: Current Wave Num: \(self.currentWave)")
                
                guard let wave = dict["zombieWave"] as? [String: Any] else {
                    fatalError("Mult: Failed to get new wave!!!")
                }
                guard let seedDict = self.buildSeedDictionary(wave: wave) else {
                    print("Mult: Failed to build dictionary from seeds")
                    return
                }
                
                self.zombieWave = seedDict
            } catch {
                print("Mult: JSON Error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.recievedZombieWave()
                self.referenceVC.notifyUser(prompt: "Wave \(self.currentWave)")
            }
        }
        newWaveReq.resume()
    }
    
    func buildSeedDictionary(wave: [String: Any]) -> [String: ZombieSeed]?{
        var tempDict: [String: ZombieSeed] = [:]
        for (key, _) in wave {
            guard let seed = wave[key] as? [String: Any] else {return nil}
            guard let angle = seed["angle"] as? Float else {return nil}
            guard let distance = seed["distance"] as? Double else {
                print("Fail at distance")
                return nil
            }
            guard let id = seed["id"] as? Int else {
                print("fail at id")
                return nil
            }
            guard let x = seed["positionX"] as? Double else {
                print("fail x")
                return nil
            }
            guard let y = seed["positionY"] as? Double else {
                print("fail y")
                return nil
            }
            guard let z = seed["positionZ"] as? Double else {
                print("fail z")
                return nil
            }
            let tempSeed = ZombieSeed(angle: angle, distance: Float(distance), id: id, positionX: Float(x), positionY: Float(y), positionZ: Float(z), hasSpawned: false)
            //building dict
            tempDict[String(tempSeed.id)] = tempSeed
        }
        return tempDict
    }
    
    func killClient() {
        
        //if base hasn't been placed send dummy place-base
        if (self.referenceVC.isPlacingBase) {
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
            }
            confirmBaseTask.resume()
        }
        
        //then kill switch
        
        guard let gameID = self.gameID else {return}
        guard let name = self.playerName else {return}
        
        let endPoint = "/kill-client/" + String(gameID) + "/" + name
        let urlString = self.server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let killTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
        }
        killTask.resume()
    }
    
    func killGame() {
        guard let gameID = self.gameID else {return}
        
        let endPoint = "/kill-game/" + String(gameID)
        let urlString = self.server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let killGameTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
        }
        killGameTask.resume()
    }
    
    // MARK: Zombie Stuff
    
    /*
     Method looks through zombieWave dictionary and looks for first
     seed that it can find that has not been spawned yet. Returns
     key associated with that seed. Returns nil if no free seed
     found.
     */
    func getZombieSeedKey() -> String? {
        for (key, seed) in self.zombieWave {
            if !seed.hasSpawned {
                return key
            }
        }
        self.doneSpawning = true
        return nil
    }
    
    /*
     Method creates zombie SCNNode that is the zombie.
     */
    func loadZombie(seedKey sk: String) -> SCNNode? {
        guard let zScene = SCNScene(named: "art.scnassets/walking_zombie_180.dae") else {
            fatalError("Couldn't load zombie")
        }
        let parentNode = SCNNode()
        let nodeArray = zScene.rootNode.childNodes
        
        for child in nodeArray {
            parentNode.addChildNode(child as SCNNode)
        }
        
        //Add physics to node
        let bound = SCNPhysicsShape(geometry: SCNBox(width: 0.03, height: 0.05, length: 0.03, chamferRadius: 0), options: [:])
        parentNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: bound)
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
        let moveAction = SCNAction.move(to: basePosition, duration: 15)
        let deletion = SCNAction.removeFromParentNode()
        let zombieSequence = SCNAction.sequence([moveAction, deletion])
        
        parentNode.runAction(zombieSequence, completionHandler:{
            if self.referenceVC.isGameOver {
                return
            }
            //decrease player health
            print("Base has been hit!!!")
            // if health is 0 go to game over state
            guard let name = parentNode.name else {
                print("Mult: No name")
                return
            }

            DispatchQueue.main.async {
                self.zombieWave[name]?.isDead = true
                let health: Int = self.referenceVC.decrementHealth()
                self.updateHealthTask(health: health)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.updateZombiesTask()
                }

            }
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
