//
//  MovieDetailViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 11/7/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

import UIKit
import CoreData

class MovieDetailViewController: UIViewController {
    
    let id: Int!
    let movieTitle: String!
    let posterImage: UIImage!
    let releaseDate: String!
    let voteAverage: Double!
    let overview: String!
    let voteCount:Int!
    let smallImageData: Data!
    let largeImageData: Data!
    
    var isFavorited: Bool = false
    
    init(id: Int, movieTitle: String, posterImage: UIImage, releaseDate: String, voteAverage: Double, overview: String, voteCount: Int, smallImageData: Data, largeImageData: Data){
        self.id = id
        self.movieTitle = movieTitle
        self.posterImage = posterImage
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.overview = overview
        self.voteCount = voteCount
        self.smallImageData = smallImageData
        self.largeImageData = largeImageData
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoder")
    }
    

    @IBOutlet weak var poster: UIImageView!
    @IBOutlet weak var releaseLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var favoritesButton: UIButton!
    
    
    

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
        
        releaseLabel.text = "Released: \(formattedReleaseDate)"
        scoreLabel.text = "Score: \(voteAverage * 10)/100"
        if let overview = overview{
            overviewLabel.text = "Overview: \n\(overview)"
        }
        checkIsFavorite()
        updateFavoriteButton()
        
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkIsFavorite()
        updateFavoriteButton()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func updateFavoriteButton(){
        if(isFavorited){
            favoritesButton.setTitle("Remove From Favorites", for: .normal)
        }else{
            favoritesButton.setTitle("Add To Favorites", for: .normal)
        }
    }
    
    func checkIsFavorite(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoriteMovie")
        fetchRequest.predicate = NSPredicate(format: "id == \(id!)")
        
        do {
            let results: [NSManagedObject] = try context.fetch(fetchRequest)
            if results.count > 0 {
                isFavorited = true
            }else{
                isFavorited = false
            }
        } catch let error as NSError{
            print("error fetching from core date \(error)")
        }
    }
    
    
    @IBAction func favoritesButtonClicked(_ sender: Any) {
        if(isFavorited){
            deleteFromFavorites(id: id)
            //TODO: Decide if this is kept
            navigationController?.popViewController(animated: true)
        }else{
            saveToFavorites(title: movieTitle, smallPosterImage: smallImageData, largePosterImage: largeImageData, releaseDate: releaseDate, voteAverage: voteAverage, overview: overview, id: id)
        }
        checkIsFavorite()
        updateFavoriteButton()
//        saveToFavorites(title: movieTitle, smallPosterImage: smallImageData, largePosterImage: largeImageData, releaseDate: releaseDate, voteAverage: voteAverage, overview: overview, id: id)
//        deleteFromFavorites(id: id)
    }
    
    func deleteFromFavorites(id: Int){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoriteMovie")
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        
        do {
            let results: [NSManagedObject] = try context.fetch(fetchRequest)
            context.delete(results[0])
            try context.save()
        } catch let error as NSError{
            print("error deleting from core data: \(error)")
        }
    }
    
    func saveToFavorites(title: String, smallPosterImage: Data, largePosterImage: Data, releaseDate: String, voteAverage: Double, overview: String, id: Int){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let context = appDelegate.persistentContainer.viewContext
                
        let entity = NSEntityDescription.entity(forEntityName: "FavoriteMovie", in: context)
        
        let favoritedMovie = NSManagedObject(entity: entity!, insertInto: context)
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from:releaseDate)!
        dateFormatter.dateFormat = "MM/dd/yyyy"
//        let formattedReleaseDate = dateFormatter.string(from: date)
        
        
        favoritedMovie.setValue(title, forKey: "title")
        favoritedMovie.setValue(smallPosterImage, forKey: "smallPosterImage")
        favoritedMovie.setValue(largePosterImage, forKey: "largePosterImage")
        favoritedMovie.setValue(date, forKey: "releaseDate")
        favoritedMovie.setValue(voteAverage, forKey: "voteAverage")
        favoritedMovie.setValue(overview, forKey: "overview")
        favoritedMovie.setValue(id, forKey: "id")
        
        do {
            try context.save()
        } catch let error{
            print("Failed saving to core data: \(error)")
        }
        print("saved to core data")
    }
    
}

