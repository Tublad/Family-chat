//
//  ListFriendTableView.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 10.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase

class ListFriendTableViewController: UITableViewController {
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    var cellId = "cellId"
    var timer: Timer?
    
    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        
        tableView.tableFooterView = UIView()
        textLabel.text = "Упссс.... Пока что у вас нет сообщений."
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.darkGray
        textLabel.textAlignment = .center
        textLabel.font = UIFont.boldSystemFont(ofSize: 30)
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        return textLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        
        tableView.backgroundColor = UIColor.white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Выйти", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.leftBarButtonItem?.tintColor = UIColor.black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(handleWriteMessage))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.black
        
        navigationController?.navigationBar.barTintColor = UIColor.customYellow
        navigationController?.navigationBar.isTranslucent = false 
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.separatorInset.left = 66
        tableView.separatorColor = UIColor.darkGray
        tableView.tableFooterView = UIView()
        
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    private func checkMessage() {
        if messagesDictionary.isEmpty {
            showControllerWithoutTableView()
            textLabel.isHidden = false
        } else {
            textLabel.isHidden = true 
        }
    }
    
    private func showControllerWithoutTableView() {
        tableView.addSubview(textLabel)
        
        textLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
        textLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        textLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
    }
    
    private func observeUserMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded, with: { [weak self] (snapshot) in
            
            let userId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { [weak self] (snapshot) in
                
                let messageId = snapshot.key
                self?.fetchMessageWithMessageId(messageId: messageId)
                
                }, withCancel: nil)
            
            }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { [weak self] (snapshot) in
            
            self?.messagesDictionary.removeValue(forKey: snapshot.key)
            self?.attemptReloadTable()
            
            }, withCancel: nil)
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        let messagesRefence = Database.database().reference().child("messages").child(messageId)
        
        messagesRefence.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            if let dict = snapshot.value as? [String: AnyObject] {
                
                let message = Message(dictionary: dict)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self?.messagesDictionary[chatPartnerId] = message
                    self?.attemptReloadTable()
                }
            }
            
            }, withCancel: nil)
        
    }
    
    private func attemptReloadTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    private func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            if let dict = snapshot.value as? [String: AnyObject] {
                
                let user = User(dictionary: dict)
                user.id = snapshot.key
                self?.setupNavBarWithUser(user: user)
            }
            
            }, withCancel: nil)
    }
    
    
    func setupNavBarWithUser(user: User) {
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let conteinerView = UIView()
        conteinerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(conteinerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.loadImageUsingCacheWithUrlString(urlString: user.profileUrl ?? "")
        conteinerView.addSubview(profileImageView)
        
        // x,y,wight, height constraint
        profileImageView.leftAnchor.constraint(equalTo: conteinerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: conteinerView.centerYAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        conteinerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // x,y,wight, height constraint
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: conteinerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // x,y,wight, height constraint
        conteinerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        conteinerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        self.attemptReloadTable()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            guard let dict = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User(dictionary: dict)
            user.id = chatPartnerId
            
            self?.showChatControllerForUser(user: user)
            }, withCancel: nil)
    }
    
    func showChatControllerForUser(user: User) {
        let chatMessageVC = ChatLogViewController(collectionViewLayout: UICollectionViewFlowLayout())
        chatMessageVC.user = user
        let backButton = UIBarButtonItem()
        backButton.title = "Назад"
        backButton.tintColor = .black
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        self.navigationController?.pushViewController(chatMessageVC, animated: true)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginVC = LoginViewController()
        loginVC.friendListVC = self
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
    }
    
    @objc func handleWriteMessage() {
        let newMessageVC = NewMessageTableViewController()
        let navController = UINavigationController(rootViewController: newMessageVC)
        navController.modalPresentationStyle = .fullScreen
        
        newMessageVC.messageController = self
        
        present(navController, animated: true, completion: nil)
    }
    
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp?.intValue ?? 0 > message2.timestamp?.intValue ?? 0
        })
        
        DispatchQueue.main.async {
            self.checkMessage()
            self.tableView.reloadData()
        }
    }
}

// MARK: Delegate

extension ListFriendTableViewController {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") {  (contextualAction, view, boolValue) in
            
            let refRemove = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId)
            refRemove.removeValue { [weak self] (error, ref) in
                
                if error != nil {
                    self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                    return
                }
                
                self?.messagesDictionary.removeValue(forKey: chatPartnerId)
                self?.attemptReloadTable()
            }
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return swipeActions
    }
}
