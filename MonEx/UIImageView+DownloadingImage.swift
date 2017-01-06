//
//  UIImageView+DownloadingImage.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/5/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//


import UIKit

extension UIImageView{
    
    func loadImage(url:URL) -> URLSessionDownloadTask{
        let session = URLSession.shared
        let downladTask = session.downloadTask(with: url, completionHandler: { [weak self] url, response, error  in
            
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data){
                
                DispatchQueue.main.async {
                    if let strongSelf = self{
                        strongSelf.image = image
                    }
                }
            }
        })
        
        downladTask.resume()
        return downladTask
    }
}
