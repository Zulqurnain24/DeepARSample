//
//  FileManagerExtension.swift
// Shaadoow
//
//  Created by Jafar Khan on 9/7/19.
//  Copyright © 2019 Jafar Khan. All rights reserved.
//

import Foundation
import AVFoundation


extension FileManager {

    private static let totalNumberOfVideoAllowedToSave = 50
    private static let totalSizeForCacheVideo = 100.0 //in MB

    enum VideoLocation {
        case normal
        case song
        case recorded
        
        var folderName: String {
            switch self {
            case .normal:
                return "Videos"
            case .song :
                return "Song"
            case .recorded :
                return "Recorded"
            }
        }
    }
    
    static func countOfFiles(videoLocation:VideoLocation) -> Int {
        let fileManager = FileManager.default
        //Getting the document directory
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let videoFolderName = videoLocation.folderName
        //Checking for the directory exist or not
        
        if let pathComponent = url.appendingPathComponent(videoFolderName) {
            let filePath = pathComponent.path
            if fileManager.fileExists(atPath: filePath) {
                //return the directory path
                let dirContents = try? fileManager.contentsOfDirectory(atPath: filePath)
                let count = dirContents?.count
                return count ?? 0
            }
            return 0
            
        }
        return 0
        
    }
    
    static func getLocalVideo(url: URL?, videoLocation:VideoLocation = .recorded) -> URL? {
        let fileName =  URL(fileURLWithPath: url?.path ?? "").lastPathComponent.replacingOccurrences(of: ".mp4", with: "")
        
        if let fileUrl = FileManager.getFile(fileName: fileName + ".mp4", folder: videoLocation) {
                    return fileUrl
                }
                    
                else {
                    return url
                }
    }
    
    static func getLocalImage(url: URL?, videoLocation:VideoLocation = .recorded) -> URL? {
        let fileName =  URL(fileURLWithPath: url?.path ?? "").lastPathComponent.replacingOccurrences(of: ".jpg", with: "")
        
        if let fileUrl = FileManager.getFile(fileName: fileName + ".jpg", folder: videoLocation) {
                    return fileUrl
                }
                    
                else {
                    return url
                }
    }

    
    //Deleting the old video if the folder directory content reaches the maximum count
    private func deleteTheOldFileWhileReachesMaximusSaveCount(videoLocation:VideoLocation) {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let videoFolderName = videoLocation.folderName
        //Checking for the directory exist or not
        
        if let pathComponent = url.appendingPathComponent(videoFolderName), self.fileExists(atPath: pathComponent.path) == true {
            if let urlArray = try? FileManager.default.contentsOfDirectory(at: pathComponent, includingPropertiesForKeys: [.addedToDirectoryDateKey, .totalFileAllocatedSizeKey], options: .skipsHiddenFiles), urlArray.count >= FileManager.totalNumberOfVideoAllowedToSave {
                let arrayTotalVideos = urlArray.map { (url) -> (Date, URL) in
                
                    let item = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                    return (item?.contentModificationDate ?? Date(), url)
                }.sorted { $0.0 < $1.0 }
                print(arrayTotalVideos)

                guard let oldVideo = arrayTotalVideos.first else { return }
                let videoPathUrl = oldVideo.1
                do { try FileManager.default.removeItem(at: videoPathUrl) }
                catch { print(error) }
            }
        }
    }
    
    static func getPathForCacheVideo(folderLocation:String) -> URL {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(folderLocation)
        return assetURL
    }
    
    //Deleting the old video if the folder directory content reaches the maximum count
    func deleteTheOldFileWhileReachesMaximusSaveCounts(folderLocation:String) {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let videoFolderName = folderLocation
        let pathComponent = url.appendingPathComponent(videoFolderName)
        
        //Checking for the directory exist or not
            do {
                let sizeOnDisk = try pathComponent.deletingLastPathComponent().sizeOnDisk() ?? 0.0
                print("sizeOnDisk", sizeOnDisk)
                guard sizeOnDisk >= Self.totalSizeForCacheVideo else { return }
                if let urlArray = try? FileManager.default.contentsOfDirectory(at: pathComponent.deletingLastPathComponent(), includingPropertiesForKeys: [.addedToDirectoryDateKey], options: .skipsHiddenFiles) {
                
                    let arrayTotalVideos = urlArray.map { (url) -> (Date, URL) in
                    
                        let item = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                        return (item?.contentModificationDate ?? Date(), url)
                    }.sorted { $0.0 < $1.0 }

                    guard let oldVideo = arrayTotalVideos.first else { return }
                    print(oldVideo)
                    let videoPathUrl = oldVideo.1
                    do {
                        if videoPathUrl != pathComponent {
                        try FileManager.default.removeItem(at: videoPathUrl)
                        }
                        deleteTheOldFileWhileReachesMaximusSaveCounts(folderLocation: folderLocation)
                    }
                    catch { print(error) }
                }
            }
            catch {
                
            }
    }
 
    private static func videoDirectoryURL(videoLocation:VideoLocation) -> URL? {
        let fileManager = FileManager.default
        //Getting the document directory
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let videoFolderName = videoLocation.folderName
        //Checking for the directory exist or not
        if let pathComponent = url.appendingPathComponent(videoFolderName) {
            let filePath = pathComponent.path
            if fileManager.fileExists(atPath: filePath) {
                //return the directory path
                return pathComponent
            } else {
                //Creating the directory path
                do {
                    let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let documentDirectoryUrl = documentDirectory.appendingPathComponent(videoFolderName, isDirectory: true)
                    try fileManager.createDirectory(at: documentDirectoryUrl, withIntermediateDirectories: false, attributes: nil)
                    return documentDirectoryUrl
                }
                catch {
                    print(error)
                    return nil
                }
            }
        }
        else {
            return nil
        }
    }
    
    static func saveVideo(fileName:String, location: VideoLocation = .normal, path:URL, completion:@escaping (Bool)->Void)  {
        guard let documentDirectory = videoDirectoryURL(videoLocation: location)?.appendingPathComponent(fileName) else { return }
        do {
            let data = try Data(contentsOf: path)
            try data.write(to: documentDirectory)
            completion(true)
        }
        catch {
            print(error)
            completion(false)
        }
    }
    
    static func getFile(fileName:String, folder:VideoLocation = .normal) -> URL? {
        let fileManager = FileManager.default
        //Getting the document directory
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        //Checking for the directory exist or not
        
        if let pathDirectory = url.appendingPathComponent(folder.folderName) {
            let filePath = pathDirectory.appendingPathComponent(fileName).path
            if fileManager.fileExists(atPath: filePath) {
                //return the directory path
                print("Success")
                return URL(fileURLWithPath: filePath)
            }
            else {
                return nil
            }
        }
        else {
            let filePath = url.appendingPathComponent(fileName)?.path ?? ""
            if fileManager.fileExists(atPath: filePath) {
                //return the directory path
                print("Success")
                return URL(fileURLWithPath: filePath)
            }
            else {
                return nil
            }
        }
    }
    
    /// Create  a path in file manager
    ///
    /// - parameter location: The folder location.
    /// - parameter fileName: The file name to be created
    /// - parameter type: The type or extension of file name to be created. And the default value will be mp4
    
    static func createPathFor(location:VideoLocation = .normal, fileName:String, type:String = "mp4") -> URL? {
        let path = videoDirectoryURL(videoLocation: location)
        let outputPath = path?.appendingPathComponent(fileName + "." + type)
        // Be sure that the file isn't exist
        if let outputPathExist = outputPath {
        try? FileManager.default.removeItem(at: outputPathExist)
        }
        //Check if the file is saved on song or recorded directory
        //If so then have to check if new file adding makes the total file count greater than 'totalNumberOfVideoAllowedToSave'
        (location == .song || location == .recorded) ? FileManager.default.deleteTheOldFileWhileReachesMaximusSaveCount(videoLocation: location) : nil
        return outputPath
    }

}


extension URL {
    /// check if the URL is a directory and if it is reachable
    func isDirectoryAndReachable() throws -> Bool {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            return false
        }
        return try checkResourceIsReachable()
    }

    /// returns total allocated size of a the directory including its subFolders or not
    func directoryTotalAllocatedSize(includingSubfolders: Bool = false) throws -> Int? {
        guard try isDirectoryAndReachable() else { return nil }
        if includingSubfolders {
            guard
                let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                    (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
                 (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                    .totalFileAllocatedSize ?? 0) + $0
        }
    }

    /// returns the directory total size on disk
    func sizeOnDisk() throws -> Double? {
        guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return nil }
       return Double(size) / (1e+6)
        
    }
}
