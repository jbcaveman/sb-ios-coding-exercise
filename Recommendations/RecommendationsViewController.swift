//
//  ViewController.swift
//  Recommendations
//

import UIKit
import OHHTTPStubs

struct Recommendation: Codable {
    var imageURL = String()
    var title = String()
    var tagline = String()
    var rating: Double = 0.0
    var isReleased: Bool = false
}

extension Recommendation {
    init?(json: [String: Any]) {
        guard let rating = json["rating"] as? Double else { return nil }
        self.title = json["title"] as? String ?? title
        self.isReleased = json["is_released"] as? Bool ?? isReleased
        self.rating =  rating
        self.tagline = json["tagline"] as? String ?? tagline
        self.imageURL = json["image"] as? String ?? imageURL
    }
    
    static let documentsdirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveurl = documentsdirectory.appendingPathComponent("recommendations").appendingPathExtension("plist")
    static func cache (recommendations: [Recommendation]) {
        let plistDecoder = PropertyListEncoder()
        let encoded = try? plistDecoder.encode(recommendations)
        try? encoded?.write(to : archiveurl , options : .noFileProtection)
    }
    static func load() -> [Recommendation]? {
       let plistDecoder = PropertyListDecoder()
       do {
          let recommendations = try Data(contentsOf: archiveurl)
          return try plistDecoder.decode([Recommendation].self, from: recommendations)
       } catch {
         return nil
       }
    }
}

class RecommendationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var recommendations = [Recommendation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ---------------------------------------------------
        // -------- <DO NOT MODIFY INSIDE THIS BLOCK> --------
        // stub the network response with our local ratings.json file
        let stub = Stub()
        stub.registerStub()
        // -------- </DO NOT MODIFY INSIDE THIS BLOCK> -------
        // ---------------------------------------------------
        
        tableView.register(UINib(nibName: "RecommendationTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // NOTE: please maintain the stubbed url we use here and the usage of
        // a URLSession dataTask to ensure our stubbed response continues to
        // work; however, feel free to reorganize/rewrite/refactor as needed
        guard let url = URL(string: Stub.stubbedURL_doNotChange) else { fatalError() }
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)

        if let recommendations = Recommendation.load() {
            self.recommendations = recommendations
            self.tableView.reloadData()
        }

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let receivedData = data else { return }
            
            // TASK: This feels gross and smells. Can this json parsing be made more robust and extensible?
            do {
                if let json = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions(rawValue: UInt(0))) as? [String: Any], let titles = json["titles"] as? [[String: AnyObject]], let titlesSkipped = json["skipped"] as? [String], let titlesOwned = json["titles_owned"] as? [String] {
                    
                    self.recommendations = [Recommendation]()
                    for item in titles {
                        if let recommendation = Recommendation(json: item) {
                            self.recommendations.append(recommendation)
                        }
                    }
                    let sortedSlice = self.recommendations.lazy
                        .sorted( by: { $0.rating > $1.rating } )
                        .prefix(10)
                    .filter( { $0.isReleased && !titlesOwned.contains($0.title) && !titlesSkipped.contains($0.title) })
                    self.recommendations = Array(sortedSlice)
                    Recommendation.cache(recommendations: self.recommendations)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
            catch {
                fatalError("Error parsing stubbed json data: \(error)")
            }
        });

        task.resume()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecommendationTableViewCell
        
        let recommendation = recommendations[indexPath.row]

        cell.titleLabel.text = recommendation.title
        cell.taglineLabel.text = recommendation.tagline
        cell.ratingLabel.text = "Rating: \(recommendation.rating)"

        cell.recommendationImageView.downloadImageFrom(link: recommendation.imageURL, contentMode: UIView.ContentMode.scaleAspectFit)

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
