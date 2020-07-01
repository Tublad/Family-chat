//
//  LoginViewController + handlers.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 19.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase

extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    @objc func handleRegisterAction() {
        guard let email = emailTextField.text, emailTextField.text?.count ?? 0 > 0,
            let name = nameTextField.text, nameTextField.text?.count ?? 0 > 0,
            let password = passwordTextField.text, passwordTextField.text?.count ?? 0 > 0 else {
                showBasicAlert(title: "Вы заполнели не все поля", message: "")
                return
        }
        
        // registration action
        runActivityIndicator()
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (user: AuthDataResult?, error) in
            
            if error != nil {
                self?.stopActivityIndicator()
                self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
            }
            
            guard let uid = user?.user.uid else { return }
            
            let imageName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_Images").child("\(imageName).jpg")
            
            if let uploadData = self?.profileImageView.image?.jpegData(compressionQuality: 0.1) {
                
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    
                    if error != nil {
                        self?.stopActivityIndicator()
                        self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                        return
                    }
                    
                    storageRef.downloadURL { (url, error) in
                        if error != nil {
                            self?.stopActivityIndicator()
                            self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                            return
                        }
                        
                        if let urlString = url?.absoluteString {
                            let value = ["name": name, "email": email, "profileImageUrl": urlString]
                            self?.registerUserIntoDatabase(uid: uid, value: value)
                        }
                    }
                }
            }
        }
    }
    
    private func registerUserIntoDatabase(uid: String, value: [String: String]) {
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(value) { [weak self] (err, ref) in
            
            if err != nil {
                self?.stopActivityIndicator()
                self?.showBasicAlert(title: "Ошибка", message: err!.localizedDescription)
            }
            self?.stopActivityIndicator()
            
            if let dict = value as? [String: AnyObject] {
                
                let user = User(dictionary: dict)
                
                self?.friendListVC?.setupNavBarWithUser(user: user)
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editingImage = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            selectedImageFromPicker = editingImage
        } else if let originalImage = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
