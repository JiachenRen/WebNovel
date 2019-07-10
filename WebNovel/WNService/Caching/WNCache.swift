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
    
    enum OperationStatus {
        case created
        case overwritten
    }
    
    /// Saves the WN chapter, cover image, information, or chapters catalogue to core data
    /// If an existing WN chapter with the same url exists, it is overwritten.
    @discardableResult
    static func save<T: Serializable>(_ object: T) throws -> OperationStatus {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        
        let url = object.url
        let request = fetchRequest(url, for: T.ManagedObject.self)
        let (managedObj, created) = try fetchOrCreate(request)
        
        // Update the object's properties
        managedObj.url = url
        managedObj.data = try jsonEncoder.encode(object) as NSObject
        
        // Apply changes
        try ctx.save()
        
        // Return the appropriate status
        return created ? .created : .overwritten
    }
    
    /// Fetches all objects of specified type in core data
    static func fetchAll<T: Serializable>(_ object: T.Type) throws -> [T] {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        
        let request: NSFetchRequest<T.ManagedObject> = T.ManagedObject.fetchRequest() as! NSFetchRequest<T.ManagedObject>
        return try ctx.fetch(request).compactMap {
            guard let data = $0.data as? Data else {
                return nil
            }
            return try jsonDecoder.decode(T.self, from: data)
        }
    }
    
    /// Fetches the first object in core data of corresponding type and url.
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
    private static func fetchOrCreate<T: WNManagedObject>(_ request: NSFetchRequest<T>) throws -> (T, created: Bool) {
        guard let ctx = managedContext else {
            throw WNError.managedContextNotFound
        }
        if let retrieved = try ctx.fetch(request).first {
            return (retrieved, false)
        } else {
            let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: ctx)!
            return (NSManagedObject(entity: entity, insertInto: ctx) as! T, true)
        }
    }
}
