//
//  BasePlacementController.swift
//  TestApp
//
//  Created by Jacob Smith on 2/15/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit
import MultipeerConnectivity



class BasePlacementController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: Outlets
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var userInstructions: UILabel!
    @IBOutlet weak var shareMapButton: UIButton!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var gameModeState: UISwitch!
    //@IBOutlet weak var selectPlayerButton: UIButton!
    @IBOutlet weak var promptLabel: UILabel!
    
    var baseNode: SCNNode!
    var anchorPoint: ARAnchor!
    //var isHosting: Bool = true
    var worldMap: ARWorldMap!
    var activePlayers: [Player]!
    
    // MARK: Multipeer Implementation
    //var mcService : MultipeerSession!
    
    //MARK: View Life Cycle
    //View Life Cycle modeled after AR Multipeer Demo
    override func viewDidLoad() {
        super.viewDidLoad()
        MusicPlayer.shared.stopBackgroundMusic()
        //mcService = MultipeerSession(receivedDataHandler: receivedData)
        sceneView.delegate = self
        shareMapButton.isEnabled = false
        connectionLabel.text = "Place Your Base By Tapping On Screen"
        /*if isHosting {
            promptLabel.text = "Place Base Down"
        }*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                AR Not supported on device. Implement so that App won't be installed on devices
                that lack AR support so users don't see this message
            """)
        }
        
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        // Only enabling plane detection for now
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        // Show orange dots(Feature Points)
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        //Don't want app to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
 
    // MARK: - SCNView Delegates
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            anchorPoint = anchor
            baseNode = loadBase()
            DispatchQueue.main.async {
                self.connectionLabel.text = "Map More Of The Area By Moving Camera Around"
            }
            node.addChildNode(baseNode)
        }
    }
    
    
    //MARK: - AR Session Delegate
    //Inform View of changes in quality of device position tracking
    //code to update in this case goes in this functon
    /*func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        // Update the UI to provide feedback on the state of the AR experience.
        let trackingState = camera.trackingState
        //let frame = session.currentFrame!
        switch trackingState {
            
        case .normal where !mcService.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            print("Connected with \(peerNames).")
            
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            print("Received map from \(mapProvider!.displayName).")
            
        case .limited(.relocalizing):
            print("Resuming session — move to where you were when the session was interrupted.")
            
        case .limited(.initializing):
            print("Initializing AR session.")
        
        default:
            print("default")
        }
    }*/
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("Player Count: \(Player.playerCount)")
        /*if (!mcService.connectedPeers.isEmpty && mapProvider == nil) {
            let peerNames = mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            print("Connected with \(peerNames).")
            connectionLabel.text = "Connected with: \(peerNames)"
        }*/
        
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            print("MappingStatus: NA or Limited")
        case .extending:

            shareMapButton.isEnabled = (baseNode != nil) //|| (Player.playerCount != 0)
            print("MappingStatus: Extending")
            

        case .mapped:
            if (baseNode != nil)
            {
                 self.connectionLabel.text = "Press Start"
            }
            shareMapButton.isEnabled = (baseNode != nil) //|| (Player.playerCount != 0)

            print("MappingStatus: Mapped")
        @unknown default:
            print("Unknown worldMappingStatus")
        }

        
        /*if mapProvider != nil {
            shareMapButton.setTitle("Map Received! Proceed to game...", for: UIControl.State.normal)
        }*/
    }
    
    
    // MARK: - AR session management
    /*private func loadCube() -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "boxNode"
        return boxNode
    }*/
    
    private func loadBase() -> SCNNode {
        let sceneURL = Bundle.main.url(forResource: "base copy", withExtension: "scn", subdirectory: "art.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        referenceNode.name = "boxNode"
        return referenceNode
    }
    // MARK: - Session Observer
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session Interruption is over. Might have to reset tracking and Anchors here
        resetTracking(nil)
        print("ViewController.sessionInterruptionEnded()")
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
        sceneView.session.run(configuration, options:[.resetTracking, .removeExistingAnchors])
    }
    
    
    
    
    // MARK: - Common View Stuff
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        /*if !isHosting {
            print("Can't set base.")
            return
        }*/
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        baseNode?.removeFromParentNode()  // Only allow one base to be placed at a time
        if anchorPoint != nil{
            sceneView.session.remove(anchor: anchorPoint)
        }// Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
        anchorPoint = ARAnchor(name: "cube", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchorPoint)
        print("handleSceneTap: added anchor")
            
    }
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    /*func receivedData(_ data: Data, from peer: MCPeerID) {
        print("Data received from \(peer)")
        do {
            if let sharedWorldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("Getting worldmap")
                worldMap = sharedWorldMap
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
                
                shareMapButton.isHidden = false
                shareMapButton.isEnabled = true
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }*/
    
    @IBAction func handleShareMap(_ sender: Any) {
        if mapProvider == nil {
            sceneView.session.getCurrentWorldMap { worldMap, error in
                /*guard let map = worldMap
                    else { print("Error: \(error!.localizedDescription)"); return }
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    else { fatalError("can't encode map") }
                self.mcService.sendToAllPeers(data)
                if self.activePlayers != nil {
                    self.mcService.sendToConnectedPeers(data, self.activePlayers)
                }
                else {
                    print("No active Players!!")
                }*/
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
            if let gameVC = segue.destination as? GameViewController {
                sceneView.session.getCurrentWorldMap {worldMap, error in
                    guard let map = worldMap
                        else {return}
                    
                    self.worldMap = map
                }
                
                gameVC.previousViewController = self
                //gameVC.isMaster = (mapProvider == nil)
                //print("Passing self to next controller")
            }
            else if let playerVC = segue.destination as? PlayerSession {
                playerVC.previousVC = self
            }
        
    }
    
    
    /*@IBAction func gameModeState(_ sender: UISwitch) {
        //On means Hosting a game
        //let gameState: Bool = sender.isOn
        //Off means Joining Game
        //print("Switch: \(gameState)")
        //if(gameState == true){
        setForHosting()
        /*    self.isHosting = true
        }
        else{
            self.isHosting = false
            setForJoining()
        }*/
        
    }
    
    
    func setForHosting() {
        //selectPlayerButton.isHidden = false
        //selectPlayerButton.isEnabled = true
        
        shareMapButton.isHidden = false
        promptLabel.text = "Place Base Down"
    }

    func setForJoining() {
        //selectPlayerButton.isHidden = true
        //selectPlayerButton.isEnabled = false
        
        shareMapButton.isHidden = true
        shareMapButton.isEnabled = false
        
        promptLabel.text = "Waiting For Map From Host"
    }*/
    

}
