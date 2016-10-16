
import UIKit

//: Serializable implementation
public class Serializable: NSObject
{
    private static let lessThanString = "<"
    private static let greaterThanString = ">"
    private static let periodString = "."
    
    let dateFormatter = DateFormatter()
    
    required public override init() {
        super.init()
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
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

//: Demonstration on how to get serialization to work. Each class that can be serialized must extend Serializable. Also, it must have the @objc tag at the top of the class

@objc(Testing)
internal class Testing: Serializable {
    
    var name: String!
    var someNumber: NSNumber!
    var children = [TestingChild]()
    
    required init() {
        super.init()
    }
    
    init(name: String, someNumber: NSNumber) {
        self.name = name
        self.someNumber = someNumber
    }
}

@objc(TestingChild)
internal class TestingChild: Serializable {
    
    var name2: String!
    var someNumber2: NSNumber!
    var optionalTest: NSNumber?
    var date: Date?
    var testInt: Int = 0
    var testInt32: Int32 = 0
    var testBool: Bool = false
    
    required init() {
        super.init()
    }
    
    init(name: String, someNumber: NSNumber, testBool: Bool) {
        self.name2 = name
        self.someNumber2 = someNumber
        self.date = Date()
        self.testInt = someNumber.intValue
        self.testInt32 = someNumber.int32Value
        self.testBool = testBool
    }
}

//: Here we create a custom Testing entity. It has a collection of TestingChild entities to show that we can serialize/deserialize custom entities that are related to other custom entities

var testing = Testing(name: "my name", someNumber: 1)
testing.children.append(TestingChild(name: "cname", someNumber: 11231, testBool: true))
testing.children.append(TestingChild(name: "cname2", someNumber: 22222, testBool: true))
testing.children.append(TestingChild(name: "cname3", someNumber: 33333, testBool: true))

// Serialize the testing object to an NSDictionary
let serializedTesting = testing.serialize()
print(serializedTesting)

let data = try! JSONSerialization.data(withJSONObject: serializedTesting, options: JSONSerialization.WritingOptions.prettyPrinted)
let jsonData = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)

// NOTE: Here is where you can send your object between an iOS and watchOS app using the WCSession.sendMessage method that sends an NSDictionary
// NOTE: If you needed to send your entity to a web servie, you could convert serializedTesting to json or NSData at this point.

// Deserialize the object
let deserializedTesting: Testing = Serializable.deserialize(jsonData)
deserializedTesting.name
deserializedTesting.someNumber

deserializedTesting.children[0].name2
deserializedTesting.children[1].name2
deserializedTesting.children[2].name2

deserializedTesting.children[0].someNumber2
deserializedTesting.children[1].someNumber2
deserializedTesting.children[2].someNumber2

deserializedTesting.children[2].optionalTest
deserializedTesting.children[2].date
deserializedTesting.children[2].testInt
deserializedTesting.children[2].testInt32
deserializedTesting.children[2].testBool



