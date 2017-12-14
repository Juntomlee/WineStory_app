//
//  CustomerListTableViewController.swift
//  Project_W
//
//  Created by jun lee on 11/7/17.
//  Copyright © 2017 jun lee. All rights reserved.
//

import UIKit
import Firebase

class CustomerListTableViewController: UITableViewController {
    @IBAction func signOutButton(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("Goodbye!")
        } catch let signOutError {
            print("Error signing out: %@", signOutError)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    let ref = Database.database().reference()
    var reviews = [CustomerReview]()
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib.init(nibName: "CustomerListTableViewCell", bundle: nil), forCellReuseIdentifier: "customerCell")
        
        //FIREBASE//
        let reviewRef = ref.child("CustomerReview").queryOrdered(byChild: "vendorID").queryEqual(toValue: User.sharedInstance.email)
        reviewRef.observe(.value, with: { snapshot in
            var newItems: [CustomerReview] = []
            for item in snapshot.children {
                let reviewItem = CustomerReview(snapshot: item as! DataSnapshot)
                newItems.append(reviewItem)
            }
            self.reviews = newItems
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customerCell", for: indexPath) as! CustomerListTableViewCell
        cell.customerIDLabel.text = reviews[indexPath.row].customerID
        cell.customerReviewLabel.text = reviews[indexPath.row].review
        return cell
    }
}
