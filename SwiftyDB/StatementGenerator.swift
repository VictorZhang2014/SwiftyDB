//
//  QueryGenerator.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 27/12/15.
//

import Foundation

internal enum SQLiteDatatype: String {
    case Text       = "TEXT"
    case Integer    = "INTEGER"
    case Real       = "REAL"
    case Blob       = "BLOB"
    case Numeric    = "NUMERIC"
    case Null       = "NULL"
    
    init?(type: Value.Type) {
        switch type {
        case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type, is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is Bool.Type:
            self.init(rawValue: "INTEGER")
        case is Double.Type, is Float.Type, is Date.Type:
            self.init(rawValue: "REAL")
        case is Data.Type:
            self.init(rawValue: "BLOB")
        case is NSNumber.Type:
            self.init(rawValue: "NUMERIC")
        case is String.Type, is NSString.Type, is Character.Type:
            self.init(rawValue: "TEXT")
        case is NSArray.Type, is NSDictionary.Type:
            self.init(rawValue: "BLOB")
        default:
            fatalError("DSADSASA")
        }
    }
}

internal class StatementGenerator {
    
    internal class func createTableStatementForTypeRepresentedByObject <S: Storable> (_ object: S) -> String {
        let tableName =  tableNameForType(S.self)
        
        var statement = "CREATE TABLE " + tableName + " ("
        
        for propertyData in PropertyData.validPropertyDataForObject(object) {
            statement += "\(propertyData.name!) \(SQLiteDatatype(type: propertyData.type!)!.rawValue)"
            statement += propertyData.isOptional ? "" : " NOT NULL"
            statement += ", "
        }
        
        if S.self is PrimaryKeys.Type {
            let primaryKeysType = S.self as! PrimaryKeys.Type
            statement += "PRIMARY KEY (\(primaryKeysType.primaryKeys().joined(separator: ", ")))"
        }
        
        statement += ")"
        
        return statement
    }
    
    internal class func insertStatementForType(_ type: Storable.Type, update: Bool) -> String {
        var statement = "INSERT OR " + (update ? "REPLACE" : "ABORT") + " INTO " + tableNameForType(type)
        
        let propertyData = PropertyData.validPropertyDataForObject(type.init())
        
        let columns = propertyData.map {$0.name!}
        let namedParameters = columns.map {":" + $0}
        
        /* Columns to be inserted */
        statement += " (" + columns.joined(separator: ", ") + ") "
        
        /* Values to be inserted */
        statement += "VALUES (" + namedParameters.joined(separator: ", ") + ")"
        
        return statement
    }
    
    internal class func selectStatementForType(_ type: Storable.Type, matchingFilter filter: Filter?) -> String {
        
        let tableName =  tableNameForType(type)
        
        var statement = "SELECT ALL * FROM \(tableName)"
        
        guard filter != nil else {
            return statement
        }
        
        statement += " " + filter!.whereStatement()
        
        return statement
    }
    
    internal class func deleteStatementForType(_ type: Storable.Type, matchingFilter filter: Filter?) -> String {
        
        let tableName =  tableNameForType(type)
        
        var statement = "DELETE FROM \(tableName)"
        
        guard filter != nil else {
            return statement
        }
                
        statement += " \(filter!.whereStatement())"
        
        return statement
    }
    
    
    
    /** Name of the table representing a class */
    fileprivate class func tableNameForType(_ type: Storable.Type) -> String {
        return String(describing: type)
    }
}