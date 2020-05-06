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

    //player
    var playerName: String!
    var players: [String] = []

    //gameSesion
    var gameID: Int? = nil
    var gameState: GameState!
    var zombieTimer: Timer! = nil

    //falgs
    var isPlacingBase: Bool = true
    var isHost: Bool = false
    var didSyncCrossHair = false
    var isSyncing:Bool = false

    //game Objects
    var client: ClientSide!
    var baseObj: Base!
    var Shooter: Shooting = Shooting()

    //Globals
    var updateCounter: Int = 0
    var center = CGPoint(x: 0, y: 0)
    var health = 3
    var masterScore: Int = 0
  
    // Inventory
    let modelNames = ModelNameFetcher()
    var inventoryItems: [IndexPath: String] = [[0, 0]: "bullet"]
    var selectedItem: IndexPath = [0, 0]
    
    //outlets
    @IBOutlet weak var confirmBaseButton: UIButton!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var arView: ARSCNView!
    

    //MARK: Controller Set up
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.delegate = self
        arView.scene.physicsWorld.contactDelegate = self
        confirmBaseButton.isHidden = true
        confirmBaseButton.isEnabled = false
        changePrompt(text: "Please place Base.")
        //Init objects
        
        client = ClientSide(gameID: self.gameID, name: self.playerName, vc: self)
        
        baseObj = Base()
        
        if self.isHost {
            client.sendGameStartMessage()
        }
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
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

    
    
    //MARK: handleTap
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if isPlacingBase {
            self.baseObj.basePlacing(sender: sender, arView: self.arView)
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
                self.client.listenForWaveTask()
            }
        } else if client.gameState == GameState.ActiveGame {
            self.handleShooting(sender: sender)
        }

    }
    
    
    //MARK: handleShooting
    func handleShooting(sender: UITapGestureRecognizer) {
        Shooter.fireProjectile(view: arView)
    }
    
    
    
    //MARK: Collision Detection
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
       // print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            contact.nodeB.physicsBody?.categoryBitMask = 0
            contact.nodeA.physicsBody?.categoryBitMask = 0
            //handle logic to differentiate b/w  targets
            
            //increment score based on target
            
            //remove zombie logically; mark as dead
            guard let nodeAName = contact.nodeA.name else {
                print("NO NAME !!!")
                return
            }
            
            if nodeAName.hasPrefix("bullet") {
                //node b is the zombie
                guard let zKey = contact.nodeB.name else {
                    print("NodeB has no name")
                    return
                }
                self.client.zombieWave[zKey]?.isDead = true
            } else {
                //node a is the zombie
                guard let zKey = contact.nodeA.name else {
                    print("NodeA has no name")
                    return
                }
                self.client.zombieWave[zKey]?.isDead = true
            }
            
            
            DispatchQueue.main.async {
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
                self.updateCounter += 1
                if(self.updateCounter == 1) {
                    self.updateZombiesTask()
                    self.updateCounter = 0
                }
            }
        }
    }
    
    
    @IBAction func confirmBaseLocation(_ sender: UIButton) {
        //No more Base Placing
        self.isPlacingBase = false
        self.confirmBaseButton.isHidden = true
        self.confirmBaseButton.isEnabled = false
        self.client.confirmBaseTask(this: self)
    }
    
    
    //MARK: Zombie Update Task
    @objc func updateZombiesTask() {
        
        print("In updateZombiesTask")
//        let endPoint = "/update-wave/"
//        guard let gameID = self.gameID else {return}
//        let urlString = client.server + endPoint + String(gameID)
//        guard let url = URL(string: urlString) else {return}
//
//        var json: [String: Any] = [:]
//        for (index, seed) in self.zombieWave.enumerated() {
//            if seed.isDead {
//                //will put health in here later
//                json[String(seed.id)] = true
//                self.zombieWave.remove(at: index)
//            }
//        }
//        var request = URLRequest(url: url)
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted )
//            request.httpBody = jsonData
//            print("Seding: \(jsonData), \(json)")
//
//        } catch {
//            print(error.localizedDescription)
//        }
//
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//
//        let updateZombiesTask = urlSession.dataTask(with: request) {
//            (data, response, error) in
//            print("In handler updateZombie")
//            if let error = error {
//                print("error: \(error)")
//                return
//            }
//
//            guard let data = data else {
//                print("Couldn't print data")
//                return
//            }
//
//            do{
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//
//                guard let dict = json as? [String: Any] else {return}
//                guard let waveNum = dict["waveNumber"] as? Int else {return}
//                self.client.currentWave = waveNum
//
//                guard let wave = dict["zombieWave"] as? [String: Any] else {
//                    print("Failed to get seed!")
//                    return
//                }
//
//                guard let temp = self.getSeedArray(wave: wave) else {return}
//
//                DispatchQueue.main.async {
//                    self.updateFromReceived(ar: temp)
//                }
//
//            } catch {
//                print("Error: \(error.localizedDescription)")
//            }
//
//
//
//        }
//
//        updateZombiesTask.resume()
        
    }
    
    func updateFromReceived(ar: [ZombieSeed]) {
        print("In updatedFromRecieved")
//        for (idx,seed) in self.client.zombieWave {
//            for (index, s)  in ar.enumerated() {
//                if (s.id == seed.id) {
//                    break
//                }
//                if(index == (ar.count - 1)) {
//                    //delete form array
//                    self.client.zombieWave.remove(at: idx)
//
//                    //remove node
//                    guard let z = self.zombies[String(seed.id)] else {
//                        print("failed to find zombie object")
//                        return
//                    }
//                    guard let node = z.node else {
//                        print("Couldn't find node")
//                        return
//                    }
//                    node.removeFromParentNode()
//                }
//            }
//        }
    }
    
    
    func getSeedArray(wave: [String: Any]) -> [ZombieSeed]? {
        var tAr: [ZombieSeed] = []
        for (key,_) in wave {
            guard let seed = wave[key] as? [String: Any]
                else {
                    print("Failed to get seed")
                    return nil
            }
            guard let angle = seed["angle"] as? Float else {
                print("Failed at angle")
                return nil

            }
            guard let distance = seed["distance"] as? Double else {
                print("fail distance")
                return nil

            }
            guard let id = seed["id"] as? Int else {
                print("fail id")
                return nil

            }
            guard let x = seed["positionX"] as? Double else {
                print("fail x")
                return nil

            }
            guard let y = seed["positionY"] as? Double else {
                fatalError("Fail y")
            }
            guard let z = seed["positionZ"] as? Double else {
                fatalError("Fail x")
            }

            let tempSeed = ZombieSeed(angle: angle, distance: Float(distance), id: id, positionX: Float(x), positionY: Float(y), positionZ: Float(z), hasSpawned: false)
            tAr.append(tempSeed)
        }
        
        return tAr
    }
    
    
    
    //MARK: AR SCNView Delegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("baseNode") {
            self.baseObj.anchorPoint = anchor
            self.baseObj.loadBase()
            node.addChildNode(self.baseObj.baseNode)

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let inventoryVC = segue.destination as? InventoryViewController {
            inventoryVC.gameID = gameID
            inventoryVC.playerName = playerName
            inventoryVC.items = inventoryItems
            inventoryVC.selectedItem = selectedItem
        }
    }
    
    @IBAction func exitAndSaveInventory(unwindSegue: UIStoryboardSegue) {
        if let sourceVC = unwindSegue.source as? InventoryViewController {
            inventoryItems = sourceVC.items // store inventory items to load next time inventory opens
            selectedItem = sourceVC.selectedItem
        }
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
