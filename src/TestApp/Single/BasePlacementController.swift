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
    @IBOutlet weak var promptLabel: UILabel!
    
    var baseNode: SCNNode!
    var anchorPoint: ARAnchor!
    var worldMap: ARWorldMap!
    var activePlayers: [Player]!
    
    
    //MARK: View Life Cycle
    //View Life Cycle modeled after AR Multipeer Demo
    override func viewDidLoad() {
        super.viewDidLoad()
        MusicPlayer.shared.stopBackgroundMusic()
        sceneView.delegate = self
        shareMapButton.isEnabled = false

        promptLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        connectionLabel.font = UIFont(name: "Bloody", size: 27)
        connectionLabel.textColor = UIColor.red
        connectionLabel.text = "Place Your Base By Tapping On Screen"
        
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
    //node corresponding to anchor has been added
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            anchorPoint = anchor
            baseNode = loadBase()
            DispatchQueue.main.async {
                self.connectionLabel.text = "Map More Of The Area By Moving Camera Around"
                self.promptLabel.isHidden = false
            }
            node.addChildNode(baseNode)
        }
    }
    
        
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            print("MappingStatus: NA or Limited")
        case .extending:
            print("MappingStatus: Extending")
        case .mapped:
            if (baseNode != nil)
            {
                self.connectionLabel.text = "Press Start"
                shareMapButton.titleLabel?.font = UIFont(name: "Bloody", size: 27)
                shareMapButton.setTitleColor(.red, for: .normal)
                shareMapButton.isEnabled = (baseNode != nil)
            }
            print("MappingStatus: Mapped")
        @unknown default:
            print("Unknown worldMappingStatus")
        }
    }
    
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
    

    
    @IBAction func handleShareMap(_ sender: Any) {
        if mapProvider == nil {
            sceneView.session.getCurrentWorldMap { worldMap, error in
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
            }
            else if let playerVC = segue.destination as? PlayerSession {
                playerVC.previousVC = self
            }
        
    }

}
