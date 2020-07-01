//
//  LoginViewController.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 10.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var friendListVC: ListFriendTableViewController?
    
    lazy var inputConteinerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        return view
    }()
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.black
        button.setTitle("Регистрация", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(handelLoginRegister), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handelLoginRegister() {
        if loginRegisterSegmentControl.selectedSegmentIndex == 0 {
            handleLoginAction()
        } else {
            handleRegisterAction()
        }
    }
    
    @objc func handleLoginAction() {
        guard let email = emailTextField.text, emailTextField.text?.count ?? 0 > 0,
            let password = passwordTextField.text, passwordTextField.text?.count ?? 0 > 0 else {
                showBasicAlert(title: "Вы заполнели не все поля", message: "")
                return
        }
        
        runActivityIndicator()
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            
            if error != nil {
                self?.stopActivityIndicator()
                self?.showBasicAlert(title: "Ошибка", message: error!.localizedDescription)
                return
            }
            
            self?.stopActivityIndicator()
            self?.friendListVC?.fetchUserAndSetupNavBarTitle()
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Имя"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    lazy var nameSeparationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Почта"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    lazy var emailSeparationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Пароль "
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    lazy var passwordSeparationView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon")
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        
        imageView.isUserInteractionEnabled = true 
        return imageView
    }()
    
    lazy var loginRegisterSegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Войти","Зарегистрироваться"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.tintColor = UIColor.white
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.customYellow
        
        view.addSubview(inputConteinerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentControl)
        
        setupInputConteinerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
    }
    
    private func setupLoginRegisterSegmentedControl() {
        // x, y, w, h constraint
        loginRegisterSegmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentControl.bottomAnchor.constraint(equalTo: inputConteinerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentControl.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor, multiplier: 1).isActive = true
        loginRegisterSegmentControl.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    private func setupProfileImageView() {
        //x, y, w, h constraint
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    var inputConteinerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTexfFieldHeightAnchor: NSLayoutConstraint?
    
    private func setupInputConteinerView() {
        
        //x, y, w, h constraint
        inputConteinerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputConteinerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputConteinerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        
        inputConteinerViewHeightAnchor = inputConteinerView.heightAnchor.constraint(equalToConstant: 150)
        inputConteinerViewHeightAnchor?.isActive = true
        
        inputConteinerView.addSubview(nameTextField)
        inputConteinerView.addSubview(nameSeparationView)
        inputConteinerView.addSubview(emailTextField)
        inputConteinerView.addSubview(emailSeparationView)
        inputConteinerView.addSubview(passwordTextField)
        inputConteinerView.addSubview(passwordSeparationView)
        
        // x, y, w, h constraint
        nameTextField.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputConteinerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        // x, y, w, h constraint
        
        nameSeparationView.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor).isActive = true
        nameSeparationView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparationView.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        nameSeparationView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // x, y, w, h constraint
        emailTextField.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        // x, y, w, h constraint
        emailSeparationView.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor).isActive = true
        emailSeparationView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparationView.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        emailSeparationView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // x, y, w, h constraint
        passwordTextField.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        passwordTextField.isSecureTextEntry = true
        
        passwordTexfFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: 1/3)
        passwordTexfFieldHeightAnchor?.isActive = true
        
        // x, y, w, h constraint
        passwordSeparationView.leftAnchor.constraint(equalTo: inputConteinerView.leftAnchor).isActive = true
        passwordSeparationView.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor).isActive = true
        passwordSeparationView.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        passwordSeparationView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    private func setupLoginRegisterButton() {
        // x, y, w, h constraint
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputConteinerView.bottomAnchor, constant: 15).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputConteinerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
}

extension LoginViewController {
    
    @objc func handleLoginRegisterChange() {
        let title = loginRegisterSegmentControl.titleForSegment(at: loginRegisterSegmentControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        inputConteinerViewHeightAnchor?.constant = loginRegisterSegmentControl.selectedSegmentIndex == 0 ? 100 : 150
        
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: loginRegisterSegmentControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: loginRegisterSegmentControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTexfFieldHeightAnchor?.isActive = false
        passwordTexfFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputConteinerView.heightAnchor, multiplier: loginRegisterSegmentControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTexfFieldHeightAnchor?.isActive = true
    }
}
