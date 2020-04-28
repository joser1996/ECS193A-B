//
//  InventoryViewController.swift
//  TestApp
//
//  Created by Jacob Smith on 4/18/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class InventoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let reuseIdentifier = "CellIdentifier"
    var items: [String] = []
    var numItems = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        //collectionView.register(InventoryViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
         super.didReceiveMemoryWarning()
         // Dispose of any resources that can be recreated.
     }
     
     //UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
     {
         
         return 4;
     }
    
    // Determine cell size
    func collectionView(_ collectionView: UICollectionView,
           layout collectionViewLayout: UICollectionViewLayout,
           sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
//     func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
//     {
//
//         return 1;
//     }
     
     
     //UICollectionViewDatasource methods
//     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//
//         return 1
//     }
     
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return numItems
     }
     
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! InventoryViewCell
    
        cell.backgroundColor = self.randomColor()
        
        let index = indexPath[0] + indexPath[1]
        cell.label.text = items[index]
        
        print(indexPath)
        
        return cell
    }

     // custom function to generate a random UIColor
     func randomColor() -> UIColor{
         let red = CGFloat(drand48())
         let green = CGFloat(drand48())
         let blue = CGFloat(drand48())
         return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
     }
    
    @IBAction func exitScanAndSaveItem(unwindSegue: UIStoryboardSegue) {
        if let sourceVC = unwindSegue.source as? ScanViewController {
            numItems += 1
            print("Item saved, now there are " + String(numItems) + " items.")
            print("Added " + sourceVC.item)
            items.append(sourceVC.item)
            collectionView.reloadData()
        }
    }

    @IBAction func exitScanAndTrashItem(unwindSegue: UIStoryboardSegue) {
        print("Item trashed!")
    }
    
    
}
