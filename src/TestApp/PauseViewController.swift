//
//  PauseViewController.swift
//  TestApp
//
//  Created by David Mottle on 3/2/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

protocol PauseViewControllerDelegate: class {
    func pauseMenuUnPauseButtonPressed()
}

class PauseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
   
   weak var delegate: PauseViewControllerDelegate?
    
    init(delegate: PauseViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
   @IBAction func unPauseButtonPressed(_ sender: Any) {
        delegate?.pauseMenuUnPauseButtonPressed()
        self.navigationController!.popViewController(animated: true)
   }
    
    @IBAction func main_menu(_ sender: Any) {
        self.navigationController!.popToRootViewController(animated: true)
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
