//
//  Connection-Transaction.swift
//  MySQL
//
//  Created by ito on 12/24/15.
//  Copyright © 2015 Yusuke Ito. All rights reserved.
//


extension Connection {
    
    func beginTransaction() throws {
        try query("START TRANSACTION;")
    }

    func commit() throws {
        try query("COMMIT;")
    }
    
    func rollback() throws {
        try query("ROLLBACK;")
    }
}

extension ConnectionPool {
    
    public func transaction<T>(@noescape block: (conn: Connection) throws -> T  ) throws -> T {
        let conn = try getConnection()
        defer {
            releaseConnection(conn)
        }
        try conn.beginTransaction()
        do {
            let result = try block(conn: conn)
            try conn.commit()
            return result
        } catch (let e) {
            do {
                try conn.rollback()
            } catch (let e) {
                print(e)
            }
            throw e
        }
    }
}