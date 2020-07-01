//
//  ChatLogViewController.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 22.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogViewController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var messages = [Message]()
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid,
            let toId = user?.id else { return }
        
        let userMessageRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessageRef.observe(.childAdded, with: { [weak self] (snapshot) in
            
            let messagesId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messagesId)
            messagesRef.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                
                guard let dict = snapshot.value as? [String: AnyObject] else  {
                    return
                }
                let message = Message(dictionary: dict)
                
                self?.messages.append(message)
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                    if let count = self?.messages.count {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self?.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                }
                
                }, withCancel: nil)
            
            }, withCancel: nil)
    }
    
    var cellId: String = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        navigationController?.navigationBar.barTintColor = UIColor.customYellow
        navigationController?.navigationBar.isTranslucent = false
        
        collectionView.keyboardDismissMode = .interactive
        setupKeyboardObserve()
    }
    
    lazy var inputConteinerView: ChatInputConteinerView = {
        let chatInputConteinerView = ChatInputConteinerView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        chatInputConteinerView.chatLogViewController = self
        return chatInputConteinerView
    }()
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .fullScreen
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoUrl = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerMediaURL")] as? NSURL {
            // we selected an video
            handleVideoSelectedForUser(videoUrl)
        } else {
            // we selected an image
            handleImageSelectedForInfo(info)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUser(_ NSUrl: NSURL) {
        runActivityIndicator()
        guard let stringMediaUrl = NSUrl.absoluteString,
            let localFile = URL(string: stringMediaUrl) else { return }
        
        let filename = NSUUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_movies").child(filename)
        let uploadTask = ref.putFile(from: localFile, metadata: nil) {  [weak self] (metadata, error) in
            
            if error != nil {
                self?.showBasicAlert(title: "Ошибка при загрузки видео", message: error!.localizedDescription)
                return
            }
            
            ref.downloadURL { [weak self] (url, error) in
                
                if error != nil {
                    self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                    return
                }
                
                if let videoUrl = url?.absoluteString {
                    if let thumbnailImage = self?.thumbnailImageForFileUrl(NSUrl) {
                        
                        self?.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { [weak self] (imageUrl) in
                            
                            let properties: [String: AnyObject] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl] as [String: AnyObject]
                            self?.sendMessageWithProperties(properties: properties)
                            
                        })
                    }
                }
            }
        }
        
        uploadTask.observe(.progress) { [weak self] (snapshot) in
            if let complitedUnitCount = snapshot.progress?.completedUnitCount {
                self?.navigationItem.title = String(complitedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { [weak self] (snapshot) in
            self?.stopActivityIndicator()
            self?.navigationItem.title = self?.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(_ fileUrl: NSURL) -> UIImage? {
        
        guard let stringMediaUrl = fileUrl.absoluteString,
            let localFile = URL(string: stringMediaUrl) else { return UIImage() }
        
        let asset = AVAsset(url: localFile)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60),
                                                                  actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let error {
            showBasicAlert(title: "Ошибка", message: error.localizedDescription)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(_ info:[UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editingImage = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            selectedImageFromPicker = editingImage
        } else if let originalImage = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(selectedImage) { (imageUrl) in
                self.sendMessageWithUrl(imageUrl: imageUrl, image: selectedImage)
            }
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping(String) -> ()) {
        let imageName = NSUUID().uuidString
        
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = image.jpegData(compressionQuality: 0.2) {
            
            ref.putData(uploadData, metadata: nil) { [weak self] (metadata, error) in
                
                if error != nil {
                    self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                    return
                }
                
                ref.downloadURL { [weak self] (url, error) in
                    
                    if error != nil {
                        self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                        return
                    }
                    
                    if let urlString = url?.absoluteString {
                        completion(urlString)
                    }
                    
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputConteinerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObserve() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count  - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var conteinerViewBottomAnchor: NSLayoutConstraint?
    
    //    MARK: Custom Zooming Logic Image
    
    var startingFrame: CGRect?
    var blackBackgroungView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForStartingImageView(_ startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        guard let starFrame = startingFrame else { return }
        
        let zoomingImageView = UIImageView(frame: starFrame)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroungView = UIView(frame: keyWindow.frame)
            blackBackgroungView?.backgroundColor = UIColor.black
            blackBackgroungView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroungView ?? UIView())
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut,
                           animations: {
                            self.blackBackgroungView?.alpha = 1
                            self.inputConteinerView.alpha = 0
                            
                            let height = starFrame.height / starFrame.width * keyWindow.frame.width
                            
                            zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                            
                            zoomingImageView.center = keyWindow.center
            }) { (completed) in
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut,
                           animations: {
                            
                            self.blackBackgroungView?.alpha = 1
                            self.inputConteinerView.alpha = 0
                            
                            let height = starFrame.height / starFrame.width * keyWindow.frame.width
                            
                            zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                            
                            zoomingImageView.center = keyWindow.center
                            
            }, completion: nil)
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            //need to animate back out to controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true 
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut,
                           animations: {
                            if let startFrame = self.startingFrame {
                                self.blackBackgroungView?.alpha = 0
                                zoomOutImageView.frame = startFrame
                                self.inputConteinerView.alpha = 1
                            }
            }) { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            }
        }
    }
}

// MARK: DataSource

extension ChatLogViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else {
            return UICollectionViewCell()
        }
        
        cell.chatLogController = self 
        
        let message = messages[indexPath.item]
        
        cell.message = message 
        
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            
            cell.bubbleWidhtAnchor?.constant = estimatedFrameForText(text: text).width + 30
            cell.textView.isHidden = false
            
        } else if message.imageUrl != nil {
            
            cell.bubbleWidhtAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let profileImageUrl = user?.profileUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            // outgoing black
            cell.bubbleView.backgroundColor = UIColor.black
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = ChatMessageCell.lightGrayColor
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            // outgoing gray
        }
        
        if let messageImageUrl = message.imageUrl {
            if !messageImageUrl.isEmpty {
                cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
                cell.messageImageView.isHidden = false
                cell.bubbleView.backgroundColor = UIColor.clear
            }
        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimatedFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue , let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrameForText(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size,
                                                   options: options,
                                                   attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)],
                                                   context: nil)
    }
}

extension ChatLogViewController {
    
    @objc func handleSend() {
        guard let text = self.inputConteinerView.inputTextField.text, text.count > 0 else { return }
        let properties = ["text": text] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithUrl(imageUrl: String, image: UIImage) {
        let properties: [String: AnyObject] = ["imageUrl": imageUrl,
                                               "imageWidth": image.size.width, "imageHeight": image.size.height] as [String: AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        guard let users = self.user,
            let fromId = Auth.auth().currentUser?.uid,
            let toId = users.id else { return }
        let timestamp: NSNumber = NSNumber(value: NSDate().timeIntervalSince1970)
        
        var values: [String: AnyObject] = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : AnyObject]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { [weak self] (error, ref) in
            
            if error != nil {
                self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                return
            }
            
            self?.inputConteinerView.inputTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            
            if let messageId = childRef.key {
                userMessageRef.updateChildValues([messageId: 1])
                
                let recepientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
                recepientUserMessagesRef.updateChildValues([messageId: 1])
            }
        }
    }
}
