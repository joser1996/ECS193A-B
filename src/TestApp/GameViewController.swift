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
    
    @IBOutlet weak var sceneViewGame: ARSCNView!
    
    
    
    override func viewDidLoad() {
        print("In View Did Load")
        super.viewDidLoad()
        sceneViewGame.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear")
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        let op: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        if let worldMap = previousViewController.worldMap {
            configuration.initialWorldMap = worldMap
            print("The map has been set")
        }
        
        sceneViewGame.session.run(configuration, options: op)
        sceneViewGame.session.delegate = self
    }


//    //MARK: View Life Cycle
//    //View Life Cycle modeled after AR Multipeer Demo
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        mcService = MultipeerSession(receivedDataHandler: receivedData)
//        //Start MultiPeer Service once view loads
//        //addBox()
//        //addTapGestureToSceneView()
//    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        guard ARWorldTrackingConfiguration.isSupported else {
//            fatalError("""
//                AR Not supported on device. Implement so that App won't be installed on devices
//                that lack AR support so users don't see this message
//            """) // For details, see https://developer.apple.com/documentation/arkit
//        }
//        
//        // Start the view's AR session.
//        let configuration = ARWorldTrackingConfiguration()
//        // Only enabling plane detection for now
//        configuration.planeDetection = .horizontal
//        sceneView.session.run(configuration)
//        
//        // Set a delegate to track the number of plane anchors for providing UI feedback.
//        sceneView.session.delegate = self
//        
//        // Show orange dots(Feature Points)
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
//        //Don't want app to sleep
//        UIApplication.shared.isIdleTimerDisabled = true
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneViewGame.session.pause()
    }
    
//    //MARK: - AR Session Delegate
//    //Inform View of changes in quality of device position tracking
//    //code to update in this case goes in this functon
//    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        
//        // Update the UI to provide feedback on the state of the AR experience.
//        let trackingState = camera.trackingState
//        //let frame = session.currentFrame!
//        switch trackingState {
//            
//        case .normal where !mcService.connectedPeers.isEmpty && mapProvider == nil:
//            let peerNames = mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//            print("Connected with \(peerNames).")
//            
////        case .notAvailable:
////            message = "Tracking unavailable."
////
////        case .limited(.excessiveMotion):
////            message = "Tracking limited - Move the device more slowly."
////
////        case .limited(.insufficientFeatures):
////            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
//            
//        case .limited(.initializing) where mapProvider != nil,
//             .limited(.relocalizing) where mapProvider != nil:
//            print("Received map from \(mapProvider!.displayName).")
//            
//        case .limited(.relocalizing):
//            print("Resuming session — move to where you were when the session was interrupted.")
//            
//        case .limited(.initializing):
//            print("Initializing AR session.")
//        
//        default:
//            print("default")
//        }
//    }
//        
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        if (!previousViewController.mcService.connectedPeers.isEmpty) {
//            let peerNames = previousViewController.mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//            print("Game VC: Connected with \(peerNames).")
//            //connectionLabel.text = "\(peerNames)"
//        }
//
//        switch frame.worldMappingStatus {
//        case .notAvailable, .limited:
//            //Don't want to send data to each other if mapping status is limited or N/A
//            button.isEnabled = false
//            print("MappingStatus: NA or Limited")
//            mappingStatusLabel.text = "NA/Limited"
//        case .extending:
//            //has mapped some areas but is currently mapping aournd current position
//            button.isEnabled = true //!mcService.connectedPeers.isEmpty
//            print("MappingStatus: Extending")
//            mappingStatusLabel.text = "Extending"
//        case .mapped:
//            //Mapped enough of the visible area
//            button.isEnabled = true //!mcService.connectedPeers.isEmpty
//            print("MappingStatus: Mapped")
//            mappingStatusLabel.text = "Mapped"
//        @unknown default:
//            print("Unknown worldMappingStatus")
//            mappingStatusLabel.text = "Unknown"
//            button.isEnabled = false
//    }
//    
//    // Let the View know that the session ended because of some error
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        print("Session failed: \(error.localizedDescription)")
//        guard error is ARError else { return }
//        let errorWithInfo = error as NSError
//        let messages = [
//            errorWithInfo.localizedDescription,
//            errorWithInfo.localizedFailureReason,
//            errorWithInfo.localizedRecoverySuggestion
//        ]
//        
//        // Remove optional error messages.
//        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
//        
//        DispatchQueue.main.async {
//            // Present an alert informing about the error that has occurred.
//            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
//            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
//                alertController.dismiss(animated: true, completion: nil)
//                self.resetTracking(nil)
//            }
//            alertController.addAction(restartAction)
//            self.present(alertController, animated: true, completion: nil)
//        }
//    }
    
//    //Connect this function to reset button
//    func resetTracking(_ sender: UIButton?) {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal
//        sceneView.session.run(configuration, options:[.resetTracking, .removeExistingAnchors])
//    }
    
    // MARK: - Session Observer
    func sessionWasInterrupted(_ session: ARSession) {
        print("Sessin was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Session Interruption is over. Might have to reset tracking and Anchors here
        //resetTracking(nil)
        print("ViewController.sessionInterruptionEnded()")
    }
    
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
        //let tapLoc = recognizer.location(in: sceneView)
        var viewRect: CGRect
        if self.view.frame.width > self.view.frame.height {
            viewRect = CGRect(x: 0, y: 0, width: self.view.frame.width - 100, height: self.view.frame.height - 50)
        } else {
            viewRect = CGRect(x: 0, y: 0, width: self.view.frame.width - 40, height: self.view.frame.height - 40)
        }

        let center = CGPoint(x: viewRect.midX, y: viewRect.midY)
        //print(center)
        //print(tapLoc)
        let hitTestResults = sceneViewGame.hitTest(center)
        
        let node = hitTestResults.first?.node
        node?.removeFromParentNode()
    }
    
    // MARK: - SCNView Delegates
    //this function isn't being called
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            node.addChildNode(loadCube())
        }
    }
    
    var mapProvider: MCPeerID?
    
    // TODO: ADD Functionality to share the World Map data
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        print("Data received from \(peer)")
        do {
            if  let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("Getting worldmap")
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneViewGame.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                print("Getting anchor")
                // Add anchor to the session, ARSCNView delegate adds visible content.
                sceneViewGame.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    
    // MARK: - AR session management
    private func loadCube() -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.name = "boxNode"
        return boxNode
    }
    
}

