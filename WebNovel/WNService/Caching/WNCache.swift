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
    
    /// Saves the WN chapter, cover image, information, or chapters catalogue to core data
    /// If an existing WN chapter with the same url exists, it is overwritten.
    static func save<T: Serializable>(_ object: T) throws {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        guard let url = object.url else {
            throw WNError.urlNotFound
        }
        
        let request = fetchRequest(url, for: T.ManagedObject.self)
        let managedObj = try fetchOrCreate(request)
        
        // Update the object's properties
        managedObj.url = url
        managedObj.data = try jsonEncoder.encode(object) as NSObject
        
        // Apply changes
        try ctx.save()
    }
    
    /// Fetches the first object in core data of coresponding type and url.
    static func fetch<T: Serializable>(by url: String, object: T.Type) throws -> T? {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        
        let request = fetchRequest(url, for: T.ManagedObject.self)
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
    /// - Returns: Retrieved or newly created WNManagedObject
    private static func fetchOrCreate<T: WNManagedObject>(_ request: NSFetchRequest<T>) throws -> T {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        if let retrieved = try ctx.fetch(request).first {
            return retrieved
        } else {
            let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: ctx)!
            return NSManagedObject(entity: entity, insertInto: ctx) as! T
        }
    }
}
