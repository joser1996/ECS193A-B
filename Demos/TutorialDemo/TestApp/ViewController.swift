//
//  ViewController.swift
//  TestApp
//
//  Created by Jose Torres on 1/22/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    
    
    
    // MARK: Multipeer Implementation
    let mcService = MultipeerService()
    
    
    
    //MARK: View Life Cycle
    //View Life Cycle modeled after AR Multipeer Demo
    override func viewDidLoad() {
        super.viewDidLoad()
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
        print("rederer: attempting to add cube")
        if let name = anchor.name, name.hasPrefix("cube") {
            node.addChildNode(loadCube())
            print("Added Cube Node")
        }
    }
    
    
    //MARK: - AR Session Delegate
    //Inform View of changes in quality of device position tracking
    //code to update in this case goes in this functon
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Update Session Info Label of Status
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            //Don't want to send data to each other if mapping status is limited or N/A
            //sendMapButton.isEnabled = false
            print("MappingStatus: NA or Limited")
        case .extending:
            //has mapped some areas but is currently mapping aournd current position
            //sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
            print("MappingStatus: Extending")
        case .mapped:
            //Mapped enough of the visible area
            //sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
            print("MappingStatus: Mapped")
        @unknown default:
            print("Unknown worldMappingStatus")
        }
    }
    
    
    // MARK: - AR session management
    private func loadCube() -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = box
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
    print("Handling Scene Tap")
    // Hit test to find a place for a virtual object.
    guard let hitTestResult = sceneView
        .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
        .first
        else { return }
    
    // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
    let anchor = ARAnchor(name: "cube", transform: hitTestResult.worldTransform)
    sceneView.session.add(anchor: anchor)
    print("handleSceneTap: added anchor")
    // TODO: Add code that sends Anchor infor to other peers here for now.
    
    }
    
    // TODO: ADD Functionality to share the World Map data
    
    
    // TODO: Functionality to recieve map data
    
//    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer){
//        let tapLoc = recognizer.location(in: sceneView)
//        let hitTestResults = sceneView.hitTest(tapLoc)
//        guard let node = hitTestResults.first?.node else {
//            let hitTestResultsWithFeatPts = sceneView.hitTest(tapLoc, types: .featurePoint)
//            if let hitTestResultsWithFeatPts = hitTestResultsWithFeatPts.first{
//                let translation = hitTestResultsWithFeatPts.worldTransform.translation
//                addBox(x: translation.x, y: translation.y, z: translation.z)
//            }
//            return
//
//        }
//
//        node.removeFromParentNode()
//    }
    
}



extension float4x4{
    var translation: SIMD3<Float>{
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}

