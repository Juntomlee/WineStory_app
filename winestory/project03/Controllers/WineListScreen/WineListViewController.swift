//
//  WineListViewController.swift
//  Project_W
//
//  Created by jun lee on 10/23/17.
//  Copyright © 2017 jun lee. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class WineListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    // MARK: Properties
    var wineList = [WineInfo]()
    var filteredList = [WineInfo]()
    var selectedWine: WineInfo?
    var listOfLabel = [String:UIImage]()
    var items: [WineInfo] = []
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    var isSearching = false
    var keyword = String()
    
    // MARK: Outlets
    @IBOutlet weak var wineListTableView: UITableView!
    @IBOutlet weak var wineSearch: UISearchBar!
    
    // MARK: Actions
    @IBAction func signOutButton(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("Goodbye!")
        } catch let signOutError {
            print ("Error signing out: %@", signOutError)
        }
        dismiss(animated: true, completion: nil)
    }
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Indicators.progressIndicator(self.view, startAnimate: true)
        searchController.searchBar.delegate = self
        wineListTableView.register(UINib.init(nibName: "WineListTableViewCell", bundle: nil), forCellReuseIdentifier: "wineListCell")


        //Load list of wines from Firebase
        let wineRef = ref.child("Vendor").queryOrdered(byChild: "vendorID").queryEqual(toValue: User.sharedInstance.email)
        wineRef.observe(.value, with: { snapshot in

            print(snapshot.childrenCount)
            var newItems: [WineInfo] = []
            self.listOfLabel.removeAll()
            for item in snapshot.children {
                let wineItem = WineInfo(snapshot: item as! DataSnapshot)
                newItems.append(wineItem)

                let url = URL(string: wineItem.thumbnail)
                let savedImage = try? Data(contentsOf: url!)
                self.listOfLabel[wineItem.code] = UIImage(data: savedImage!)!
                print(wineItem.name)
            }
            
            self.wineList = newItems
            print("count", self.wineList.count)
            self.wineListTableView.reloadData()
            Indicators.progressIndicator(self.view, startAnimate: false)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let wineRef = ref.child("Vendor").queryOrdered(byChild: "vendorID").queryEqual(toValue: User.sharedInstance.email)
        wineRef.observe(.value, with: { snapshot in
            var newItems: [WineInfo] = []
            
            for item in snapshot.children {
                let wineItem = WineInfo(snapshot: item as! DataSnapshot)
                newItems.append(wineItem)
            }
            
            self.wineList = newItems
            self.wineListTableView.reloadData()
        })
        wineSearch.delegate = self
        wineSearch.returnKeyType = UIReturnKeyType.done
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if wineSearch.text == nil || wineSearch.text == "" {
            isSearching = false
            view.endEditing(true)
            wineListTableView.reloadData()
        } else {
            isSearching = true
            let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
            switch scope {
            case "Name":
                self.filteredList = self.wineList.filter({$0.name.uppercased().contains(searchText.uppercased())})
            case "Wine Type":
                self.filteredList = self.wineList.filter({$0.wineType.uppercased().contains(searchText.uppercased())})
            case "Low Qty":
                self.filteredList = self.wineList.filter({$0.quantity == 0})
            default:
                print("Filter error")
            }
            self.wineListTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.wineListTableView.reloadData()
        DispatchQueue.main.async {
            self.isSearching = false;
            self.wineSearch.endEditing(true)
        }
    }
    
    //MARK: Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching{
            return filteredList.count
        } else {
            return wineList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wineListCell", for: indexPath) as! WineListTableViewCell
        var currentWine = wineList[indexPath.row]
        
        if isSearching{
            currentWine = filteredList[indexPath.row]
        } else {
            currentWine = wineList[indexPath.row]
        }
        cell.accessoryType = .disclosureIndicator

        cell.nameLabel.text = currentWine.name + " (\(currentWine.vintage))"
        cell.vineyardLabel.text = currentWine.vineyard
        cell.grapeTypeLabel.text = currentWine.wineType
        cell.priceLabel.text = "$\(Int(currentWine.vendorPrice))"
        cell.quantityLabel.text = "Qty: \(currentWine.quantity)"
        cell.ratingLabel.text = "⭐️ \(currentWine.rating)"
        cell.labelImage.image = listOfLabel[currentWine.code]
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = wineListTableView.indexPathForSelectedRow!
        let cell = wineListTableView.cellForRow(at: indexPath)! as! WineListTableViewCell
        
        selectedWine = wineList[indexPath.row]
        performSegue(withIdentifier: "editView", sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ref.child("Vendor").child("\(wineList[indexPath.row].code)_\(wineList[indexPath.row].vendorID)").removeValue()
            
            //Delete original and thumbnail image from the storage
            let thumbnailRef = storageRef.child("thumbnail/\(wineList[indexPath.row].uuid)_small.jpg")
            let originalRef = storageRef.child("\(wineList[indexPath.row].uuid).jpg")
            thumbnailRef.delete(completion: { (error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Successfully deleted")
                }
            })
            originalRef.delete(completion: { (error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Successfully deleted")
                }
            })
            wineList.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    // MARK: - Navigation : Sending 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editView"{
            guard let addItemTableViewController = segue.destination as? AddItemViewController else {
                fatalError()
            }
            addItemTableViewController.wineData = selectedWine
        }
    }
}
