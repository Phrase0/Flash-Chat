//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    //創建Firestore數據庫
    let db = Firestore.firestore()
    
    var messages:[Message] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //隱藏back按鈕
        navigationItem.hidesBackButton = true
        //設定tableView dataSource
        tableView.dataSource = self
        
        //使用自定義設計的文件(自定義xib文件)的第一步是在viewDidLoad註冊他
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        //提取數據庫中所有當前數據
        loadMessages()
    }
    
    
    func loadMessages(){
        //取得資料
        // SnapshotListener: each time the contents change, another call updates the document snapshot
        //order(by: String): 排序
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { [self] (querySnapshot, error) in
            
            //清空messages資料
            self.messages = []
            
            if let error = error {
                print("There was an issue retrieving data from Firestore, \(error)")
            } else {
                //querySnapshot:訪問該查詢的快照對象，並獲取其中包含的數據
                if let snapshotDocuments = querySnapshot?.documents{
                    for doc in snapshotDocuments{
                        //data() -> [String:Any]
                        let data = doc.data()
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String{
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            //呼叫tableView
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                //創建要滾動到的行
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    //送出按鈕
    @IBAction func sendPressed(_ sender: UIButton) {
        
        if messageTextfield.text != ""{
            
            if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email{
                //            K.FStore.collectionName = "messages"
                //            K.FStore.senderField = "sender"
                //            K.FStore.bodyField = "body"
                //            K.FStore.dateField = "date"
                db.collection(K.FStore.collectionName).addDocument(data:[
                    //上傳的資料
                    K.FStore.senderField: messageSender,
                    K.FStore.bodyField: messageBody,
                    K.FStore.dateField: Date().timeIntervalSince1970
                ]) { error in
                    if let error = error{
                        print("There was an issue saving data to firestore, \(error)")
                    }else{
                        print("Successfully saved data")
                        DispatchQueue.main.async {
                            self.messageTextfield.text = ""
                        }
                    }
                }
            }
        }
        
    }
    
    
    //logOut按鍵
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            //回到根畫面
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}


//MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource{
    //有幾列
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    //表格中的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        //檢查訊息發送者是否與當前登入的用戶相同
        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
}
