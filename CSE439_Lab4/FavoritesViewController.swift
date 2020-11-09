//
//  FavoritesViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 10/27/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

import UIKit
import CoreData

class FavoritesCollectionViewCell: UICollectionViewCell{
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
}

class FavoritesViewController: UIViewController {
    
    @IBOutlet weak var favoritesCollectionView: UICollectionView!
    
    var movieList: [NSManagedObject] = []
    var images: [UIImage] = []
    
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 50.0,
    left: 20.0,
    bottom: 50.0,
    right: 20.0)
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        favoritesCollectionView.dataSource = self
        favoritesCollectionView.delegate = self
        getFavorites()
        favoritesCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Appear")
        checkIfUpdated()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func checkIfUpdated(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoriteMovie")
        
        do{
            let movies: [NSManagedObject] = try context.fetch(fetchRequest)
            if(movies != movieList){
                movieList = movies
                images = []
                for movie in movieList {
                    guard let smallImageData: Data = movie.value(forKey: "smallPosterImage") as? Data else { return }
                    guard let smallPosterImage:UIImage = UIImage(data: smallImageData) else { return }
                    images.append(smallPosterImage)
                }
                favoritesCollectionView.reloadData()
            }
        }catch let error as NSError{
            print("Error fetching from core data: \(error)")
        }
    }
    
    func getFavorites(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoriteMovie")
        
        do{
            movieList = try context.fetch(fetchRequest)
        } catch let error as NSError{
            print("Error fetchin from CoreData: \(error)")
        }
        
        for movie in movieList {
            guard let smallImageData: Data = movie.value(forKey: "smallPosterImage") as? Data else { return }
            guard let smallPosterImage:UIImage = UIImage(data: smallImageData) else { return }
            images.append(smallPosterImage)
        }
    }

}

extension FavoritesViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteMovieCell", for: indexPath) as! FavoritesCollectionViewCell
        
        cell.posterImage.image = images[indexPath.item]
        cell.titleLabel.text = movieList[indexPath.item].value(forKey: "title") as? String
        return cell
    }
    
    
}

extension FavoritesViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 92.0, height: 201.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension FavoritesViewController: UICollectionViewDelegate{
    //TODO: send user to detail page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thisMovie = movieList[indexPath.item]
        
        guard let largeImageData = thisMovie.value(forKey: "largePosterImage") as? Data, let id = thisMovie.value(forKey: "id") as? Int, let title = thisMovie.value(forKey: "title") as? String, let releaseDate = thisMovie.value(forKey: "releaseDate") as? Date, let voteAverage = thisMovie.value(forKey: "voteAverage") as? Double, let overview = thisMovie.value(forKey: "overview") as? String, let smallImageData = thisMovie.value(forKey: "smallPosterImage") as? Data else { return }
        guard let largePosterImage = UIImage(data: largeImageData) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: releaseDate)
        
        let detailVC = MovieDetailViewController(id: id, movieTitle: title, posterImage: largePosterImage, releaseDate: date, voteAverage: voteAverage, overview: overview, voteCount: 100, smallImageData: smallImageData, largeImageData: largeImageData)
        
        detailVC.title = title
        
        navigationController?.pushViewController(detailVC, animated: true)
        
    }
}
