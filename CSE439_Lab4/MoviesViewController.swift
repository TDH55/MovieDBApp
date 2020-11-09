//
//  MoviesViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 10/27/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

//TODO: Implement favorites
//TODO: Creative portion: 1. allow for favorites offline, 2. pagination? 3. sort?
//TODO: Context menu
//TODO: Fix collection view cell movie labels - add a parent uiview to label
//TODO: custom tab bar image

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
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
    func cacheImages(){
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
            self.executeQuery(query: self.currentQuery)
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

