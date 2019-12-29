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
  
    }
    
    ////////////// /////////////////////////////
    ///////Mark : Setup The View
    
    
    func setupSearchBarAndLoading (){
    navigationController?.navigationBar.prefersLargeTitles = true
    searchController = UISearchController(searchResultsController: nil)
    searchController!.searchBar.delegate = self
    searchController!.searchResultsUpdater = self
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
        loading.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        loading.sizeToFit()
    }
    
    
    func loadMoreDeclartion(){
        loadMore = UIButton(frame: CGRect.init(x: 0, y: 0, width: tableView.bounds.width, height: 50))
        loadMore?.setTitle("Load More", for: .normal)
        loadMore?.setTitleColor(#colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), for: .normal)
        loadMore?.addTarget(self, action: #selector(self.loadMoreItems), for: .touchUpInside)
    }
    
    
    ////////////////////////////////////////////
    /////Mark : notification Functions
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    @objc func reloadData(_ notification: Notification?) {
        self.tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func NotificationPressed(){
        AlamofireRequest(page: 1, per_page: 10) { (Result) in
            self.Repos = Result
            self.page = 2
            NotificationCenter.default.post(name: NSNotification.Name("ReloadNotification"), object: nil)
        }
    }

    ////////////////////////////////////////////////////////
    ///////////Mark : Pull to Refresh and infinete scrollingFunctions
    
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
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    ///////////
    @objc func loadMoreItems(){
        tableView.tableFooterView = loading
        tableView.tableFooterView?.isHidden = false
        self.loading.loopMode = .loop
        self.loading.play()
        RetriveOrFetch(page: page)
    }
    
    ////////////////////////////////////////////////////////
    ///////////Mark : Cahceing Functions and Holder
    
    class ReposHolder: NSObject {
        let pageofRepos: [RepoElement]
        init(pageofRepos: [RepoElement]) {
            self.pageofRepos = pageofRepos
        }
    }
    
    func CachingPageOfRepos( PageOfRepos : [RepoElement] ){
        RepoCache.setObject(ReposHolder(pageofRepos: PageOfRepos), forKey: "\(self.page)" as NSString)
        }
    
    func RetrivingPageFromRepos (page : Int) -> [RepoElement] {
        if let RetrivedPageOfRepos = RepoCache.object(forKey: "\(page)" as NSString){
            return RetrivedPageOfRepos.pageofRepos
        }else{
            print("PageNotExsit")
        }
        return [RepoElement]()
    }
    
    func RemoveAllCache(){
        self.RepoCache.removeAllObjects()
    }

    ////////////////////////////////////////////////////////
    ///////////Mark : AlamoFireRequests
    
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
                 self.showAlert(title: "Faild", message: "Sorry Please Try Again Later")
                }
            }
        ProgressHUD.dismiss()
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
            for NextRepo in RetrivedPage {
                self.Repos.append(NextRepo)
            }
            self.page += 1
            ProgressHUD.dismiss()
        }
    }
    
}////End of the class


/////////////////////////////////////////////////////////////////
///MARK : TableView Functions

extension ViewController : UITableViewDelegate , UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredRepos.isEmpty == true{
            return Repos.count
        }else{
            return filteredRepos.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoCell", for: indexPath) as? RepoTableViewCell
        if filteredRepos.isEmpty == true{
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
        return configuration
    }
    
}

/////////////////////////////////////////////////////////////////
///MARK : Search Functions

extension ViewController : UISearchResultsUpdating , UISearchBarDelegate{
    func updateSearchResults(for searchController: UISearchController) {
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.tableFooterView?.isHidden = true
        self.filteredRepos = Repos.filter({($0.name?.lowercased().contains(searchText.lowercased()))!})
        tableView.reloadData()
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        filteredRepos.removeAll()
        tableView.reloadData()
    }

}
