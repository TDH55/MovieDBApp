//
//  MoviesViewController.swift
//  CSE439_Lab4
//
//  Created by Taylor Howard on 10/27/20.
//  Copyright © 2020 Taylor Howard. All rights reserved.
//

import UIKit

enum APIError: Error {
    case inavlidURL
    case noImage
}
class MovieCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var posterImageView: UIImageView!
}

class MoviesViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var movieCollectionView: UICollectionView!
    
    let apiKey = "api_key=d5d50f98654e01d24371f44ad6fa09ee"
    let apiBaseURL = "https://api.themoviedb.org/3/"
    let imageBaseURL = "https://image.tmdb.org/t/p/w92"
    let apiURLLang = "&language=en-US"
    let apiURLPage = "&page="
    private let apiURLPopular = "movie/popular?"
    
    var currentSearch: String = ""
    
    var getPopular: Bool = true
    var currentPage: Int = 1
    
    var movieList: [Movie] = []
    var imageCache: [UIImage] = []
    
    var loading: Bool = false
    
    var currentQuery: String {
        return "https://api.themoviedb.org/3/search/movie?api_key=d5d50f98654e01d24371f44ad6fa09ee&language=en-US&query=\(currentSearch)&page=1&include_adult=false"
    }
    
    
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 50.0,
    left: 20.0,
    bottom: 50.0,
    right: 20.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        movieCollectionView.dataSource = self
        movieCollectionView.delegate = self
        DispatchQueue.global(qos: .userInitiated).async {
            self.getPopular(pageNumber: self.currentPage)
            self.cacheImages()
            DispatchQueue.main.async {
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
    
    func cacheImages(){
//        imageCache = []
        for i in imageCache.count ..< movieList.count{
            let movie = movieList[i]
            guard let posterPath = movie.poster_path else { return }
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
        movieList.append(contentsOf: res.results)
        if currentPage < res.total_pages {
            currentPage = currentPage + 1
        } else{
            currentPage = 1
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCollectionViewCell
        
        
        cell.posterImageView.image = imageCache[indexPath.item]
        
        return cell
    }
    
}


extension MoviesViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
//        let availableWidth = view.frame.width - paddingSpace
//        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: 92.0, height: 138.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}

extension MoviesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let numberOfItems = movieList.count
        if((indexPath.item == numberOfItems - 1) && !loading){
            //get next page
            DispatchQueue.global(qos: .userInitiated).async {
                if(self.getPopular){
                    self.getPopular(pageNumber: self.currentPage)
                    self.cacheImages()
                } else{
                    print("exuctute current query")
                    
                }
                DispatchQueue.main.async {
                    self.movieCollectionView.reloadData()
                    self.loading = false
                }
            }
        }
    }
}
