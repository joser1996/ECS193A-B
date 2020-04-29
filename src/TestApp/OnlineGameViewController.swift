//
//  OnlineGameViewController.swift
//  TestApp
//
//  Created by Jose Torres on 4/20/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit
class OnlineGameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

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
        confirmBaseButton.isHidden = true
        confirmBaseButton.isEnabled = false
        changePrompt(text: "Please place Base.")
        if self.isHost {
            sendGameStartMessage()
        }
    }
    
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
    
    
    private func loadCube() -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "boxNode"
        return boxNode
    }
    
    func basePlacing(sender: UITapGestureRecognizer) {
        print("TAP!")
        guard let hitTestResult = arView.hitTest(sender.location(in: arView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else {return}
        baseNode?.removeFromParentNode()
        
        if self.anchorPoint != nil {
            arView.session.remove(anchor: anchorPoint)
        }
        
        self.anchorPoint = ARAnchor(name: "cube", transform: hitTestResult.worldTransform)
        
        arView.session.add(anchor: self.anchorPoint)
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if isPlacingBase {
            basePlacing(sender: sender)
            //UI Stuff
            changePrompt(text: "Confirm Base Location")
            confirmBaseButton.isHidden = false
            confirmBaseButton.isEnabled = true
        }
        
        if isSyncing {
            let tapLoc = sender.location(in: self.arView)
            self.center = tapLoc
            self.isSyncing = false
            self.didSyncCrossHair = true
            self.hidePrompt()
            DispatchQueue.main.async {
                self.listenForWaveTask()
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
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON from recZombiesTask\(json)")
                //Not JSON just a string "Success"
            } catch {
                print("JSON error: \(error.localizedDescription)")
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
    }
    
    //MARK: SpawnZombie Logic
    func getZombieSeed () -> ZombieSeed! {
        print("In getZombieSeed")
        for var seed in self.zombieWave {
            if !seed.hasSpawned {
                seed.hasSpawned = true
                return seed
            }
        }
        return nil
    }
    
    @objc func zombieSpawningTask() {
        print("In zombieSpawningTask")
        guard let zSeed = self.getZombieSeed() else {
            print("returned nil")
            return
        }
        let node = loadZombie(seed: zSeed)
        let name = String(zSeed.id)
        node.name = name
        let zombie = Zombie(name: node.name!, health: 1, node: node)
        zombies[node.name!] = zombie
        print("Done spawning zombie")
        self.arView.scene.rootNode.addChildNode(node)
        
    }
    
    private func loadZombie(seed: ZombieSeed) -> SCNNode{
        print("in loadZombie")
        let sceneURL = Bundle.main.url(forResource: "minecraftupdate2", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        referenceNode.name = "boxNode"
        
        let basePosition = SCNVector3(
            self.anchorPoint.transform.columns.3.x,
            self.anchorPoint.transform.columns.3.y,
            self.anchorPoint.transform.columns.3.z
            
        )
        
        //Movement
        let moveAction = SCNAction.move(to: basePosition, duration: 10)
        let deletion = SCNAction.removeFromParentNode()
        let zombieSequence = SCNAction.sequence([moveAction, deletion])
        
        referenceNode.runAction(zombieSequence, completionHandler:{
            //decrease player health
            
            // TODO: send update to server to update health
            print("Base has been hit!!!")
            
            // if health is 0 go to game over state
        })
        
        referenceNode.position = SCNVector3(seed.positionX, seed.positionY, seed.positionZ)
        
        return referenceNode
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
        if let name = anchor.name, name.hasPrefix("cube") {
            self.anchorPoint = anchor
            self.baseNode = loadCube()
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
    var positionX:Float = 0;
    var positionY:Float = 0;
    var positionZ:Float = 0;
    var hasSpawned:Bool = false
}
