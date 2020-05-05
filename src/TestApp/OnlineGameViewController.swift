//
//  OnlineGameViewController.swift
//  TestApp
//
//  Created by Jose Torres on 4/20/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import AVFoundation

class OnlineGameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    var playerName: String!
    var players: [String] = []
    let server: String = "http://server162.site:59435"
    var gameID: Int? = nil
    var isPlacingBase: Bool = true
    let urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    var isHost: Bool = false
    var gameState: GameState!
    var baseNode: SCNNode!
    var anchorPoint: ARAnchor!
    var taskTimer = Timer()
    var Shooter: Shooting = Shooting()
    
    //game stuff
    var didSyncCrossHair = false
    var isSyncing:Bool = false
    var currentWave:Int = 0
    var center = CGPoint(x: 0, y: 0)
    var health = 3
    var isWithinBase = true
    var zombies: [String: Zombie] = [:]
    var zombieIndex: Int = 0
    var zombieTimer: Timer! = nil
    var masterScore: Int = 0
    var recievedZombies: Bool = false
    var zombieWave: [ZombieSeed] = []
    @IBOutlet weak var confirmBaseButton: UIButton!
    
    
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var arView: ARSCNView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.delegate = self
        arView.scene.physicsWorld.contactDelegate = self
        confirmBaseButton.isHidden = true
        confirmBaseButton.isEnabled = false
        changePrompt(text: "Please place Base.")
        if self.isHost {
            sendGameStartMessage()
        }
    }
    
    // MARK: sendGameStartMessage
    func sendGameStartMessage() {
        print("In view start message")
        guard let gameID = self.gameID else {return}
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
            print("Data was recieved")
            let dataString = String(decoding: data, as: UTF8.self )
            print(dataString)
            if dataString != "Success" {
                print("Error: Something went wrong")
                return
            }
            
            DispatchQueue.main.async {
                print("Move on to Base Placing State")
            }
        }
        gameStartMessageTask.resume()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("AR Not supported on this device")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        arView.session.delegate = self
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    //MARK: Prompt Stuff
    func changePrompt(text: String) {
        self.promptLabel.text = text
    }
    
    func hidePrompt() {
        self.promptLabel.isHidden = true
    }
    func showPrompt() {
        self.promptLabel.isHidden = false
    }
    //MARK: Methods
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    
    //MARK: loadBase
    private func loadBase() -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "baseNode"
        return boxNode
    }
    
    func basePlacing(sender: UITapGestureRecognizer) {
        print("TAP!")
        guard let hitTestResult = arView.hitTest(sender.location(in: arView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else {return}
        baseNode?.removeFromParentNode()
        
        if self.anchorPoint != nil {
            arView.session.remove(anchor: anchorPoint)
        }
        
        self.anchorPoint = ARAnchor(name: "baseNode", transform: hitTestResult.worldTransform)
        
        arView.session.add(anchor: self.anchorPoint)
    }
    
    
    //MARK: handleTap
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if isPlacingBase {
            basePlacing(sender: sender)
            //UI Stuff
            changePrompt(text: "Confirm Base Location")
            confirmBaseButton.isHidden = false
            confirmBaseButton.isEnabled = true
            
        } else if isSyncing {
            print("is in isSyncing")
            let tapLoc = sender.location(in: self.arView)
            self.center = tapLoc
            print("Center is: \(self.center)")
            self.isSyncing = false
            self.didSyncCrossHair = true
            self.hidePrompt()
            DispatchQueue.main.async {
                self.listenForWaveTask()
            }
        } else if self.gameState == GameState.ActiveGame {
            self.handleShooting(sender: sender)
        }

    }
    
    
    //MARK: handleShooting
    func handleShooting(sender: UITapGestureRecognizer) {
        
        Shooter.fireProjectile(view: arView)
        
        let hitTestResults = self.arView.hitTest(center, options: [SCNHitTestOption.backFaceCulling: false])
        print("ZOMBIE: Center is \(self.center)")
        guard let node = hitTestResults.first?.node else {
            print("ZOMBIE: Hit test returned nothing")
            return
        }
        
        if let name = node.name, name != "baseNode" {
            guard let parentNode = node.parent else{
                print("No parent Node")
                return
            }
            guard let zIndex = parentNode.name else {return}
            MusicPlayer.shared.playZombieDying()
            let hitZombie = zombies[zIndex]
            //assuming health is 1 for now
            parentNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.1), SCNAction.removeFromParentNode()]))
//            // update score
//            // remove zombie logically
            self.zombies.removeValue(forKey: zIndex)
        }
        
        
    }
    
    
    
    //MARK: Collision Detection
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            //handle logic to differentiate b/w  targets
            
            //increment score based on target
            
            DispatchQueue.main.async {
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
            }
            
        }
        
        
        
    }
    
    
    
    @IBAction func confirmBaseLocation(_ sender: UIButton) {
        //No more Base Placing
        self.isPlacingBase = false
        self.confirmBaseButton.isHidden = true
        self.confirmBaseButton.isEnabled = false
        guard let gameID = self.gameID else {return}
        guard let name = self.playerName else {return}
        //Send a message to server saying base has been placed
        let endPoint = "/place-base/" + String(gameID) + "/" + name
        
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        

        let confirmBaseTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            let dataString = String(decoding: data, as: UTF8.self)
            
            print("Data from base: \(dataString)")
            if dataString == "Success" {
                self.waitForGame()
            }
        }
        confirmBaseTask.resume()
    }
    
    
    func waitForGame() {
        //change state
        print("waitForGame")
        self.gameState = GameState.WaitingForGame

        //set up task that will monitor state from server
        
        DispatchQueue.main.async {
            self.taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkGameState), userInfo: nil, repeats: true)
        }

    }

        
    @objc func checkGameState() {
        print("Update")
        let endPoint = "/game-state-check/"
        guard let gameID = self.gameID else {return}
        
        let urlString = self.server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        
        let checkStateTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
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
                    print("STATE: in if")
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
    
    
    func mainGamePrep(){
        print("In Main Game")
        //listen for zombie wave
        self.listenForWaveTask()
        while(!self.recievedZombies){
            print("Waiting For Zombies")
        }
    }
    
    
    //MARK: listernForWaveTask
    func listenForWaveTask() {
        guard let gameID = self.gameID else {return}
        print("In listenForZombieWave")
        
        let endPoint = "/request-wave/"
        let urlString = self.server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        
        let waveRequestTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else{return}
            do{
                print("HERE: \(data)")
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                print(json)
                //want to extract data(wave) and store in global
                guard let dict = json as? [String: Any] else {return}
                print("Dictionary: \(dict)")
                guard let waveNum = dict["waveNumber"] as? Int else {return}
                self.currentWave = waveNum
                print("Current Wave Number: \(self.currentWave)")
                
                guard let wave = dict["zombieWave"] as? [Any] else {
                    fatalError("Failed to get zombie wave!!")
                }
                print("Wave: \(wave) of size: \(wave.count)")
                for i in 0..<wave.count {
                    guard let seed = wave[i] as? [String: Any] else {
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
                    self.zombieWave.append(tempSeed)
                }
                print("Final Wave: \(self.zombieWave)")
                DispatchQueue.main.async {
                    self.recievedZombieWave()
                }
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
        }
        waveRequestTask.resume()
    }
    
    func recievedZombieWave() {
        print("In recieved zombie wave")
        guard let gameID = self.gameID else {return}
        let endPoint = "/received-zombie/" + String(gameID)
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let recZombiesTask = self.urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do{
                //let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON from recZombiesTask")
                print(data)
                //Not JSON just a string "Success"
            }
            DispatchQueue.main.async {
                self.listenForStartTaskHelper()
            }
            
        }
        recZombiesTask.resume()
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
        let listenForStartTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            print("Data: \(data)")

            do{
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
        //start zombie spawning task here
        print("Setting up background task")
        self.taskTimer = Timer.scheduledTimer(timeInterval:1, target: self, selector: #selector(self.zombieSpawningTask), userInfo: nil, repeats: true)
        self.gameState = GameState.ActiveGame
        
        
        //set up task that will send and recives update from server for zombies
        
    }
    
    func updateZombiesTask() {
        print("In updateZombiesTask")
        let endPoint = "/update-wave/"
        guard let gameID = self.gameID else {return}
        let urlString = server + endPoint + String(gameID)
        guard let url = URL(string: urlString) else {return}
        var json: [String: Any] = [:]
        for seed in self.zombieWave {
            if seed.isDead {
                //will put health in here later
                json[String(seed.id)] = true
            }
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        //let updateZombiesTask = urlSession.dataTask(with: request)
        
        
        
    }
    
    
    //MARK: SpawnZombie Logic
    func getZombieSeedIndex() -> Int {
        var ret = -1
        for (index, seed) in self.zombieWave.enumerated() {
            if !seed.hasSpawned {
                ret = index
                return ret
            }
        }
        return ret
    }
    
    @objc func zombieSpawningTask() {
        let zSeedIndex = self.getZombieSeedIndex()
        if(zSeedIndex == -1) {
            //failed to return value index. Probablly no more seeds available
            return
        }
        
        let node = loadZombie(seedIndex: zSeedIndex)
        let name = String(self.zombieWave[zSeedIndex].id)
        node.name = name
        let zombie = Zombie(name: node.name!, health: 1, node: node)
        zombies[node.name!] = zombie
        print("Done spawning zombie")
        self.arView.scene.rootNode.addChildNode(node)
        
    }
    
    //MARK: loadZombie
    private func loadZombie(seedIndex si: Int) -> SCNNode{
        guard let zScene = SCNScene(named: "art.scnassets/minecraftupdate2.dae") else {
            fatalError("Couldn't load zombie")
        }
        let parentNode = SCNNode()
        let nodeArray = zScene.rootNode.childNodes
        
        for child in nodeArray {
            parentNode.addChildNode(child as SCNNode)
        }
        parentNode.name = "parentZombie"
        
        //Add physics to node
        parentNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        parentNode.physicsBody?.isAffectedByGravity = false
        
        //collision
        parentNode.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
        parentNode.physicsBody?.contactTestBitMask = CollisionCategory.bulletCategory.rawValue
        
        let basePosition = SCNVector3(
            self.anchorPoint.transform.columns.3.x,
            self.anchorPoint.transform.columns.3.y,
            self.anchorPoint.transform.columns.3.z
            
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
        let seed = self.zombieWave[si]
        parentNode.position = SCNVector3(seed.positionX, seed.positionY, seed.positionZ )
        
        // mark seed as spawned
        self.zombieWave[si].hasSpawned = true
        return parentNode
    }
    
    
    func syncCrosshair() {
        print("Syncing")
        self.changePrompt(text: "Tap on center!")
        self.showPrompt()
        self.isSyncing = true
    }
    
    
    
    //MARK: AR SCNView Delegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("This function was called 1")
        print("Base Anchor Name: \(anchor.name)")
        if let name = anchor.name, name.hasPrefix("baseNode") {
            self.anchorPoint = anchor
            self.baseNode = loadBase()
            node.addChildNode(self.baseNode)

        }
    }
    
    
    
    
    
//    //MARK: AR Session Delegate
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//
//        switch frame.worldMappingStatus {
//        case .notAvailable, .limited:
//            print("Mapping stateus: NA or Limited")
//        case .extending:
//            print("Extending map")
//
//        case .mapped:
//            print("Mapped state")
//
//        @unknown default:
//            print("Unkown world Mapping State")
//        }
//
//    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed: \(error.localizedDescription)")
        
        guard error is ARError else {return}
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0}).joined(separator: "\n")
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title:"The AR Session has Failed", message: errorMessage, preferredStyle: .alert)
            
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) {_ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    func resetTracking(_ sender: UIButton?) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.session.run(config, options:[.resetTracking, .removeExistingAnchors])
    }
    
    
    
}

struct ZombieSeed {
    var angle:Float = 0
    var distance:Float = 0
    var id:Int = 0;
    var positionX:Float = 0
    var positionY:Float = 0
    var positionZ:Float = 0
    var hasSpawned:Bool = false
    var isDead:Bool = false
}
