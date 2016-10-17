//
//  Serializable.swift
//
//  Created by Brandon Lehner on 8/15/15.
//  Copyright © 2015 App Techies. All rights reserved.
//

import UIKit

public class Serializable: NSObject
{
    private static let lessThanString = "<"
    private static let greaterThanString = ">"
    private static let periodString = "."
    
    let dateFormatter: DateFormatter?
    
    required public override init() {
        super.init()
        
    }
    
    public static func serialize(items: [Serializable]) -> [[String:AnyObject]] {
        var serializedItems = [[String:AnyObject]]()
        for item in items {
            serializedItems.append(item.serialize())
        }
        
        return serializedItems
    }
    
    // Convert this object into a dictionary
    public func serialize() -> [String:AnyObject] {
        var transfer = [String:AnyObject]()
        let mirror = Mirror(reflecting: self)
        for i in mirror.children
        {
            // If this is a collection, serialize all children
            if let values = i.value as? NSArray {
                var serializedChildren = [[String:AnyObject]]()
                for item in values {
                    serializedChildren.append((item as AnyObject).serialize())
                }
                
                transfer[i.label!] = serializedChildren as AnyObject?
            }
                // If this is a serializable object, serialize it
            else if let value = i.value as? Serializable {
                transfer[i.label!] = value.serialize() as AnyObject?
            }
                // Otherwise, serialize the property as long as it is not nil
            else {
                if let value = i.value as? NSNumber {
                    transfer[i.label!] = value
                } else if let value = i.value as? Int8 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Int16 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Int32 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Int64 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Double {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Float {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? Bool {
                    transfer[i.label!] = NSNumber(value: value)
                } else if i.value is String {
                    transfer[i.label!] = i.value as AnyObject
                } else if i.value is Date {
                    
                    if self.dateFormatter == nil {
                        self.dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
                    }
                    
                    transfer[i.label!] = dateFormatter.string(from: i.value as! Date) as AnyObject?
                } else if let value = i.value as? UInt8 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? UInt16 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? UInt32 {
                    transfer[i.label!] = NSNumber(value: value)
                } else if let value = i.value as? UInt64 {
                    transfer[i.label!] = NSNumber(value: value)
                }
            }
        }
        
        return transfer
    }
    
    func propertyValueByName(propertyName: String) -> [Serializable]! {
        let mirror = Mirror(reflecting: self)
        for i in mirror.children
        {
            if i.label == propertyName {
                return i.value as? [Serializable]
            }
        }
        
        return nil
    }
    
    // Convert a dictionary to an object of type T
    public static func deserialize<T: Serializable>(_ transfer: Any) -> T {
        let target = T()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        
        if let data = transfer as? Data { // If we were given data
            let jsonData = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return deserialize(jsonData)
        } else if let transfer = transfer as? [String:AnyObject] { // If we were given a json object
            target.deserialize(transfer: transfer, dateFormatter: dateFormatter, dateFormatter2: dateFormatter2)
        }
        
        return target
    }
    
    // Convert a dictionary to an object of type T
    public static func deserialize<T: Serializable>(_ transfer: Any) -> [T] {
        var target = [T]()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        
        if let data = transfer as? Data { // If we were given data
            let jsonData = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return deserialize(jsonData)
        } else if let transfer = transfer as? [Any] { // If we were given an array of json objects
            for item in transfer {
                let newItem = T()
                newItem.deserialize(transfer: item as! [String : AnyObject], dateFormatter: dateFormatter, dateFormatter2: dateFormatter2)
                target.append(newItem)
            }
        }
        
        return target
    }
    
    public func deserialize(transfer: [String:AnyObject], dateFormatter: DateFormatter, dateFormatter2: DateFormatter) {
        for item in transfer {
            if let values = item.1 as? NSArray {
                var children = [Serializable]()
                
                var parameterTypeString = self.getTypeOfVariableWithName(name: item.0)
                parameterTypeString = parameterTypeString?.components(separatedBy: Serializable.lessThanString).last
                parameterTypeString = parameterTypeString?.components(separatedBy: Serializable.greaterThanString).first
                
                let extensionParameterTypeStringArray = parameterTypeString?.components(separatedBy: Serializable.periodString)
                if (extensionParameterTypeStringArray?.count)! > 1 {
                    parameterTypeString = extensionParameterTypeStringArray?.last
                }
                
                let nsobjectype : NSObject.Type = NSClassFromString(parameterTypeString!) as! NSObject.Type
                
                for value in values {
                    let child: Serializable = (nsobjectype.init() as? Serializable)!
                    child.deserialize(transfer: value as! [String : AnyObject], dateFormatter: dateFormatter, dateFormatter2: dateFormatter2)
                    children.append(child)
                }
                
                self.setValue(children, forKey: item.0)
            } else if let _ = item.1 as? NSDictionary {
                var parameterTypeString = self.getTypeOfVariableWithName(name: item.0)
                parameterTypeString = parameterTypeString?.components(separatedBy: Serializable.lessThanString).last
                parameterTypeString = parameterTypeString?.components(separatedBy: Serializable.greaterThanString).first
                
                let extensionParameterTypeStringArray = parameterTypeString?.components(separatedBy: Serializable.periodString)
                if (extensionParameterTypeStringArray?.count)! > 1 {
                    parameterTypeString = extensionParameterTypeStringArray?.last
                }
                
                let nsobjectype : NSObject.Type = NSClassFromString(parameterTypeString!) as! NSObject.Type
                
                let child: Serializable = (nsobjectype.init() as? Serializable)!
                child.deserialize(transfer: item.1 as! [String : AnyObject], dateFormatter: dateFormatter, dateFormatter2: dateFormatter2)
                
                self.setValue(child, forKey: item.0)
            } else {
                if let stringValue = item.1 as? String {
                    if let date = dateFormatter.date(from: stringValue) {
                        self.setValue(date, forKey: item.0)
                    } else if let  date = dateFormatter2.date(from: stringValue) {
                        self.setValue(date, forKey: item.0)
                    } else {
                        self.setValue(item.1, forKey: item.0)
                    }
                } else {
                    self.setValue(item.1, forKey: item.0)
                }
            }
        }
    }
    
    func getTypeOfVariableWithName(name: String) -> String! {
        let mirror = Mirror(reflecting: self)
        for i in mirror.children
        {
            if i.label == name {
                let longName = String(describing: type(of: i.value))
                return longName
            }
        }
        
        return nil
    }
}
