//
//  ViewController.swift
//  The Repo
//
//  Created by Sherif Darwish on 12/24/19.
//  Copyright © 2019 Sherif Darwish. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Lottie
import ProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var refreshControl : UIRefreshControl?
    var searchController : UISearchController?    
    private var loading = AnimationView.init(name: "222-trail-loading")
    private var loadMore : UIButton?
    
    var Repos = [RepoElement]()
    var filteredRepos = [RepoElement]()
    var page = 1
    var per_page = 10
    
    var searching = false
    
    let RepoCache = NSCache<NSString, ReposHolder>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        RetriveOrFetch(page: page)
        setupNotificationAlert()
        setupSearchBarAndLoading()
        ProgressHUD.show()
        loadMoreDeclartion()
        addRefreshControl()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData(_:)), name: NSNotification.Name("ReloadNotification"), object: nil)
        
        self.definesPresentationContext = true
    }
    
    
// MARK: - View Initialization
    
    func setupSearchBarAndLoading (){
        navigationController?.navigationBar.prefersLargeTitles = true
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchBar.delegate = self
        searchController!.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController?.obscuresBackgroundDuringPresentation = false
        loading.frame = CGRect(x: 0, y: 0, width: 100, height: 65)
        loading.sizeToFit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    @objc func reloadData(_ notification: Notification?) {
        self.tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Pressed Function
    
    func NotificationPressed(){
        AlamofireRequest(page: 1, per_page: 10) { (Result) in
            self.Repos = Result
            self.page = 2
            NotificationCenter.default.post(name: NSNotification.Name("ReloadNotification"), object: nil)
        }
    }
    
// Mark: - Pull To Refresh ( UIRefreshController )
    
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        refreshControl?.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl!)
    }
    
    @objc func refreshData(){
        AlamofireRequest(page: 1, per_page: 10) { (result) in
            self.page = 1
            self.Repos.removeAll()
            self.RemoveAllCache()
            for NextRepo in result {
                self.Repos.append(NextRepo)
            }
            self.refreshControl?.endRefreshing()
            self.page += 1
        }
        print(Repos.count)
        self.tableView.reloadData()
        
    }
    
// MARK: - Load More Items Button ( Infinite Scrolling )
    
    func loadMoreDeclartion(){
        loadMore = UIButton(frame: CGRect.init(x: 0, y: 0, width: tableView.bounds.width, height: 50))
        loadMore?.setTitle("Load More", for: .normal)
        loadMore?.setTitleColor(#colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), for: .normal)
        loadMore?.addTarget(self, action: #selector(self.loadMoreItems), for: .touchUpInside)
    }
    
    @objc func loadMoreItems(){
        tableView.tableFooterView = loading
        tableView.tableFooterView?.isHidden = false
        self.loading.loopMode = .loop
        self.loading.play()
        RetriveOrFetch(page: page)
    }
    
// MARK: - Cahceing Stuff & Holder
    
    class ReposHolder: NSObject {
        let pageofRepos: [RepoElement]
        init(pageofRepos: [RepoElement]) {
            self.pageofRepos = pageofRepos
        }
    }
    
    func CachingPageOfRepos( PageOfRepos : [RepoElement] ){
        RepoCache.setObject(ReposHolder(pageofRepos: PageOfRepos), forKey: "\(self.page)" as NSString)
        print("page \(page) is cached")
    }
    
    func RetrivingPageFromRepos (page : Int) -> [RepoElement] {
        if let RetrivedPageOfRepos = RepoCache.object(forKey: "\(page)" as NSString){
            print("retriving page \(page)")
            return RetrivedPageOfRepos.pageofRepos
        }else{
            print("PageNotExsit")
        }
        return [RepoElement]()
    }
    
    func RemoveAllCache(){
        self.RepoCache.removeAllObjects()
    }
    
    func RetriveOrFetch(page : Int){
        let RetrivedPage = RetrivingPageFromRepos(page: page)
        if RetrivedPage.isEmpty {
            AlamofireRequest(page: page , per_page: per_page) { (result) in
                for temp in result {
                    self.Repos.append(temp)
                }
                ProgressHUD.dismiss()
                self.page += 1
                self.tableView.reloadData()
            }
        }else{
            print("if else fetch or retive is in retrive now")
            for NextRepo in RetrivedPage {
                self.Repos.append(NextRepo)
                print("retriving page \(page)")
            }
            self.page += 1
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
// MARK: - Alamofire Request
    
    func AlamofireRequest(page : Int , per_page : Int , completion : @escaping ([RepoElement])->Void){
        let URL = "https://api.github.com/users/square/repos?page=\(page)&per_page=\(per_page)"
        Alamofire.request(URL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseData { response in
            switch response.result
            {
            case .success(let value):
                do {
                    let json =  try JSON(value).rawData()
                    let repositories = try? newJSONDecoder().decode(Repo.self, from: json)
                    var result = [RepoElement]()
                    for repository in repositories! {
                        result.append(repository)
                    }
                    self.CachingPageOfRepos(PageOfRepos: result)
                    completion(result)
                } catch {}
            case .failure(let error):
                print("Failaure \(error.localizedDescription)")
                ProgressHUD.dismiss()
                self.showAlert(title: "Failed", message: "Sorry Please Try Again Later")
                self.tableView.tableFooterView = self.loadMore
            }
        }
        ProgressHUD.dismiss()
    }
    
}


// MARK: - TableView Delegate Functions

extension ViewController : UITableViewDelegate , UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching == false{
            return Repos.count
        }else{
            return filteredRepos.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoCell", for: indexPath) as? RepoTableViewCell
        if searching == false{
            print(Repos.count)
            let  NextRepo = self.Repos[indexPath.row]
            cell!.ConfigureCell(RepoName: NextRepo.name ?? "name", RepoDesc: NextRepo.repoDescription ?? "desc", OwnerName: (NextRepo.owner?.login).map { $0.rawValue } ?? "" , OwnerAvatar: (NextRepo.owner?.avatarURL)! )
            if NextRepo.fork == false || NextRepo.fork == nil {
                cell?.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
            }else{
                cell?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
            
        }else{
            let  NextRepo = self.filteredRepos[indexPath.row]
            cell!.ConfigureCell(RepoName: NextRepo.name ?? "name", RepoDesc: NextRepo.repoDescription ?? "desc", OwnerName: (NextRepo.owner?.login).map { $0.rawValue } ?? "" , OwnerAvatar: (NextRepo.owner?.avatarURL)! )
            if NextRepo.fork == false || NextRepo.fork == nil {
                cell?.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
            }else{
                cell?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastCell = self.Repos.count - 1
        if filteredRepos.isEmpty == true && indexPath.row == lastCell{
            tableView.tableFooterView = loadMore
            tableView.tableFooterView?.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let goToRepository = UIContextualAction(style: .normal, title: "Go To Repository") { (action, _, _) in
            UIApplication.shared.open(URL(string: self.Repos[indexPath.row].htmlURL!)!, completionHandler: nil)
        }
        let goToOwner = UIContextualAction(style: .normal, title: "Go To Owner") { (action, _, _) in
            UIApplication.shared.open(URL(string: (self.Repos[indexPath.row].owner?.htmlURL)!)!, completionHandler: nil)
        }
        
        goToRepository.backgroundColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        goToOwner.backgroundColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
        let configuration = UISwipeActionsConfiguration(actions: [goToRepository , goToOwner])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let swipeAction = UISwipeActionsConfiguration(actions: [])
        swipeAction.performsFirstActionWithFullSwipe = false
        return swipeAction
    }
    
}

// MARK: - SearchBar Delegate Functions

extension ViewController : UISearchResultsUpdating , UISearchBarDelegate{
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
        guard searchController!.searchBar.text?.count != 0 else {
            return
        }
        searching = true
        tableView.tableFooterView?.isHidden = true
        refreshControl?.removeFromSuperview()
        search(searchBar: searchBar)
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        tableView.addSubview(refreshControl!)
        filteredRepos.removeAll()
        tableView.tableFooterView?.isHidden = false
        showTable()
        searchBar.endEditing(true)
    }
    
    func showTable(){
        tableView.reloadData()
        tableView.isHidden = false
    }
    
// MARK: - Search Function
    
    func search(searchBar : UISearchBar){
        if searchBar.text == "" {
            searching = false
            showTable()
        }else{
            self.filteredRepos = Repos.filter({ ($0.name?.lowercased().prefix(searchBar.text!.count).contains(searchBar.text!.lowercased()))! })
            guard filteredRepos.isEmpty != true , filteredRepos.count != 0 else {
                tableView.isHidden = true
                refreshControl?.removeFromSuperview()
                return
            }
            showTable()
        }
    }
    
}
