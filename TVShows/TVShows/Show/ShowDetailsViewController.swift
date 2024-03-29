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
import Kingfisher

final class ShowDetailsViewController: UIViewController {

    //MARK: - Properties
    var showId: String = ""
    var token: String = ""
    private var episodes: [Episode] = []
    
    //MARK: - Private UI
    @IBOutlet private weak var showTitleLabel: UILabel!
    @IBOutlet private weak var showDescriptionLabel: UILabel!
    @IBOutlet private weak var numberOfEpisodesLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var showImage: UIImageView!
    
    //MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        _loadShowDetails()
    }
    
    //MARK: - Navigation and Actions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        let navigationController = UINavigationController(rootViewController:
            addEpViewController)
        present(navigationController, animated: true)
        addEpViewController.token = token
        addEpViewController.showId = showId
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
        let bundle = Bundle.main
        let storyboard = UIStoryboard(name: "EpisodeDetails", bundle: bundle)
        let epDetailsViewController = storyboard.instantiateViewController(
            withIdentifier: "EpisodeDetailsViewController"
            ) as! EpisodeDetailsViewController
        self.navigationController?.pushViewController(epDetailsViewController, animated: true)
        epDetailsViewController.token = token
        epDetailsViewController.episodeId = episode.id
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
        tableView.estimatedRowHeight = 51
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.tintColor = UIColor.gray
        refreshControl.addTarget(self, action: #selector(refreshListOfEpisodes), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    private func _loadShowDetails(){
        SVProgressHUD.show()
        let parameters = ["showId": showId]
        let headers = ["Authorization": token]
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
                    guard let self = self else { return }
                    self.showTitleLabel.text = showDetails.title
                    self.showDescriptionLabel.text = showDetails.description
                    guard
                        let url = URL(string: "https://api.infinum.academy//" + showDetails.imageUrl)
                    else { return }
                    self.showImage.kf.setImage(with: url)
                    self._loadEpisodes()
                case .failure(let error):
                    print("API failure: \(error)")
                    SVProgressHUD.showError(withStatus: "Error")
                }
                SVProgressHUD.dismiss()
        }
        
    }
    private func _loadEpisodes(){
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
                    guard let self = self else { return }
                    self.episodes = episodes
                    self.numberOfEpisodesLabel.text = String(episodes.count)
                    self.setupTableView()
                    self.tableView.reloadData()
                case .failure(let error):
                    print("API failure: \(error)")
                    SVProgressHUD.showError(withStatus: "Error")
                }
        }
    }
    
    private func cleanPropertiesAndUI(){
        self.episodes = []
        self.showId = ""
        self.token = ""
    }
}
extension ShowDetailsViewController: AddNewEpisodeDelegate {
    @objc func refreshListOfEpisodes() {
        _loadEpisodes()
        tableView.refreshControl?.endRefreshing()
    }
}



