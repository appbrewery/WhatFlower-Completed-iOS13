//
//  ViewController.swift
//  WhatFlower
//
//  Created by Angela Yu on 01/07/2017.
//  Copyright © 2017 Angela Yu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage
import ColorThiefSwift


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var pickedImage : UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let userPickedImage = info[.originalImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage.")
            }
            
            pickedImage = userPickedImage
            
            
            detect(flowerImage: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
        
        
    }
    
    func detect(flowerImage: CIImage) {
        
        
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Can't load model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not complete classfication")
            }
      
            self.navigationItem.title = result.identifier.capitalized
            
            self.requestInfo(flowerName: result.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
        
        
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : flowerName, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]
                
        AF.request(wikipediaURl, parameters: parameters).responseData { response in
            
            switch response.result {
                case .success(let data):
                   do{
                       let flowerJSON = try JSON(data: data)
                                           
                       let pageid = flowerJSON["query"]["pageids"][0].stringValue
                       
                       let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                       
                       let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                       
                       self.infoLabel.text = flowerDescription
                       
                       self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: { (image, error,  cache, url) in
                           
                           if let currentImage = self.imageView.image {
                               
                               guard let dominantColor = ColorThief.getColor(from: currentImage) else {
                                   fatalError("Can't get dominant color")
                               }
                               
                               
                               DispatchQueue.main.async {
                                   self.navigationController?.navigationBar.isTranslucent = true
                                   self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                                   
                                   
                               }
                           } else {
                               self.imageView.image = self.pickedImage
                               self.infoLabel.text = "Could not get information on flower from Wikipedia."
                           }
                           
                       })
                   }
                   catch{
                       print("Error \(String(describing: error))")
                   }
                case .failure(let error):
                     print("Error \(String(describing: error))")
                     self.infoLabel.text = "Connection Issues"
            }
        }
    }
    
    
    
    @IBAction func cameraTapped(_ sender: Any) {
        
        self.present(self.imagePicker, animated: true, completion: nil)

    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
