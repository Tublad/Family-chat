//
//  Extansion.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 08.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Foundation

// MARK: extansion UIColor

extension UIColor {
    
    static let customYellow = UIColor.init(r: 245, g: 221, b: 41)
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255,green: g/255, blue: b/255, alpha: 1)
    }
    
}

//MARK: extansion UIView

extension UIViewController {
    
    func showBasicAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func runActivityIndicator(){
        let indicatorView = UIActivityIndicatorView()
        indicatorView.startAnimating()
        indicatorView.style = .large
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.tag = 420
        self.view.addSubview(indicatorView)
        indicatorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        indicatorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        self.view.isUserInteractionEnabled = false
    }
    
    func stopActivityIndicator(){
        if let subViews = self.view.viewWithTag(420) {
            subViews.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
    }
}

// MARK: extansion UIImageView

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        // check cache for image first
        self.image = nil 
        
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject) {
            guard let image = cacheImage as? UIImage else { return }
            self.image = image
            return
        }
        // otherwise fire off a new download
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { (optData, responce, error) in
                
                // download hit an error so lets return out
                if error != nil {
                    print(error)
                    return
                }
                
                guard let data = optData else { return }
                
                DispatchQueue.main.async {
                    if let downloadedImage = UIImage(data: data) {
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                        self.image = downloadedImage
                    }
                }
            }.resume()
        }
    }
    
}
