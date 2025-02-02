import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private class Observer : TransactionObserver {
    var lastCommittedEvents: [DatabaseEvent] = []
    var events: [DatabaseEvent] = []
    
#if SQLITE_ENABLE_PREUPDATE_HOOK
    var preUpdateEvents: [DatabasePreUpdateEvent] = []
    func databaseWillChange(with event: DatabasePreUpdateEvent) {
        preUpdateEvents.append(event.copy())
    }
#endif
    
    func databaseDidChange(with event: DatabaseEvent) {
        events.append(event.copy())
    }
    
    func databaseWillCommit() throws {
    }
    
    func databaseDidCommit(_ db: Database) {
        lastCommittedEvents = events
        events = []
    }
    
    func databaseDidRollback(_ db: Database) {
        lastCommittedEvents = []
        events = []
    }
}

class TransactionObserverSavepointsTests: GRDBTestCase {
    
    private func match(event: DatabaseEvent, kind: DatabaseEvent.Kind, tableName: String, rowId: Int64) -> Bool {
        return (event.tableName == tableName) && (event.rowID == rowId) && (event.kind == kind)
    }
    
#if SQLITE_ENABLE_PREUPDATE_HOOK
    
    private func match(preUpdateEvent event: DatabasePreUpdateEvent, kind: DatabasePreUpdateEvent.Kind, tableName: String, initialRowID: Int64?, finalRowID: Int64?, initialValues: [DatabaseValue]?, finalValues: [DatabaseValue]?, depth: CInt = 0) -> Bool {
        
        func check(databaseValues values: [DatabaseValue]?, expected: [DatabaseValue]?) -> Bool {
            if let values = values {
                guard let expected = expected else { return false }
                return values == expected
            }
            else { return expected == nil }
        }
        
        var count : Int = 0
        if let initialValues = initialValues { count = initialValues.count }
        if let finalValues = finalValues { count = max(count, finalValues.count) }
        
        guard (event.kind == kind) else { return false }
        guard (event.tableName == tableName) else { return false }
        guard (event.count == count) else { return false }
        guard (event.depth == depth) else { return false }
        guard (event.initialRowID == initialRowID) else { return false }
        guard (event.finalRowID == finalRowID) else { return false }
        guard check(databaseValues: event.initialDatabaseValues, expected: initialValues) else { return false }
        guard check(databaseValues: event.finalDatabaseValues, expected: finalValues) else { return false }
        
        return true
    }
    
#endif
    
    
    // MARK: - Events
    func testSavepointAsTransaction() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("SAVEPOINT sp1")
                XCTAssertTrue(db.isInsideTransaction)
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 0)
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 0)
                try db.execute("RELEASE SAVEPOINT sp1")
                XCTAssertFalse(db.isInsideTransaction)
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 2)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items2", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 2)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items2", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
    func testSavepointInsideTransaction() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("BEGIN TRANSACTION")
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("COMMIT")
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 2)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items2", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 2)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items2", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
    func testSavepointWithIdenticalName() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items3 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items4 (id INTEGER PRIMARY KEY)")
                try db.execute("BEGIN TRANSACTION")
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items3 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("RELEASE SAVEPOINT sp1")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("RELEASE SAVEPOINT sp1")
                XCTAssertEqual(observer.events.count, 3)
                try db.execute("INSERT INTO items4 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 4)
                try db.execute("COMMIT")
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items3"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items4"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 4)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items2", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[2], kind: .insert, tableName: "items3", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[3], kind: .insert, tableName: "items4", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 4)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items2", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[2], kind: .Insert, tableName: "items3", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[3], kind: .Insert, tableName: "items4", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
    func testMultipleRollbackOfSavepoint() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items3 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items4 (id INTEGER PRIMARY KEY)")
                try db.execute("BEGIN TRANSACTION")
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("INSERT INTO items3 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("ROLLBACK TO SAVEPOINT sp1")
                try db.execute("INSERT INTO items4 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("ROLLBACK TO SAVEPOINT sp1")
                try db.execute("INSERT INTO items4 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("COMMIT")
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items3"), 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items4"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 2)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items4", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 2)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items4", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
    func testReleaseSavepoint() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items3 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items4 (id INTEGER PRIMARY KEY)")
                try db.execute("BEGIN TRANSACTION")
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                try db.execute("INSERT INTO items3 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("RELEASE SAVEPOINT sp1")
                XCTAssertEqual(observer.events.count, 3)
                try db.execute("INSERT INTO items4 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 4)
                try db.execute("COMMIT")
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items3"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items4"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 4)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items2", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[2], kind: .insert, tableName: "items3", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[3], kind: .insert, tableName: "items4", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 4)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items2", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[2], kind: .Insert, tableName: "items3", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[3], kind: .Insert, tableName: "items4", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
    func testRollbackNonNestedSavepointInsideTransaction() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            let observer = Observer()
            dbQueue.add(transactionObserver: observer)
            
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE items1 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items2 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items3 (id INTEGER PRIMARY KEY)")
                try db.execute("CREATE TABLE items4 (id INTEGER PRIMARY KEY)")
                try db.execute("BEGIN TRANSACTION")
                try db.execute("INSERT INTO items1 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp1")
                try db.execute("INSERT INTO items2 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("SAVEPOINT sp2")
                try db.execute("INSERT INTO items3 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("RELEASE SAVEPOINT sp2")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("ROLLBACK TO SAVEPOINT sp1")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("INSERT INTO items4 (id) VALUES (NULL)")
                XCTAssertEqual(observer.events.count, 1)
                try db.execute("COMMIT")
                
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items1"), 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items2"), 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items3"), 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM items4"), 1)
            }
            
            XCTAssertEqual(observer.lastCommittedEvents.count, 2)
            XCTAssertTrue(match(event: observer.lastCommittedEvents[0], kind: .insert, tableName: "items1", rowId: 1))
            XCTAssertTrue(match(event: observer.lastCommittedEvents[1], kind: .insert, tableName: "items4", rowId: 1))
            
            #if SQLITE_ENABLE_PREUPDATE_HOOK
                XCTAssertEqual(observer.preUpdateEvents.count, 2)
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[0], kind: .Insert, tableName: "items1", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
                XCTAssertTrue(match(preUpdateEvent: observer.preUpdateEvents[1], kind: .Insert, tableName: "items4", initialRowID: nil, finalRowID: 1, initialValues: nil, finalValues: [Int(1).databaseValue]))
            #endif
        }
    }
    
}
