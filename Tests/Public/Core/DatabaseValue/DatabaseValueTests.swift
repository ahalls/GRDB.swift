import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class DatabaseValueTests: GRDBTestCase {
    
    func testDatabaseValueAsDatabaseValueConvertible() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            dbQueue.inDatabase { db in
                XCTAssertTrue((Row.fetchOne(db, "SELECT 1")!.value(atIndex: 0) as DatabaseValue).value() is Int64)
                XCTAssertTrue((Row.fetchOne(db, "SELECT 1.0")!.value(atIndex: 0) as DatabaseValue).value() is Double)
                XCTAssertTrue((Row.fetchOne(db, "SELECT 'foo'")!.value(atIndex: 0) as DatabaseValue).value() is String)
                XCTAssertTrue((Row.fetchOne(db, "SELECT x'53514C697465'")!.value(atIndex: 0) as DatabaseValue).value() is Data)
                XCTAssertTrue((Row.fetchOne(db, "SELECT NULL")!.value(atIndex: 0) as DatabaseValue?) == nil)
            }
        }
    }
    
    func testDatabaseValueAsStatementColumnConvertible() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            dbQueue.inDatabase { db in
                XCTAssertTrue(DatabaseValue.fetchOne(db, "SELECT 1")!.value() is Int64)
                XCTAssertTrue(DatabaseValue.fetchOne(db, "SELECT 1.0")!.value() is Double)
                XCTAssertTrue(DatabaseValue.fetchOne(db, "SELECT 'foo'")!.value() is String)
                XCTAssertTrue(DatabaseValue.fetchOne(db, "SELECT x'53514C697465'")!.value() is Data)
                XCTAssertTrue(DatabaseValue.fetchOne(db, "SELECT NULL") == nil)
            }
        }
    }
    
    func testDatabaseValueCanBeUsedAsStatementArgument() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE integers (integer INTEGER)")
                try db.execute("INSERT INTO integers (integer) VALUES (1)")
                let databaseValue: DatabaseValue = 1.databaseValue
                let count = Int.fetchOne(db, "SELECT COUNT(*) FROM integers WHERE integer = ?", arguments: [databaseValue])!
                XCTAssertEqual(count, 1)
            }
        }
    }
    
    func testDatabaseValueEquatable() {
        let fooData = "foo".data(using: .utf8)!
        let barData = "bar".data(using: .utf8)!
        
        XCTAssertEqual(DatabaseValue.null, DatabaseValue.null)
        XCTAssertNotEqual(DatabaseValue.null, 1.databaseValue)
        XCTAssertNotEqual(DatabaseValue.null, 1.0.databaseValue)
        XCTAssertNotEqual(DatabaseValue.null, "foo".databaseValue)
        XCTAssertNotEqual(DatabaseValue.null, fooData.databaseValue)
        
        XCTAssertNotEqual(1.databaseValue, DatabaseValue.null)
        XCTAssertEqual(1.databaseValue, 1.databaseValue)
        XCTAssertNotEqual(1.databaseValue, 2.databaseValue)
        XCTAssertEqual(1.databaseValue, 1.0.databaseValue)
        XCTAssertNotEqual(1.databaseValue, 1.1.databaseValue)
        XCTAssertNotEqual(1.databaseValue, 2.0.databaseValue)
        XCTAssertEqual(Double(Int64(1) << 53).databaseValue, Double(Int64(1) << 53).databaseValue)        // Any integer up to 2^53 has an exact representation as a IEEE-754 double...
        XCTAssertNotEqual((Int64(1) << 53 + 1).databaseValue, Double(Int64(1) << 53 + 1).databaseValue)   // ... 2^53 + 1 does not....
        XCTAssertEqual((Int64(1) << 54).databaseValue, Double(Int64(1) << 54).databaseValue)              // ... but 2^54 does.
        XCTAssertNotEqual(Int64.max.databaseValue, Double(Int64.max).databaseValue)         // ... and Int64.max does not.
        XCTAssertNotEqual(1.databaseValue, "foo".databaseValue)
        XCTAssertNotEqual(1.databaseValue, "1".databaseValue)
        XCTAssertNotEqual(1.databaseValue, "1.0".databaseValue)
        XCTAssertNotEqual(1.databaseValue, fooData.databaseValue)
        
        XCTAssertNotEqual(1.0.databaseValue, DatabaseValue.null)
        XCTAssertEqual(1.0.databaseValue, 1.databaseValue)
        XCTAssertNotEqual(1.1.databaseValue, 1.databaseValue)
        XCTAssertNotEqual(1.0.databaseValue, 2.databaseValue)
        XCTAssertEqual(1.0.databaseValue, 1.0.databaseValue)
        XCTAssertNotEqual(1.0.databaseValue, 2.0.databaseValue)
        XCTAssertEqual(Double(Int64(1) << 53).databaseValue, Double(Int64(1) << 53).databaseValue)        // Any integer up to 2^53 has an exact representation as a IEEE-754 double...
        XCTAssertNotEqual(Double(Int64(1) << 53 + 1).databaseValue, (Int64(1) << 53 + 1).databaseValue)   // ... 2^53 + 1 does not....
        XCTAssertEqual(Double(Int64(1) << 54).databaseValue, (Int64(1) << 54).databaseValue)              // ... but 2^54 does.
        XCTAssertNotEqual(Double(Int64.max).databaseValue, Int64.max.databaseValue)         // ... and Int64.max does not.
        XCTAssertNotEqual(1.0.databaseValue, "foo".databaseValue)
        XCTAssertNotEqual(1.0.databaseValue, "1".databaseValue)
        XCTAssertNotEqual(1.0.databaseValue, "1.0".databaseValue)
        XCTAssertNotEqual(1.0.databaseValue, fooData.databaseValue)
        
        XCTAssertNotEqual("foo".databaseValue, DatabaseValue.null)
        XCTAssertNotEqual("foo".databaseValue, 1.databaseValue)
        XCTAssertNotEqual("foo".databaseValue, 1.0.databaseValue)
        XCTAssertEqual("foo".databaseValue, "foo".databaseValue)
        XCTAssertNotEqual("foo".databaseValue, "bar".databaseValue)
        XCTAssertNotEqual("foo".databaseValue, fooData.databaseValue)
        
        XCTAssertNotEqual(fooData.databaseValue, DatabaseValue.null)
        XCTAssertNotEqual(fooData.databaseValue, 1.databaseValue)
        XCTAssertNotEqual(fooData.databaseValue, 1.0.databaseValue)
        XCTAssertNotEqual(fooData.databaseValue, "foo".databaseValue)
        XCTAssertEqual(fooData.databaseValue, fooData.databaseValue)
        XCTAssertNotEqual(fooData.databaseValue, barData.databaseValue)
    }
    
    func testDatabaseValueHash() {
        // Equal => Same hash
        let intValue = 1.databaseValue
        let doubleValue = 1.0.databaseValue
        XCTAssertEqual(intValue, doubleValue)
        XCTAssertEqual(intValue.hashValue, doubleValue.hashValue)
        
        let string1 = "foo".databaseValue
        let string2 = "foo".databaseValue
        XCTAssertEqual(string1, string2)
        XCTAssertEqual(string1.hashValue, string2.hashValue)
        
        let fooData1 = "foo".data(using: .utf8)!.databaseValue
        let fooData2 = "foo".data(using: .utf8)!.databaseValue
        XCTAssertEqual(fooData1, fooData2)
        XCTAssertEqual(fooData1.hashValue, fooData2.hashValue)
    }
    
    func testNullDatabaseValueGetValue() {
        let databaseValue_Null = DatabaseValue.null
        XCTAssertNil(databaseValue_Null.value())
    }
    
    func testDatabaseValueDescription() {
        let databaseValue_Null = DatabaseValue.null
        let databaseValue_Int64 = Int64(1).databaseValue
        let databaseValue_Double = Double(100000.1).databaseValue
        // TODO: String & Blob
        
        XCTAssertEqual(databaseValue_Null.description, "NULL")
        XCTAssertEqual(databaseValue_Int64.description, "1")
        XCTAssertEqual(databaseValue_Double.description, "100000.1")
    }
}
