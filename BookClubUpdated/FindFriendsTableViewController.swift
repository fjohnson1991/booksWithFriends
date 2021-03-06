//
//  FindFriendsTableViewController.swift
//  BookClubUpdated
//
//  Created by Felicity Johnson on 11/24/16.
//  Copyright © 2016 FJ. All rights reserved.
//

import UIKit

class FindFriendsTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredUsers = [User]()
    var usersArray = [User]()
    var usernamesArray = [String]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.themeOrange
        self.tabBarController?.tabBar.barTintColor = UIColor.themeDarkBlue
        
        let navBarAttributesDictionary = [ NSForegroundColorAttributeName: UIColor.themeDarkBlue,NSFontAttributeName: UIFont.themeMediumThin]
        navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        
        UserFirebaseMethods.retrieveAllUsers { (users) in
            for user in users {
                guard let addedUser = user else {return}
                self.usersArray.append(addedUser)
                self.usernamesArray.append(addedUser.username)
                self.tableView.reloadData()
            }
        }
    }
    
    
    func filterContentForSearchText(searchText: String) {
        
        filteredUsers = usersArray.filter { user in
            return user.username.lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let empty = [String]()
        if searchController.isActive && self.searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        return empty.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResults", for: indexPath) as! SearchFriendsTableViewCell
        
        let user: User
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            user = usersArray[indexPath.row]
        }
        cell.textLabel?.text = user.username
        
        cell.addFollowing.addTarget(self, action: #selector(addFollowingButton), for: .touchUpInside)
        cell.contentView.bringSubview(toFront: cell.addFollowing)
        
        return cell
    }
    
    func addFollowingButton(sender: UIButton) {
        _ = sender.tag
        let cellContent = sender.superview!
        let cell = cellContent.superview! as! UITableViewCell
        guard let indexPath = self.tableView.indexPath(for: cell) else {return}
        
        var uniqueUserID = String()
        var username = String()
        
        if searchController.isActive && searchController.searchBar.text != "" {
            uniqueUserID = filteredUsers[indexPath.row].uniqueKey
            username = filteredUsers[indexPath.row].username
        } else {
            uniqueUserID = usersArray[indexPath.row].uniqueKey
            username = usersArray[indexPath.row].username
        }
        
        UserFirebaseMethods.retrieveSpecificUser(with: uniqueUserID) { (user) in
            
            UserFirebaseMethods.prohibitDuplicateFollowing(of: uniqueUserID, completion: { (alreadyFollowing) in
                if alreadyFollowing == true {
                    let alert = UIAlertController(title: "Oops", message: "You are already following \(username)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    
                    UserFirebaseMethods.addFollowing(with: uniqueUserID, completion: { (success) in
                        if success == true {
                            
                            let alert = UIAlertController(title: "Success", message: "You have added \(username) as a friend!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in

                            }))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            let alert = UIAlertController(title: "Oops", message: "You have been blocked by \(username)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
       
                            }))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                    })
                }
            })
        }
    }
    
    
     // MARK: - Navigation

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "userProfile" {
            //let dest = segue.destination as! UINavigationController
            let target = segue.destination as! FriendsProfileViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
               target.passedUserID = filteredUsers[indexPath.row].uniqueKey
            }
        }
        
        
     }
}


extension FindFriendsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

