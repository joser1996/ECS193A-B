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
        
        

    }
    
    @IBAction func confirmBaseLocation(_ sender: UIButton) {
        //No more Base Placing
        self.isPlacingBase = false
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
                
                print("STATE: \(state)")
                print("STATE: self \(self.gameState)")
                if self.gameState == GameState.WaitingForGame {
                    print("STATE: in if")
                    if state == "game"{
                        self.taskTimer.invalidate()
                        self.mainGameState()
                    }
                }
                
                
            } catch {
                print("JSON Error: \(error.localizedDescription)")
            }
            
        }
        
        checkStateTask.resume()
        
    }
    
    
    func mainGameState(){
        print("In Main Game")
        //listen for zombie wave
        
        //send response that wave was recieved
        
        //waiting for start signal
        
        //start game
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

