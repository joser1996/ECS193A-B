//
//  SyncViewController.swift
//  TestApp
//
//  Created by Cameron Brown on 2/15/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import ARKit

class SyncViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureToSceneView()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    func addTapGestureToSceneView(){
        print("hello\n")
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer){
        let tapLoc = recognizer.location(in: sceneView)
        
        print(tapLoc)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
