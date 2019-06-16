//
//  WNCache.swift
//  WebNovel
//
//  Created by Jiachen Ren on 6/16/19.
//  Copyright © 2019 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class WNCache {
    private static var managedContext: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()
    
    enum Policy {
        case overwritesCache
        case usesCache
    }
    
    /// Saves loaded chapters for the given url to core data
    static func save(_ wnChaptersCatalogue: WNChaptersCatalogue) throws {
        try save(object: wnChaptersCatalogue, managedObject: ChaptersCatalogue.self)
    }
    
    /// Saves the WN to core data
    /// If an existing WN entry with the same url exists, it is overwritten.
    static func save(_ webNovel: WebNovel) throws {
        try save(object: webNovel, managedObject: Novel.self)
    }
    
    /// Saves the WN chapter to core data
    /// If an existing WN chapter with the same url exists, it is overwritten.
    static func save(_ wnChapter: WNChapter) throws {
        try save(object: wnChapter, managedObject: Chapter.self)
    }
    
    /// Saves the WN chapter to core data
    /// If an existing WN chapter with the same url exists, it is overwritten.
    private static func save<T: Serializable, K: WNManagedObject>(object: T, managedObject: K.Type) throws {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        guard let url = object.url else {
            throw WNError.urlNotFound
        }
        
        let request = fetchRequest(url, for: K.self)
        let chapter = try fetchOrCreate(request, entityName: T.entityName)
        
        // Update the object's properties
        chapter.url = url
        chapter.data = try jsonEncoder.encode(object) as NSObject
        
        // Apply changes
        try ctx.save()
    }
    
    static func fetchWebNovel(by url: String) throws -> WebNovel? {
        return try fetch(by: url, managedObject: Novel.self, object: WebNovel.self)
    }
    
    static func fetchChapter(by url: String) throws -> WNChapter? {
        return try fetch(by: url, managedObject: Chapter.self, object: WNChapter.self)
    }
    
    static func fetchChaptersCatalogue(by url: String) throws -> WNChaptersCatalogue? {
        return try fetch(by: url, managedObject: ChaptersCatalogue.self, object: WNChaptersCatalogue.self)
    }
    
    private static func fetch<T: Codable, K: WNManagedObject>(by url: String, managedObject: K.Type, object: T.Type) throws -> T? {
        guard let ctx = managedContext else {
            throw WNError.urlNotFound
        }
        
        let request = fetchRequest(url, for: K.self)
        if let obj = try ctx.fetch(request).first {
            if let data = obj.data as? Data {
                return try jsonDecoder.decode(T.self, from: data)
            }
        }
        
        return nil
    }
    
    /// Create a WN fetch request for WNs with matching URL.
    private static func fetchRequest<T: NSManagedObject>(_ url: String, for obj: T.Type) -> NSFetchRequest<T> {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.predicate = NSPredicate(format: "url == %@", url)
        return fetchRequest
    }
    
    /// If the requested object already exists in core data, the object is returned;
    /// if not, a new object is created from provided entity name.
    /// - Parameter request: A NSFetchRequest for retrieving object
    /// - Parameter entityName: The entity name for the object
    /// - Returns: Retrieved or newly created NSManagedObject
    private static func fetchOrCreate<T>(_ request: NSFetchRequest<T>, entityName: String) throws -> T {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        if let retrieved = try ctx.fetch(request).first {
            return retrieved
        } else {
            let entity = NSEntityDescription.entity(forEntityName: entityName, in: ctx)!
            return NSManagedObject(entity: entity, insertInto: ctx) as! T
        }
    }
}
