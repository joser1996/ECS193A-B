//
//  InventoryViewCell.swift
//  TestApp
//
//  Created by Jacob Smith on 4/20/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class InventoryViewCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    func loadThumbnailImage(baseUrlString: String, item: String, gameID: Int, playerName: String) {
        let urlString = "\(baseUrlString)/fetch-thumbnail/\(gameID)/\(playerName)/\(item)"
        let url = URL(string: urlString)
        guard let requestUrl = url else { fatalError() }
        
        print("Download Started")
        getData(from: requestUrl) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? requestUrl.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.imageView.image = UIImage(data: data)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

}
