//
//  ShowDetailsViewController.swift
//  TVShows
//
//  Created by Infinum on 28/07/2019.
//  Copyright © 2019 Infinum Academy. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire

class ShowDetailsViewController: UIViewController {

    //MARK: - Properties
    var showId: String = ""
    var token: String = ""
    private var episodes: [Episode] = []
    
    //MARK: - Private UI
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var showDescriptionLabel: UILabel!
    @IBOutlet weak var numberOfEpisodesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    //MARK: - Navigation and Actions
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let addNewEpViewController = segue.destination as! AddNewEpisodeViewController
        addNewEpViewController.delegate = self
    }
    @IBAction func addNewEpisode(_ sender: UIButton) {
        let bundle = Bundle.main
        let storyboard = UIStoryboard(name: "AddNewEpisode", bundle: bundle)
        let addEpViewController = storyboard.instantiateViewController(
            withIdentifier: "AddNewEpisodeViewController"
            ) as! AddNewEpisodeViewController
        addEpViewController.token = token
        addEpViewController.showId = showId
        let navigationController = UINavigationController(rootViewController:
            addEpViewController)
        present(navigationController, animated: true)
    }
    @IBAction func goBack(_ sender: UIButton) {
        cleanPropertiesAndUI()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableView
extension ShowDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = episodes[indexPath.row]
        print("Selected episode: \(episode)")
    }
}

extension ShowDetailsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("CURRENT INDEX PATH BEING CONFIGURED: \(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: EpisodeTableViewCell.self), for: indexPath) as! EpisodeTableViewCell
        cell.configure(episode: episodes[indexPath.row])
        return cell
    }
}

//MARK: - Set up UI
private extension ShowDetailsViewController {
    
    private func setupTableView() {
        tableView.estimatedRowHeight = 110
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setUpUI(){
        let parameters: [String: String] = [
            "showId": showId,
        ]
        let headers: [String: String] = [
            "Authorization": token,
        ]
        Alamofire
            .request(
                "https://api.infinum.academy/api/shows/" + showId,
                method: .get,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
            ).responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) { [weak self] (response: DataResponse<ShowDetails>) in
                switch response.result {
                case .success(let showDetails):
                    print("Success: \(showDetails)")
                    SVProgressHUD.showSuccess(withStatus: "Success")
                    self?.showTitleLabel.text = showDetails.title
                    self?.showDescriptionLabel.text = showDetails.description
                    self?._listOfEpisodes()
                case .failure(let error):
                    print("API failure: \(error)")
                    SVProgressHUD.showError(withStatus: "Error")
                }
                SVProgressHUD.dismiss()
        }
        
    }
    private func _listOfEpisodes(){
        SVProgressHUD.show()
        let parameters = ["showId": showId]
        let headers = ["Authorization": token]
        Alamofire
            .request(
                "https://api.infinum.academy/api/shows/"+showId+"/episodes",
                method: .get,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
            ).responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) { [weak self] (response: DataResponse<[Episode]>) in
                switch response.result {
                case .success(let episodes):
                    print("Success: \(episodes)")
                    self?.episodes = episodes
                    self?.numberOfEpisodesLabel.text = String(episodes.count)
                    self?.setupTableView()
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("API failure: \(error)")
                    SVProgressHUD.showError(withStatus: "Error")
                }
                SVProgressHUD.dismiss()
        }
    }
    
    private func cleanPropertiesAndUI(){
        self.episodes = []
        self.showId = ""
        self.token = ""
    }
}
extension ShowDetailsViewController: AddNewEpisodeViewControllerDelegate {
    func refreshListOfEpisodes(episode: Episode) {
        _listOfEpisodes()
    }
}



