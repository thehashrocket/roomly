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
    
    func deleteCloudImage(reference: String, image:(key: Any, value: Any), completion: @escaping (UIImage?, Error?) -> Void) {
        
    }
    
    func downloadCloudImage(reference: String, image_key: String, completion: @escaping (UIImage?, Error?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let islandRef = storageRef.child("\(reference)/\(image_key)")
        
        islandRef.getData(maxSize: 1 * 2048 * 2048) { data, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print("downloadCloudImage: ")
                print(error)
                completion(nil, error)
            } else {
                let image = UIImage(data: data!)
                CloudStorage.instance.saveImageToDocumentDirectory(image!, image_key: image_key)
                completion(image!, nil)
            }
        }
    }
    
    func downloadImage(reference: String, image_key: String, completion: @escaping (UIImage?, Error?) -> Void) {
        DataService.instance.checkIfImageDirectoryExists()
        let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(image_key as String)
        let image = UIImage(contentsOfFile: imageURL.path)
        if ((image) != nil) {
            completion(image!, nil)
        } else {
            let image = CloudStorage.instance.downloadCloudImage(reference: reference, image_key: image_key, completion: { (image, error) in
                if let error = error {
                    print("i am in error")
                    completion(nil, error)
                } else {
                    completion(image, nil)
                }
            })
        }
    }
    
    func loadTopImage(destination: String, saved_image: String, completion: @escaping (UIImage?, Error?) -> Void) {
        CloudData.instance.getImages(destination: destination) { (fire_images) in
            if (fire_images.count > 0) {
                let image_key = fire_images[0]
                let reference = "images/" + destination
                
                CloudStorage.instance.downloadImage(reference: reference, image_key: image_key, completion: { (image, error) in
                    if let error = error {
                        completion(nil, error)
                        
                    } else {
                        completion(image, nil)
                    }
                })
            } else {
                if (saved_image != "") {
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(saved_image as String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    completion(image!, nil)
                }
            }
        }
    }
    
    func moveImage(origin: String, destination: String, new_room: String, user_id: String, item_id: String) -> Void {
        DataService.instance.checkIfImageDirectoryExists()
        CloudData.instance.getImages(destination: origin) { (fire_images) in
            if (fire_images.count > 0) {
                fire_images.forEach({ (fire_image) in
                    let ref_origin = "images/" + destination + "/\(fire_image)"
                    CloudStorage.instance.downloadImage(reference: ref_origin, image_key: fire_image, completion: { (image, error) in
                        var filename = NSString()
                        let storage = Storage.storage()
                        let storageRef = storage.reference()
                        var imagesRef = storageRef
                        imagesRef = storageRef.child("images").child(destination).child("\(fire_image)")
                        let resizedImage = self.resizeImage(image: image!, targetSize: CGSize.init(width: 2048, height: 2048))
                        var data = NSData()
                        data = UIImageJPEGRepresentation(resizedImage, 0.8)! as NSData
                        let metaData = StorageMetadata()
                        metaData.contentType = "image/jpg"
                        
                        let uploadTask = imagesRef.putData(data as Data, metadata: metaData) { (metadata, error) in
                            if let error = error {
                                // Uh-oh, an error occurred!
                                print("saveImageToFirebase: ")
                                print(error)
                            } else {
                                print("uploaded file")
                                filename = "\(fire_image)" as NSString
                                CloudData.instance.addImagesToRecord(key: item_id, image: filename as String, user_id: user_id, destination: "items", second_key: new_room)
                                let deleteRef = storageRef.child(ref_origin)
                                deleteRef.delete { error in
                                    if let error = error {
                                        // Uh-oh, an error occurred!
                                        print("deletion failed")
                                        print(error)
                                    } else {
                                        // File deleted successfully
                                        print("filed successfully deleted")
                                    }
                                }
                            }
                        }
                    })
                    
                })
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
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage, image_key: String) -> String {
        
        let filepath = IMAGE_DIRECTORY_PATH + "/".appending(image_key)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try UIImageJPEGRepresentation(chosenImage, 1.0)?.write(to: url, options: .atomic)
            return String.init("\(image_key)")
            
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
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
    
}
