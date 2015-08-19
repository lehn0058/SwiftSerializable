//
//  Serializable.swift
//  fit
//
//  Created by Brandon Lehner on 8/15/15.
//  Copyright © 2015 App Techies. All rights reserved.
//

import UIKit

class Serializable: NSObject
{
    required override init() {
        super.init()
    }
    
    // Convert this object into a dictionary
    func serialize() -> [String:AnyObject] {
        var transfer = [String:AnyObject]()
        let mirror = Mirror(reflecting: self)
        for i in mirror.children
        {
            // If this is a collection, serialize all children
            if let values = i.value as? NSArray {
                var serializedChildren = [[String:AnyObject]]()
                for item in values {
                    serializedChildren.append(item.serialize())
                }
                
                transfer[i.label!] = serializedChildren
            }
                // Otherwise, serialize the property as long as it is not nil
            else if let value = i.value as? AnyObject {
                transfer[i.label!] = value
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
    static func deserialize<T: Serializable>(transfer: [String:AnyObject]) -> T {
        let target = T()
        
        for item in transfer {
            if let values = item.1 as? NSArray {
                var children = [Serializable]()
                
                var parameterTypeString = target.getTypeOfVariableWithName(item.0)
                parameterTypeString = parameterTypeString?.componentsSeparatedByString("<").last
                parameterTypeString = parameterTypeString?.componentsSeparatedByString(">").first
                
                let extensionParameterTypeStringArray = parameterTypeString?.componentsSeparatedByString(".")
                if extensionParameterTypeStringArray?.count > 1 {
                    parameterTypeString = extensionParameterTypeStringArray?.last
                }
                
                let nsobjectype : NSObject.Type = NSClassFromString(parameterTypeString!) as! NSObject.Type
                
                for value in values {
                    let child: Serializable = (nsobjectype.init() as? Serializable)!
                    child.deserialize(value as! [String : AnyObject])
                    children.append(child)
                }
                
                target.setValue(children, forKey: item.0)
            } else {
                target.setValue(item.1, forKey: item.0)
            }
        }
        
        return target
    }
    
    func deserialize(transfer: [String:AnyObject]) {
        
        for item in transfer {
            if let values = item.1 as? NSArray {
                var children = [Serializable]()
                
                var parameterTypeString = self.getTypeOfVariableWithName(item.0)
                parameterTypeString = parameterTypeString?.componentsSeparatedByString("<").last
                parameterTypeString = parameterTypeString?.componentsSeparatedByString(">").first
                
                let extensionParameterTypeStringArray = parameterTypeString?.componentsSeparatedByString(".")
                if extensionParameterTypeStringArray?.count > 1 {
                    parameterTypeString = extensionParameterTypeStringArray?.last
                }
                
                let nsobjectype : NSObject.Type = NSClassFromString(parameterTypeString!) as! NSObject.Type
                
                for value in values {
                    let child: Serializable = (nsobjectype.init() as? Serializable)!
                    child.deserialize(value as! [String : AnyObject])
                    children.append(child)
                }
                
                self.setValue(children, forKey: item.0)
            } else {
                self.setValue(item.1, forKey: item.0)
            }
        }
    }
    
    func getTypeOfVariableWithName(name: String) -> String! {
        let mirror = Mirror(reflecting: self)
        mirror.subjectType
        for i in mirror.children
        {
            if i.label == name {
                let longName = _stdlib_getDemangledTypeName(i.value)
                return longName
            }
        }
        
        return nil
    }
}
