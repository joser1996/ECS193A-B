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
    
    @IBAction func confirmBaseLocation(_ sender: UIButton) {
        //No more Base Placing
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
                    self.client.updateZombiesTask()
                    self.updateCounter = 0
                }
            }
        }
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
