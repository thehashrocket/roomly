//
//  CloudStorage.swift
//  Roomly
//
//  Created by Jason Shultz on 12/1/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class CloudStorage {
    
    static let instance = CloudStorage()
    
    func downloadImage(reference: String, completion: @escaping (UIImage) -> Void) {
        let storage = Storage.storage()
        var filename = NSString()
        let storageRef = storage.reference()
        let islandRef = storageRef.child("\(reference)")
        islandRef.getData(maxSize: 1 * 2048 * 2048) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print("downloadImage: ")
                print(error)
            } else {
                let image = UIImage(data: data!)
                completion(image!)
            }
        }
    }
    
    func loadTopImage(destination: String, saved_image: String, completion: @escaping (UIImage) -> Void) {
        print("this destination " + destination)
        CloudData.instance.getImages(destination: destination) { (fire_images) in
            print("destination " + destination)
            if (fire_images.count > 0) {
                let image_key = fire_images[0]
                let reference = "images/" + destination + "\(image_key)"
                
                CloudStorage.instance.downloadImage(reference: reference, completion: { (image) in
                    completion(image)
                })
            } else {
                if (saved_image != "") {
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(saved_image as String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    completion(image!)
                }
            }
        }
    }
    
    func saveImageToFirebase(key: String, image: UIImage, user_id: String, destination: String, second_key: String? = nil) {
        let storage = Storage.storage()
        var filename = NSString()
        let storageRef = storage.reference()
        let image_key = randomString(length: 20)
        var imagesRef = storageRef
        
        switch destination {
        case "buildings":
            imagesRef = storageRef.child("images").child("\(destination)").child(user_id).child(key).child("\(image_key).jpg")
        default:
            imagesRef = storageRef.child("images").child("\(destination)").child(user_id).child(second_key!).child(key).child("\(image_key).jpg")
        }
        
        let resizedImage = resizeImage(image: image, targetSize: CGSize.init(width: 2048, height: 2048))
        var data = NSData()
        data = UIImageJPEGRepresentation(resizedImage, 0.8)! as NSData
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        let uploadTask = imagesRef.putData(data as Data, metadata: metaData) { (metadata, error) in
            if let error = error {
                print("saveImageToFirebase: ")
                print(error)
                // Uh-oh, an error occurred!
            } else {
                filename = "\(image_key).jpg" as NSString
                CloudData.instance.addImagesToRecord(key: key, image: filename as String, user_id: user_id, destination: destination, second_key: second_key)
            }
        }
    }
    
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
}
