//
//  ViewController.swift
//  TestApp
//
//  Created by Jose Torres on 1/22/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//
//try passing the config
import UIKit
import ARKit
import MultipeerConnectivity

class GameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    //MARK: Properties
    var initMap:ARWorldMap!
    // MARK: Multipeer Implementation
    var mcService : MultipeerSession!
    
    var previousViewController: BasePlacementController!
    var didSyncCrosshair = false
    var center = CGPoint(x: 0, y: 0)
    var health = 3
    var isWithinBase = true
    var wave = 1
    
    var zombies : [String: Zombie] = [:]
    var zombieIndex : Int = 0
    var theBase = SCNNode()
    var zombieTimer : Timer! = nil
    var masterScore : Int = 0
    
    var inventoryItems : [String] = []
    
    @IBOutlet weak var sceneViewGame: ARSCNView!
    @IBOutlet weak var userPrompts: UILabel!
    @IBOutlet weak var GameOver: UILabel!
    @IBOutlet weak var ReturnToBase: UILabel!
    @IBOutlet weak var Score: UILabel!
    @IBOutlet weak var PauseButton: UIButton!
    @IBOutlet weak var NextWave: UILabel!
    
    
    @IBOutlet weak var Heart1: UIImageView!
    @IBOutlet weak var Heart2: UIImageView!
    @IBOutlet weak var Heart3: UIImageView!
    @IBOutlet weak var EmptyHeart1: UIImageView!
    @IBOutlet weak var EmptyHeart2: UIImageView!
    @IBOutlet weak var EmptyHeart3: UIImageView!
    
    func generateZombieName() -> String {
        let name = String(zombieIndex)
        zombieIndex += 1
        return name
    }
    
    func spawnZombie(paramHealth: Int = 2) {
        let angle = Float.random(in: 0 ..< 360)
        let distance = Float.random(in: 1.5 ..< 2)
        let position = (x: distance * cos(angle * Float.pi / 180), y: -0.4, z: distance * sin(angle * Float.pi / 180))
        let node = loadZombie(position.x, -0.4, position.z, true, paramHealth)
        let basePosition = SCNVector3(
            previousViewController.anchorPoint.transform.columns.3.x,
            previousViewController.anchorPoint.transform.columns.3.y,
            previousViewController.anchorPoint.transform.columns.3.z
        )
        if (node.name != "bulletNode") {
            node.look(at: basePosition)
        }
        let name = generateZombieName()
        node.name = name
        
        let zombie = Zombie(name: name, health: paramHealth, node: node)
        zombies[name] = zombie
        
        self.sceneViewGame.scene.rootNode.addChildNode(node)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PauseButton.isHidden = true
        NextWave.isHidden = true
        ReturnToBase.isHidden = true
        sceneViewGame.delegate = self

        self.GameOver.isHidden = true

        _ = loadBase()
    }
    
    
    func zombieStuff(_ waves: Int) {
        
        var zombieCount = 0
        var timerOne = 1
        var sleep = 7
        var wave = waves
            self.zombieTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if zombieCount == 0 && sleep != 0 {
                    sleep -= 1
                }
                else if zombieCount ==  wave * 2 {
                    if sleep == 0 {
                        for _ in 1...(wave * 2) {
                            self.spawnZombie(paramHealth: Int.random(in: 1...3))
                        }
                        wave += 1
                        self.wave = wave
                        zombieCount = 0
                        timerOne = 0
                        sleep = 20
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            if (self.health != 0) {
                                self.PauseButton.isHidden = false
                                self.NextWave.isHidden = false
                            }
                        }
                    }
                    else {
                        sleep -= 1
                    }
                }
                else if timerOne == 0 {
                    // Zombie spawn code
                    self.PauseButton.isHidden = true
                    self.NextWave.isHidden = true
                    self.spawnZombie(paramHealth: Int.random(in: 1...3))
                    zombieCount += 1
                    
                    // Reset timer
                    if zombieCount < (wave * 2)/4 {
                        if wave < 3 {
                            timerOne = Int.random(in: 4...6)
                        }
                        else if wave < 5 {
                            timerOne = Int.random(in: 3...5)
                        }
                        else if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }
                    else if zombieCount < (wave * 2)/2 {
                        if wave < 5 {
                            timerOne = Int.random(in: 3...5)
                        }
                        else if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }

                    else if zombieCount < 3 * (wave * 2)/4 {
                        if wave < 10 {
                            timerOne = Int.random(in: 2...4)
                        }
                        else {
                            timerOne = Int.random(in: 1...3)
                        }
                    }
                    else {
                        timerOne = Int.random(in: 1...3)
                    }
                }
                else {
                    timerOne -= 1
                }
            }
        }
        
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        let op: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        if let worldMap = previousViewController.worldMap {
            configuration.initialWorldMap = worldMap
        }
        
        sceneViewGame.session.run(configuration, options: op)
        sceneViewGame.session.delegate = self
        updatePromptLabel(prompt: "Tap on the crosshair")
        
        _ = zombieStuff(wave)
    }


    func updatePromptLabel( prompt: String) {
        userPrompts.text = prompt
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneViewGame.session.pause()
    }


    @IBAction func pause_button(_ sender: Any) {
        self.zombieTimer.invalidate()
        sceneViewGame.session.pause()
             let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let vc = storyboard.instantiateViewController(withIdentifier: "PauseViewController") as! PauseViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
        
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let basePosition = SCNVector3(
            previousViewController.anchorPoint.transform.columns.3.x,
            previousViewController.anchorPoint.transform.columns.3.y,
            previousViewController.anchorPoint.transform.columns.3.z
        )
        
        let camMatrix = SCNMatrix4(frame.camera.transform)
        let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
        let distance = SCNVector3(x: basePosition.x - position.x, y: basePosition.y - position.y, z: basePosition.z - position.z)
        let length = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
        
        if length > 1.5 {
            ReturnToBase.isHidden = false
            isWithinBase = false
        }
        else {
            ReturnToBase.isHidden = true
            isWithinBase = true
        }
        
        if self.health == 2 {
            self.Heart1.isHidden = true
        }
        else if self.health == 1 {
            self.Heart2.isHidden = true
            self.Heart1.isHidden = true
        }
        else if self.health <= 0 {
            self.Heart3.isHidden = true
            self.Heart2.isHidden = true
            self.Heart1.isHidden = true
            self.GameOver.isHidden = false
            self.PauseButton.isHidden = true
            self.NextWave.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.zombieTimer.invalidate()
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    // Let the View know that the session ended because of some error
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session failed: \(error.localizedDescription)")
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //Connect this function to reset button
    func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneViewGame.session.run(configuration, options:[.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Session Observer
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session Interruption is over. Might have to reset tracking and Anchors here
        //resetTracking(nil)
        print("ViewController.sessionInterruptionEnded()")
    }
    
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        if !didSyncCrosshair {
            let tapLoc = sender.location(in: sceneViewGame)
            center = tapLoc
            didSyncCrosshair = true
            updatePromptLabel(prompt: "Aim and Tap to shoot zombies!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.userPrompts.isHidden = true
            }
        }
        else if isWithinBase {
            guard let frame = sceneViewGame.session.currentFrame else {return}
            let bulletNode = loadBullet(frame)
            sceneViewGame.scene.rootNode.addChildNode(bulletNode)
            
            let shootTestResults = sceneViewGame.hitTest(center, types: .featurePoint)
            if !shootTestResults.isEmpty {
                guard let feature = shootTestResults.first else {
                    return
                }
                let targetPosition = SCNVector3(
                    feature.worldTransform.columns.3.x,
                    feature.worldTransform.columns.3.y,
                    feature.worldTransform.columns.3.z)
                    bulletNode.runAction(SCNAction.sequence([SCNAction.move(to: targetPosition, duration: 0.15), SCNAction.removeFromParentNode()]))
            }
            else {
                bulletNode.runAction(SCNAction.removeFromParentNode())
            }
        
            let hitTestResults = sceneViewGame.hitTest(center)
            let node = hitTestResults.first?.node
            
            if let name = node?.name, name != "baseNode" {
                guard let parentNode = node?.parent else {
                    print("No parent node")
                    return
                }
                
                guard let zIndex = parentNode.name else {return}
                let hitZombie = zombies[zIndex]
                
                hitZombie?.health? -= 1
                if hitZombie?.health == 0 {
                    MusicPlayer.shared.playZombieDying()
                    parentNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.1), SCNAction.removeFromParentNode()]))
                    

                    masterScore += hitZombie?.maxHealth ?? 0
                    let myScore = String(masterScore)
                    if (masterScore < 10) {
                        Score.text = "Score: 00" + myScore
                    }
                    if (masterScore >= 10 && masterScore < 99) {
                        Score.text = "Score: 0" + myScore
                    }
                    if (masterScore >= 100) {
                        Score.text = "Score: " + myScore
                    }
                    zombies.removeValue(forKey: name)
                }
                else if hitZombie?.health == 1 {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        let parentNode = node?.parent
                        node?.removeFromParentNode()
                        for child in parentNode!.childNodes {
                            child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "PurpleSkin")
                        }
                    }
                }
                else if hitZombie?.health == 2 {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        let parentNode = node?.parent
                        node?.removeFromParentNode()
                        for child in parentNode!.childNodes {
                            child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "YellowSkin")
                        }
                    }
                }
                else if hitZombie?.health == 3 {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    
                    }
                }
            }
        }
    }
    
    // MARK: - SCNView Delegates
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            node.addChildNode(loadBase())
        }
    }

    private func loadBase(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0, _ isZombie: Bool = false, _ health: Int = 2) -> SCNNode {
        let sceneURL = Bundle.main.url(forResource: "base copy", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        referenceNode.name = "boxNode"
        referenceNode.position = SCNVector3(x,y,z)
       
        
        return referenceNode
    }
    
    private func loadBullet (_ frame: ARFrame) -> SCNNode {
 
        let camMatrix = SCNMatrix4(frame.camera.transform)
        let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
        
        let bulletURL = Bundle.main.url(forResource: "bullet-model", withExtension: "scn", subdirectory: "art.scnassets")!
        let bulletNode = SCNReferenceNode(url: bulletURL)!
        bulletNode.load()
        
        bulletNode.name = "bullet"
        bulletNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        bulletNode.position = position
        bulletNode.position.y -= 0.1
        return bulletNode
    }
    
    // MARK: - AR session management
    private func loadZombie(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0, _ isZombie: Bool = false, _ health: Int = 2) -> SCNNode {
        var sceneURL = Bundle.main.url(forResource: "", withExtension: "scn", subdirectory: "art.scnassets")!
        switch Int.random(in: 1...4) {
        case 1:
            sceneURL = Bundle.main.url(forResource: "zombie_headless_180", withExtension: "scn", subdirectory: "art.scnassets")!
        case 2:
            sceneURL = Bundle.main.url(forResource: "zombie_1_arm_180", withExtension: "scn", subdirectory: "art.scnassets")!
        case 3:
            sceneURL = Bundle.main.url(forResource: "zombie_1_leg_180", withExtension: "scn", subdirectory: "art.scnassets")!
        case 4:
            sceneURL = Bundle.main.url(forResource: "walking_zombie_180", withExtension: "scn", subdirectory: "art.scnassets")!
        default:
            sceneURL = Bundle.main.url(forResource: "walking_zombie_180", withExtension: "scn", subdirectory: "art.scnassets")!
        }
        
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        referenceNode.name = "boxNode"
        
        if isZombie {
            if health == 1 {
                for child in referenceNode.childNodes {
                    child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "PurpleSkin")
                }
            }
            else if health == 2 {
                for child in referenceNode.childNodes {
                    child.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "YellowSkin")
                    
                }
            }

            
            referenceNode.name = "boxNode"
            
            let basePosition = SCNVector3(
                previousViewController.anchorPoint.transform.columns.3.x,
                previousViewController.anchorPoint.transform.columns.3.y,
                previousViewController.anchorPoint.transform.columns.3.z
            )
            
            let moveAction = SCNAction.move(to: basePosition, duration: 10)
            let deletion = SCNAction.removeFromParentNode()
            let zombieSequence = SCNAction.sequence([moveAction, deletion])
            
            referenceNode.runAction(zombieSequence, completionHandler:{
                self.health -= 1
            })
        }
        
        referenceNode.position = SCNVector3(x,y,z)
        
        return referenceNode
    }
    
}

extension GameViewController : PauseViewControllerDelegate {
    func pauseMenuUnPauseButtonPressed()
    {
        sceneViewGame.session.run(sceneViewGame.session.configuration!)
        
    }
 }

