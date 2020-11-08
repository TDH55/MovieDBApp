//
//  MovieDetailViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 11/7/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    let id: Int!
    let movieTitle: String!
    let posterImage: UIImage!
    let releaseDate: String!
    let voteAverage: Double!
    let overview: String!
    let voteCount:Int!
    
    init(id: Int, movieTitle: String, posterImage: UIImage, releaseDate: String, voteAverage: Double, overview: String, voteCount: Int){
        self.id = id
        self.movieTitle = movieTitle
        self.posterImage = posterImage
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.overview = overview
        self.voteCount = voteCount
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoder")
    }
    

    @IBOutlet weak var poster: UIImageView!
    @IBOutlet weak var releaseLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBAction func favoriteButton(_ sender: Any) {
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = movieTitle
        poster.image = posterImage
        
        //https://stackoverflow.com/questions/36861732/convert-string-to-date-in-swift
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from:releaseDate)!
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let formattedReleaseDate = dateFormatter.string(from: date)
//        print(formattedReleaseDate)
        
        releaseLabel.text = "Released: \(formattedReleaseDate)"
        scoreLabel.text = "Score: \(voteAverage * 10)/100"
        if let overview = overview{
            overviewLabel.text = "Overview: \n\(overview)"
        }
        
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
