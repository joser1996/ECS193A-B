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
    
    var mapFlag = false
    var baseNode: SCNNode!
    
    // MARK: Multipeer Implementation
    var mcService : MultipeerSession!
    
    //MARK: View Life Cycle
    //View Life Cycle modeled after AR Multipeer Demo
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mcService = MultipeerSession(receivedDataHandler: receivedData)
        
        userInstructions.text = "Move camera to map your surroundings\nTap on a flat surface to place your base"
        shareMapButton.isEnabled = false
        connectionLabel.text = "Searching for peers..."
        //Start MultiPeer Service once view loads
        //addBox()
        //addTapGestureToSceneView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                AR Not supported on device. Implement so that App won't be installed on devices
                that lack AR support so users don't see this message
            """) // For details, see https://developer.apple.com/documentation/arkit
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
    //this function isn't being called
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("cube") {
            baseNode = loadCube()
            node.addChildNode(baseNode)
        }
    }
    
    
    //MARK: - AR Session Delegate
    //Inform View of changes in quality of device position tracking
    //code to update in this case goes in this functon
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        // Update the UI to provide feedback on the state of the AR experience.
        let trackingState = camera.trackingState
        //let frame = session.currentFrame!
        switch trackingState {
            
        case .normal where !mcService.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            print("Connected with \(peerNames).")
            
//        case .notAvailable:
//            message = "Tracking unavailable."
//
//        case .limited(.excessiveMotion):
//            message = "Tracking limited - Move the device more slowly."
//
//        case .limited(.insufficientFeatures):
//            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
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
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if (!mcService.connectedPeers.isEmpty && mapProvider == nil) {
            let peerNames = mcService.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            print("Connected with \(peerNames).")
            connectionLabel.text = "Connected with: \(peerNames)"
        }
        
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            //Don't want to send data to each other if mapping status is limited or N/A
            shareMapButton.isEnabled = false
            print("MappingStatus: NA or Limited")
            //userInstructions.text = "NA/Limited"
        case .extending:
            //has mapped some areas but is currently mapping aournd current position
            shareMapButton.isEnabled = baseNode != nil && !mcService.connectedPeers.isEmpty
            print("MappingStatus: Extending")
            userInstructions.text = "Point all device cameras at the base location and tap the button to share your map!"
        case .mapped:
            //Mapped enough of the visible area
            shareMapButton.isEnabled = baseNode != nil && !mcService.connectedPeers.isEmpty
            print("MappingStatus: Mapped")
            userInstructions.text = "Point all device cameras at the base location and tap the button to share your map!"
        @unknown default:
            print("Unknown worldMappingStatus")
            //userInstructions.text = "Unknown"
            shareMapButton.isEnabled = false
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
    
    // MARK: - Session Observer
    func sessionWasInterrupted(_ session: ARSession) {
        print("Sessin was interrupted")
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
        
//        let tapLoc = sender.location(in: sceneView)
//        let objects = sceneView.hitTest(tapLoc)
//        for element in objects {
//            print("Element: \(element)")
//        }
//        let box = objects.first?.node
//        if box?.name == "boxNode" {
//            box?.removeFromParentNode()
//            return
//        }
        
        print("Handling Scene Tap")
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
            else { return }
        
        baseNode?.removeFromParentNode()  // Only allow one base to be placed at a time
        
        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
        let anchor = ARAnchor(name: "cube", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
        print("handleSceneTap: added anchor")
            
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        self.mcService.sendToAllPeers(data)
        // TODO: Add code that sends Anchor infor to other peers here for now.
    }
    
    var mapProvider: MCPeerID?
    
    // TODO: ADD Functionality to share the World Map data
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        print("Data received from \(peer)")
        do {
            if  mapFlag == false, let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("Getting worldmap")
                mapFlag = true
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                print("Getting anchor")
                // Add anchor to the session, ARSCNView delegate adds visible content.
                sceneView.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    @IBAction func handleShareMap(_ sender: Any) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.mcService.sendToAllPeers(data)
        }
        
        go_to_new_view_controller()
    }
    
    func go_to_new_view_controller() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }


}
