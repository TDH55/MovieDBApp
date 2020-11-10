//
//  MoviesViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 10/27/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

import UIKit
import CoreData

enum APIError: Error {
    case inavlidURL
    case noImage
}
class MovieCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var movieLabel: UILabel!
    
}

class MoviesViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var movieCollectionView: UICollectionView!
    
    let apiKey = "api_key=d5d50f98654e01d24371f44ad6fa09ee"
    let apiBaseURL = "https://api.themoviedb.org/3/"
    let imageBaseURL = "https://image.tmdb.org/t/p/w92"
    let largeImageBaseURL = "https://image.tmdb.org/t/p/w185"
    let apiURLLang = "&language=en-US"
    let apiURLPage = "&page="
    private let apiURLPopular = "movie/popular?"
    
    var currentSearch: String = ""
    
    var getPopular: Bool = true
    var currentPage: Int = 1
    var totalPages: Int = 10
    
    var movieList: [Movie] = []
    var imageCache: [UIImage] = []
    
    var loading: Bool = false
    
    var currentQuery: String {
        return "https://api.themoviedb.org/3/search/movie?api_key=d5d50f98654e01d24371f44ad6fa09ee&language=en-US&query=\(currentSearch)&page=\(currentPage)&include_adult=false"
    }
    
    let apiQueue = DispatchQueue(label: "apiQueue", qos: .userInitiated)
    
    
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 50.0,
    left: 20.0,
    bottom: 50.0,
    right: 20.0)
    
    let loadingIndicator = UIActivityIndicatorView()
    
//    let screenWidth = movieCollectionView.frame.size.width
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        deleteAllData(entity: "FavoriteMovie")
        // Do any additional setup after loading the view.
        movieCollectionView.dataSource = self
        movieCollectionView.delegate = self
        
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        
        let interaction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(interaction)
//        movieCollectionView.addSubview(loadingIndicator)
//        loadingIndicator.isHidden = false
        
//        print(loadingIndicator)
//        print(movieCollectionView.subviews)
        setupLoadingIndicator()
        startLoadingIndicator()
        apiQueue.async {
            self.getPopular(pageNumber: self.currentPage)
            self.cacheImages()
            DispatchQueue.main.async {
                self.stopLoadingIndicator()
                self.movieCollectionView.reloadData()
                self.loading = false
            }
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
    
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false

        do
        {
            let results = try managedContext.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                print(managedObjectData)
                managedContext.delete(managedObjectData)
                try managedContext.save()
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
    func cacheImages(){
//        print(movieList)
        if(imageCache.count < movieList.count){
            for i in imageCache.count ..< movieList.count{
                let movie = movieList[i]
                
                if let posterPath = movie.poster_path {
                    let url = URL(string: imageBaseURL + posterPath)
                    do {
                        guard let url = url else { throw APIError.inavlidURL }
                        let data = try Data(contentsOf: url)
                        let image = UIImage(data: data)
                        guard let thisImage = image else { throw APIError.noImage}
                        imageCache.append(thisImage)
                    } catch let error {
                        print("error caching images: \(error)")
                    }
                }
                else{
                    let image = UIImage(systemName: "film")
                    imageCache.append(image!)
                }

            }
        }
        
        
    }
    
    func setupLoadingIndicator(){
        let screenWidth = self.view.frame.size.width
        let indicatorSize = 300
        loadingIndicator.frame = CGRect(x: (Int(screenWidth) / 2) - (indicatorSize / 2), y: 30, width: indicatorSize, height: indicatorSize)
    }
    func startLoadingIndicator(){
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        movieCollectionView.addSubview(loadingIndicator)
    }
    
    func stopLoadingIndicator(){
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        loadingIndicator.removeFromSuperview()
    }
    
    func checkIsFavorite(id: Int) -> Bool{
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FavoriteMovie")
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        
        do {
            let results: [NSManagedObject] = try context.fetch(fetchRequest)
            if results.count > 0 {
                return true
            }else{
                return false
            }
        } catch let error as NSError{
            print("error fetching from core date \(error)")
        }
        return false
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

extension MoviesViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearch = searchText.lowercased().replacingOccurrences(of: " ", with: "%20")
//        movieCollectionView.reloadData()
//        currentPage = 1
//        getPopular = false
//
//
//        //query and update collection view
//        apiQueue.async {
//            print(Thread.current)
//            print("search")
//            self.movieList = []
//            self.imageCache = []
//            self.executeQuery(query: self.currentQuery)
//            print("start cache search")
//            self.cacheImages()
//            print(self.imageCache.count)
//            DispatchQueue.main.async {
//                self.movieCollectionView.reloadData()
//                self.loading = false
//            }
//        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //TODO: add case for empty search
        //TODO: add display for no results
        apiQueue.sync {
            Thread.current.cancel()
        }
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        
        currentPage = 1
        getPopular = false
        
        
        //query and update collection view
        movieList = []
        imageCache = []
        movieCollectionView.reloadData()
        startLoadingIndicator()
        
        apiQueue.async {
            
            self.movieList = []
            self.imageCache = []
            if(self.currentSearch == ""){
                self.getPopular = true
                self.getPopular(pageNumber: self.currentPage)
            }else{
                self.executeQuery(query: self.currentQuery)
            }
            self.cacheImages()
            DispatchQueue.main.async {
                self.stopLoadingIndicator()
                self.movieCollectionView.reloadData()
                self.loading = false
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        movieCollectionView.reloadData()
        apiQueue.sync {
            Thread.current.cancel()
        }
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        currentPage = 1
        getPopular = true
        movieList = []
        imageCache = []
        movieCollectionView.reloadData()
        startLoadingIndicator()
        apiQueue.async {
            
            self.movieList = []
            self.imageCache = []
            self.getPopular(pageNumber: self.currentPage)
            self.cacheImages()
            
            DispatchQueue.main.async {
                self.stopLoadingIndicator()
                self.movieCollectionView.reloadData()
                self.loading = false
            }
        }
    }
}

extension MoviesViewController: UICollectionViewDataSource{
    
    func getPopular(pageNumber: Int){
        loading = true
        var response: APIResults?
        let url = URL(string: apiBaseURL + apiURLPopular + apiKey + apiURLLang + apiURLPopular + apiURLPage + "\(pageNumber)")
        do{
            guard let url = url else { throw APIError.inavlidURL }
            let data = try Data(contentsOf: url)
            response = try JSONDecoder().decode(APIResults.self, from: data)
        } catch let error {
            print("error getting api data: \(error)")
        }
        guard let res = response else { return }
        totalPages = res.total_pages
        movieList.append(contentsOf: res.results)
//        if currentPage < res.total_pages {
//            currentPage = currentPage + 1
//        } else{
//            currentPage = 1
//        }
        currentPage = currentPage + 1
    }
    
    func executeQuery(query: String){
        loading = true
        var response: APIResults?
        let url = URL(string: currentQuery)
        do{
            guard let url = url else { throw APIError.inavlidURL }
            let data = try Data(contentsOf: url)
            response = try JSONDecoder().decode(APIResults.self, from: data)
        } catch let error{
            print("error getting query: \(error)")
        }
        
        guard let res = response else { return }
        totalPages = res.total_pages
        movieList.append(contentsOf: res.results)
        
        currentPage += 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCollectionViewCell
        
        cell.posterImageView.image = imageCache[indexPath.item]
        cell.movieLabel.text = movieList[indexPath.item].title
        
        return cell
    }
    
}


extension MoviesViewController: UICollectionViewDelegateFlowLayout{
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

extension MoviesViewController: UICollectionViewDelegate {
    //load new items when at bottom of page
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let numberOfItems = movieList.count
        if((indexPath.item == numberOfItems - 1) && !loading){
            //get next page
            if(currentPage <= totalPages){
                apiQueue.async {
                    if(self.getPopular){
                        self.getPopular(pageNumber: self.currentPage)
                        self.cacheImages()
                    } else{
                        self.executeQuery(query: self.currentQuery)
                        self.cacheImages()
                    }
                    DispatchQueue.main.async {
                        self.movieCollectionView.reloadData()
                        self.loading = false
                    }
                }
            }
        }
    }
    
    //send user to detail page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thisMovie = movieList[indexPath.item]
        
        var posterImage: UIImage?
        var largePosterData: Data?
        var smallPosterData: Data?
        
        if let posterPath = thisMovie.poster_path{
            let imageURL = URL(string: largeImageBaseURL + posterPath)
            let smallImageURL = URL(string: imageBaseURL + posterPath)
            do {
                guard let url = imageURL else { throw APIError.inavlidURL }
                guard let smallImageUrl = smallImageURL else { throw APIError.inavlidURL }
                let data = try Data(contentsOf: url)
                smallPosterData = try Data(contentsOf: smallImageUrl)
                largePosterData = data
                let image = UIImage(data: data)
                guard let thisImage = image else { throw APIError.noImage}
                posterImage = thisImage
            } catch let error {
                print("error caching images: \(error)")
            }
        }else{
            posterImage = UIImage(systemName: "film")!
            smallPosterData = posterImage?.pngData()
            largePosterData = posterImage?.pngData()
        }
        
        
        let detailVC = MovieDetailViewController(id: thisMovie.id, movieTitle: thisMovie.title, posterImage: posterImage!, releaseDate: thisMovie.release_date, voteAverage: thisMovie.vote_average, overview: thisMovie.overview, voteCount: thisMovie.vote_count, smallImageData: smallPosterData!, largeImageData: largePosterData!)
        detailVC.title = title
        
        navigationController?.pushViewController(detailVC, animated: true)
//        navigationController?.navigationBar.text
    }
}

extension MoviesViewController: UIContextMenuInteractionDelegate{
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil){ action in
            //TODO: change this to be add/remove from favorites
            let movie = self.movieList[indexPath.item]
            
            let isFavorited = self.checkIsFavorite(id: movie.id)
            //check if move is in favorites
            
            //add/remove
            if(isFavorited){
                let favoritesButton = UIAction(title: "Remove From Favorites", image: UIImage(systemName: "star.fill"), identifier: UIAction.Identifier(rawValue: "favorite")) {_ in
                    self.deleteFromFavorites(id: movie.id)
                    self.dismiss(animated: true)
                }
                
                return UIMenu(title: movie.title, image: nil, identifier: nil, children: [favoritesButton])
            }else{
                let favoritesButton = UIAction(title: "Add To Favorites", image: UIImage(systemName: "star"), identifier: UIAction.Identifier(rawValue: "favorite")) {_ in
                    var largePosterData: Data?
                    var smallPosterData: Data?
                    
                    if let posterPath = movie.poster_path{
                        let imageURL = URL(string: self.largeImageBaseURL + posterPath)
                        let smallImageURL = URL(string: self.imageBaseURL + posterPath)
                        do {
                            guard let url = imageURL else { throw APIError.inavlidURL }
                            guard let smallImageUrl = smallImageURL else { throw APIError.inavlidURL }
                            smallPosterData = try Data(contentsOf: smallImageUrl)
                            largePosterData = try Data(contentsOf: url)
                        } catch let error {
                            print("error caching images: \(error)")
                        }
                    }else{
                        let image = UIImage(systemName: "film")!
                        smallPosterData = image.pngData()
                        largePosterData = image.pngData()
                    }
                    
                    self.saveToFavorites(title: movie.title, smallPosterImage: smallPosterData!, largePosterImage: largePosterData!, releaseDate: movie.release_date, voteAverage: movie.vote_average, overview: movie.overview, id: movie.id)
                    self.dismiss(animated: true)
                }
                
                return UIMenu(title: movie.title, image: nil, identifier: nil, children: [favoritesButton])
            }
        }
        
        return configuration
    }
}
