//
//  NewMessageTableVC.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 18.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase

class NewMessageTableViewController: UITableViewController {
    
    let cellId: String = "cellId"
    
    var messageController: ListFriendTableViewController?
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.separatorInset.left = 66
        tableView.separatorColor = UIColor.darkGray
        tableView.tableFooterView = UIView()
        
        navigationItem.title = "Новое сообщение"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Отменить", style: .plain, target: self, action: #selector(backButton))
        navigationItem.leftBarButtonItem?.tintColor = UIColor.black
        
        navigationController?.navigationBar.barTintColor = UIColor.customYellow
        navigationController?.navigationBar.isTranslucent = false 
        
        fetchUser()
    }
    
    func fetchUser() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("users").observe(.childAdded, with: { [weak self] (snapshot) in
            if let dict = snapshot.value as? [String: AnyObject] {
                
                if uid != snapshot.key {
                    let user = User(dictionary: dict)
                    user.id = snapshot.key
                    self?.users.append(user)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
            }, withCancel: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else { return UITableViewCell() }
        
        //        cell.backgroundColor = UIColor.white
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        if let profileUrl = user.profileUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileUrl)
        }
        return cell
    }
}

// MARK: Delegate

extension NewMessageTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messageController?.showChatControllerForUser(user: user)
        }
    }
    
    @objc func backButton() {
        dismiss(animated: true, completion: nil)
    }
    
}

