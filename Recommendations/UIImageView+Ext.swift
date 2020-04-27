//
//  UIImageView+Ext.swift
//  Recommendations
//
//  Created by Joel on 4/27/20.
//  Copyright © 2020 Serial Box. All rights reserved.
//

import UIKit

extension UIImageView {
    func downloadImageFrom(link: String, contentMode: UIView.ContentMode) {
        guard let url = URL(string: link) else { return }
        
        URLSession.shared.dataTask( with: url, completionHandler: {
            (data, response, error) -> Void in
            DispatchQueue.main.async {
                self.contentMode =  contentMode
                if let data = data { self.image = UIImage(data: data) }
            }
        }).resume()
    }
}
