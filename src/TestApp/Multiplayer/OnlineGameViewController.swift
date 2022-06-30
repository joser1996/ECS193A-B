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
    var connectionIsAlive: Bool = true
    
    //gameSesion
    var gameID: Int? = nil
    var gameState: GameState!
    var zombieTimer: Timer! = nil
    
    //falgs
    var isPlacingBase: Bool = true
    var isHost: Bool = false
    var didSyncCrossHair = false
    var isSyncing:Bool = false
    var isGameOver:Bool = false
    
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
    var inventoryItems: [IndexPath: [String: Any]] = [:]
    var selectedItem: IndexPath = [0, 0]
    
    //outlets
    @IBOutlet weak var confirmBaseButton: UIButton!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var heart1: UIImageView!
    @IBOutlet weak var heart2: UIImageView!
    @IBOutlet weak var heart3: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    

    //MARK: Controller Set up
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //turn of wind
        MusicPlayer.shared.stopBackgroundMusic()
        arView.delegate = self
        arView.scene.physicsWorld.contactDelegate = self
        confirmBaseButton.isHidden = true
        confirmBaseButton.isEnabled = false
        promptLabel.font = UIFont(name: "Bloody", size: 35)
        promptLabel.textColor = UIColor.red
        changePrompt(text: "Please place Base.")

        //Init objects
        client = ClientSide(gameID: self.gameID, name: self.playerName, vc: self)
        baseObj = Base()
        
        if self.isHost {
            client.sendGameStartMessage()
        }
        
        fetchInventoryItems(gameID!, playerName!)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
        print("Moved to background")
        client.killClient()
        self.connectionIsAlive = false
        self.arView.session.pause()
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
    
    func decrementHealth() -> Int{
        self.baseObj.health -= 1
        if self.baseObj.health < 0 {
            self.baseObj.health = 0
        }
        let health = self.baseObj.health
        //print("Health: \(health)")
        if (health == 2) {
            //get rid of rightmost heart
            heart3.image = UIImage(named: "Image-1")
        } else if (health == 1) {
            //get rid of middle heart
            heart3.image = UIImage(named: "Image-1")
            heart2.image = UIImage(named: "Image-1")
        } else {
            //get rid of leftmost heart
            heart3.image = UIImage(named: "Image-1")
            heart2.image = UIImage(named: "Image-1")
            heart1.image = UIImage(named: "Image-1")
        }
        return health
    }
    
    func setHealth(health: Int) {
        if (health == 2) {
            //get rid of rightmost heart
            heart3.image = UIImage(named: "Image-1")
        } else if (health == 1) {
            //get rid of middle heart
            heart3.image = UIImage(named: "Image-1")
            heart2.image = UIImage(named: "Image-1")
        } else {
            //get rid of leftmost heart
            heart3.image = UIImage(named: "Image-1")
            heart2.image = UIImage(named: "Image-1")
            heart1.image = UIImage(named: "Image-1")
        }
    }
    
    
    //MARK: Game Over
    func gameOver() {
        //killing game on server
        self.client.killGame()
        
        MusicPlayer.shared.stopSong()
        self.notifyUser(prompt: "Game Over")
        self.isGameOver = true
        self.setHealth(health: 0)
        MultiPlayerLeaderBoard.setMultiplayerScore(gameId: gameID!, score: masterScore)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            for controller in self.navigationController!.viewControllers as Array {
                if controller.isKind(of: FirstViewController.self) {
                    _ = self.navigationController!.popToViewController(controller, animated: false)
                }
            }
        }
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
    
    func notifyUser(prompt: String) {
        changePrompt(text: prompt)
        showPrompt()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            self.hidePrompt()
        }
        
    }

    
    //MARK: handleTap
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if isPlacingBase {
            self.baseObj.basePlacing(sender: sender, arView: self.arView)

            
            if baseObj.anchorPoint == nil {
                return
            }
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
    
    //MARK: Confirm Base
    @IBAction func confirmBaseLocation(_ sender: UIButton) {
        //No more Base Placing
        self.arView.debugOptions = []
        self.isPlacingBase = false
        self.confirmBaseButton.isHidden = true
        self.confirmBaseButton.isEnabled = false
        self.client.confirmBaseTask(this: self)
    }
    
    //MARK: handleShooting
    func handleShooting(sender: UITapGestureRecognizer) {
        Shooter.fireProjectile(view: arView)
    }
    
    //MARK: Collision Detection
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
       // print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        if isGameOver {
            return
        }
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            //handle logic to differentiate b/w  targets
            
            //increment score based on target
            
            //remove zombie logically; mark as dead
            guard let nodeAName = contact.nodeA.name else {
                print("NO NAME !!!")
                return
            }
            
            var isAZombie:Bool = false
            let explosion = SCNParticleSystem(named: "Explode", inDirectory: nil)
            
            let zKey:String
            if nodeAName.hasPrefix("bullet") {
                //node b is the zombie
                guard let zK = contact.nodeB.name else {
                    print("NodeB has no name")
                    return
                }
                zKey = zK
            } else {
                //node a is the zombie
                isAZombie = true
                guard let zK = contact.nodeA.name else {
                    print("NodeA has no name")
                    return
                }
                zKey = zK
            }
            //decrease health
            var damage = 1
            if let d = inventoryItems[selectedItem]?["damage"] as? String { // Use item attributes if available
                damage = Int(d)!
            }

            self.client.zombieWave[zKey]?.health -= damage

            guard let zHealth = self.client.zombieWave[zKey]?.health else {
                print("ZHEALTH: Can't unwrap")
                return
            }
            //make sure it doesn't go below zero
            if(zHealth < 0) {
                //set health to zero
                self.client.zombieWave[zKey]?.health = 0
                //prevent handler from being called twice
                contact.nodeB.physicsBody?.categoryBitMask = 7
                contact.nodeA.physicsBody?.categoryBitMask = 7
                // mark it as logically dead
                self.client.zombieWave[zKey]?.isDead = true
            } else {
                //get rid of bullet
                let nodeToRemove: SCNNode
                if isAZombie {
                    nodeToRemove = contact.nodeB
                    contact.nodeB.physicsBody?.categoryBitMask = 7
                } else {
                    nodeToRemove = contact.nodeA
                    contact.nodeA.physicsBody?.categoryBitMask = 7
                }
                DispatchQueue.main.async {
                    //removing bullet from view to prevent another collision
                    //with zombie that isn't one shot
                    nodeToRemove.removeFromParentNode()
                }
                return
            }

            DispatchQueue.main.async {
                self.masterScore += 5
                self.updateScoreLabel()
                MusicPlayer.shared.playZombieDying()
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
                self.client.updateZombiesTask()
                
            }
            if isAZombie {
                contact.nodeA.addParticleSystem(explosion!)
            } else {
                contact.nodeB.addParticleSystem(explosion!)
            }
        }
    }
    
    func updateScoreLabel() {
        var text = "Score: "
        text = text + String(self.masterScore)
        self.scoreLabel.text = text
    }
    
    //MARK: AR SCNView Delegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("baseNode") {
            self.baseObj.anchorPoint = anchor
            self.baseObj.loadBase()
            node.addChildNode(self.baseObj.baseNode)

        }
    }
    
    
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
    
    //MARK: Inventory
    func fetchInventoryItems(_ gameID: Int, _ playerName: String) {
        let url = URL(string: "\(client.server)/fetch-inventory-items/\(gameID)/\(playerName)")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let error = error {
                print(error)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {

                    if let items = json["items"] as? [String: Any] {
                        if let initial = items["0"] as? [String: Any] {
                            DispatchQueue.main.async{
                                self.inventoryItems[self.selectedItem] = initial
                            }
                        }
                    }
                }
            } catch let error as NSError {
               print(error.localizedDescription)
            }
        }
        task.resume()
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
            Shooter.projectile = inventoryItems[selectedItem]?["item_name"] as? String
            if let animation = inventoryItems[selectedItem]?["animation"] as? String {
                Shooter.animation = animation
            }
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
    var health: Int = 1
}
