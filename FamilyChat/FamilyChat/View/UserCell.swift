//
//  UserCell.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 23.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            setupNameAndAvatar()
            guard let mes = message else { return }
            
            detailTextLabel?.text = mes.text
            
            let timestampDate = NSDate(timeIntervalSince1970: mes.timestamp?.doubleValue ?? 0)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a"
            
            timeLabel.text = dateFormatter.string(for: timestampDate)
        }
    }
    
    private func setupNameAndAvatar() {
        
        if let id = message?.chatPartnerId() {
            let ref = Database.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                if let dict = snapshot.value as? [String: AnyObject] {
                    self?.textLabel?.text = dict["name"] as? String
                    if let profileImageUrl = dict["profileImageUrl"] as? String {
                        self?.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                    }
                }
                }, withCancel: nil)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 76, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        
        detailTextLabel?.frame = CGRect(x: 76, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.lightGray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        // x,y,width, height anchors
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // x,y,width, height anchors
        guard let text = textLabel else { return }
        
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -5).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.centerYAnchor.constraint(equalTo: text.centerYAnchor).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: text.heightAnchor).isActive = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
