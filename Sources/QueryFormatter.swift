//
//  Query.swift
//  MySQL
//
//  Created by Yusuke Ito on 12/14/15.
//  Copyright © 2015 Yusuke Ito. All rights reserved.
//

import Foundation

public protocol QueryParameter {
    func escapedValueWith(option option: QueryParameterOption) throws -> String
}

public protocol QueryParameterDictionaryType: QueryParameter {
    func queryParameter() throws -> QueryDictionary
}

public extension QueryParameterDictionaryType {
    func escapedValueWith(option option: QueryParameterOption) throws -> String {
        return try queryParameter().escapedValueWith(option: option)
    }
}

public struct QueryParameterOption {
    let timeZone: Connection.TimeZone
}


public struct QueryParameterNull: QueryParameter, NilLiteralConvertible {
    public init() {
        
    }
    public init(nilLiteral: ()) {
        
    }
    public func escapedValueWith(option option: QueryParameterOption) -> String {
        return "NULL"
    }
}


struct SQLString {
    
    internal static func escapeId(str: String) -> String {
        var step1: [Character] = []
        for c in str.characters {
            switch c {
                case "`":
                step1.appendContentsOf("``".characters)
            default:
                step1.append(c)
            }
        }
        var out: [Character] = []
        for c in step1 {
            switch c {
                case ".":
                out.appendContentsOf("`.`".characters)
                default:
                out.append(c)
            }
        }
        return "`" + String(out) + "`"
    }
    
    internal static func escape(str: String) -> String {
        var out: [Character] = []
        for c in str.unicodeScalars {
            switch c {
            case "\0":
                out.appendContentsOf("\\0".characters)
            case "\n":
                out.appendContentsOf("\\n".characters)
            case "\r":
                out.appendContentsOf("\\r".characters)
            case "\u{8}":
                out.appendContentsOf("\\b".characters)
            case "\t":
                out.appendContentsOf("\\t".characters)
            case "\\":
                out.appendContentsOf("\\\\".characters)
            case "'":
                out.appendContentsOf("\\'".characters)
            case "\"":
                out.appendContentsOf("\\\"".characters)
            case "\u{1A}":
                out.appendContentsOf("\\Z".characters)
            default:
                out.append(Character(c))
            }
        }
        return "'" + String(out) + "'"
    }
}

public struct QueryFormatter {
    
    public static func format<S: SequenceType where S.Generator.Element == QueryParameter>(query: String, args argsg: S, option: QueryParameterOption) throws -> String {
        var args: [QueryParameter] = []
        for a in argsg {
            args.append(a)
        }
        
        var placeHolderCount: Int = 0
        
        var formatted = query + ""
        
        var valArgs: [QueryParameter] = []
        var scanRange = formatted.startIndex..<formatted.endIndex
        
        // format ??
        while true {
            let r1 = formatted.rangeOfString("??", options: [], range: scanRange, locale: nil)
            let r2 = formatted.rangeOfString("?", options: [], range: scanRange, locale: nil)
            let r: Range<String.Index>
            if let r1 = r1, let r2 = r2 {
                r = r1.startIndex <= r2.startIndex ? r1 : r2
            } else if let rr = r1 ?? r2 {
                r = rr
            } else {
                break
            }
            
            switch formatted[r] {
            case "??":
                if placeHolderCount >= args.count {
                    throw QueryError.QueryParameterCountMismatch(query: query)
                }
                guard let val = args[placeHolderCount] as? String else {
                    throw QueryError.QueryParameterIdTypeError(query: query)
                }
                formatted.replaceRange(r, with: SQLString.escapeId(val))
                scanRange = r.endIndex..<formatted.endIndex
            case "?":
                if placeHolderCount >= args.count {
                    throw QueryError.QueryParameterCountMismatch(query: query)
                }
                valArgs.append(args[placeHolderCount])
                scanRange = r.endIndex..<formatted.endIndex
            default: break
            }
            
            placeHolderCount += 1
            
            if placeHolderCount >= args.count {
                break
            }
        }
        
        //print(formatted, valArgs)
        
        placeHolderCount = 0
        var formattedChars = Array(formatted.characters)
        var index: Int = 0
        while index < formattedChars.count {
            if formattedChars[index] == "?" {
                if placeHolderCount >= valArgs.count {
                    throw QueryError.QueryParameterCountMismatch(query: query)
                }
                let val = valArgs[placeHolderCount]
                formattedChars.removeAtIndex(index)
                let valStr = (try val.escapedValueWith(option: option))
                formattedChars.insertContentsOf(valStr.characters, at: index)
                index += valStr.characters.count-1
                placeHolderCount += 1
            } else {
                index += 1
            }
        }
        
        return String(formattedChars)
    }
}

extension Connection {
    
    public func query<T: QueryRowResultType>(query: String, _ args: [QueryParameter] = []) throws -> ([T], QueryStatus) {
        let option = QueryParameterOption(
            timeZone: options.timeZone
        )
        return try self.query(query: try QueryFormatter.format(query, args: args, option: option))
    }
    
    public func query<T: QueryRowResultType>(query: String, _ args: [QueryParameter] = []) throws -> [T] {
        let (rows, _) = try self.query(query, args) as ([T], QueryStatus)
        return rows
    }
    
    public func query(query: String, _ args: [QueryParameter] = []) throws -> QueryStatus {
        let (_, status) = try self.query(query, args) as ([EmptyRowResult], QueryStatus)
        return status
    }
}