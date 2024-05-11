//
//  ViewController.swift
//  LLWebImagePicker
//
//  Created by ZHK1024 on 05/11/2024.
//  Copyright (c) 2024 ZHK1024. All rights reserved.
//

import UIKit
import LLWebImagePicker

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imageView.contentMode = .scaleAspectFit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pickAction(_ sender: UIBarButtonItem) {
        let controller = LLWebImagePickerController()
        controller.delegate = self
        controller.keywords = "太荒吞天诀"
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ViewController: LLWebImagePickerControllerDelegate {
    
    func picker(_ controller: LLWebImagePicker.LLWebImagePickerController, didFinish image: UIImage) {
        imageView.image = image
        navigationController?.popViewController(animated: true)
    }
    
    func picker(_ controller: LLWebImagePicker.LLWebImagePickerController, didFail error: any Error) {
        print(error)
    }
}

