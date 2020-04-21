//
//  ScanViewController.swift
//  TestApp
//
//  Created by Jacob Smith on 3/30/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ScanViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //var imagePicker: UIImagePickerController!
    weak var delegate: ScanViewControllerDelegate?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    @IBOutlet weak var addItemButton: UIButton!
    
    var item: String! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        classificationLabel.text = nil
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
//            presentPhotoPicker(sourceType: .photoLibrary)
            // Label: unable to scan
            return
        }
        
        addItemButton.isEnabled = false
        
        presentPhotoPicker(sourceType: .camera)
    }
     
     init(delegate: ScanViewControllerDelegate) {
         self.delegate = delegate
         super.init(nibName: nil, bundle: nil)
     }
     
     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
     }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView.image = image
        updateClassifications(for: image)
    }
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             Use the Swift class `MobileNet` Core ML generates from the model.
             To use a different Core ML classifier model, add it to the project
             and replace `MobileNet` with that model's generated Swift class.
             */
            let model = try VNCoreMLModel(for: Resnet50().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else if classifications[0].confidence > 0.7 {
                // Display top classifications ranked by confidence in the UI
                let possibleItems = classifications[0].identifier.split(separator: ",", maxSplits: 2)
                let description = String(format: "Item found: %@", String(possibleItems[0]))
                self.classificationLabel.text = description
                self.item = description
                self.addItemButton.isEnabled = true
            }
            else {
                self.classificationLabel.text = "Could not detect item."
            }
        }
    }
}

protocol ScanViewControllerDelegate: class {
    func returnToGame()
}
