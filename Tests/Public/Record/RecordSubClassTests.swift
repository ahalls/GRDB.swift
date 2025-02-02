import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

private class Person : Record {
    var id: Int64!
    var name: String!
    var age: Int?
    var creationDate: Date!
    
    init(id: Int64? = nil, name: String? = nil, age: Int? = nil, creationDate: Date? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.creationDate = creationDate
        super.init()
    }
    
    static func setup(inDatabase db: Database) throws {
        try db.execute(
            "CREATE TABLE persons (" +
                "id INTEGER PRIMARY KEY, " +
                "creationDate TEXT NOT NULL, " +
                "name TEXT NOT NULL, " +
                "age INT" +
            ")")
    }
    
    // Record
    
    override class func databaseTableName() -> String {
        return "persons"
    }
    
    required init(row: Row) {
        id = row.value(named: "id")
        age = row.value(named: "age")
        name = row.value(named: "name")
        creationDate = row.value(named: "creationDate")
        super.init(row: row)
    }
    
    override var persistentDictionary: [String: DatabaseValueConvertible?] {
        return [
            "id": id,
            "name": name,
            "age": age,
            "creationDate": creationDate,
        ]
    }
    
    override func insert(_ db: Database) throws {
        // This is implicitely tested with the NOT NULL constraint on creationDate
        if creationDate == nil {
            creationDate = Date()
        }
        
        try super.insert(db)
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
}

private class MinimalPersonWithOverrides : Person {
    var extra: Int!
    
    // Record
    
    required init(row: Row) {
        extra = row.value(named: "extra")
        super.init(row: row)
    }
}

private class PersonWithOverrides : Person {
    enum SavingMethod {
        case insert
        case update
    }
    
    var extra: Int!
    var lastSavingMethod: SavingMethod?
    
    override init(id: Int64? = nil, name: String? = nil, age: Int? = nil, creationDate: Date? = nil) {
        super.init(id: id, name: name, age: age, creationDate: creationDate)
    }
    
    // Record
    
    required init(row: Row) {
        extra = row.value(named: "extra")
        super.init(row: row)
    }
    
    override func insert(_ db: Database) throws {
        lastSavingMethod = .insert
        try super.insert(db)
    }
    
    override func update(_ db: Database) throws {
        lastSavingMethod = .update
        try super.update(db)
    }
}

class RecordSubClassTests: GRDBTestCase {
    
    override func setup(_ dbWriter: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPerson", migrate: Person.setup)
        try migrator.migrate(dbWriter)
    }
    
    
    // MARK: - Save
    
    func testSaveWithNilPrimaryKeyCallsInsertMethod() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let record = PersonWithOverrides(name: "Arthur")
                try record.save(db)
                XCTAssertEqual(record.lastSavingMethod!, PersonWithOverrides.SavingMethod.insert)
            }
        }
    }
    
    func testSaveWithNotNilPrimaryKeyThatDoesNotMatchAnyRowCallsInsertMethod() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let record = PersonWithOverrides(id: 123456, name: "Arthur")
                try record.save(db)
                XCTAssertEqual(record.lastSavingMethod!, PersonWithOverrides.SavingMethod.insert)
            }
        }
    }
    
    
    func testSaveWithNotNilPrimaryKeyThatMatchesARowCallsUpdateMethod() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let record = PersonWithOverrides(name: "Arthur", age: 41)
                try record.insert(db)
                record.age = record.age! + 1
                try record.save(db)
                XCTAssertEqual(record.lastSavingMethod!, PersonWithOverrides.SavingMethod.update)
            }
        }
    }
    
    func testSaveAfterDeleteCallsInsertMethod() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let record = PersonWithOverrides(name: "Arthur")
                try record.insert(db)
                try record.delete(db)
                try record.save(db)
                XCTAssertEqual(record.lastSavingMethod!, PersonWithOverrides.SavingMethod.insert)
            }
        }
    }
    
    
    // MARK: - Select
    
    func testSelect() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let record = Person(name: "Arthur", age: 41)
                try record.insert(db)
                
                do {
                    let fetchedRecord = PersonWithOverrides.fetchOne(db, "SELECT *, 123 as extra FROM persons")!
                    XCTAssertTrue(fetchedRecord.id == record.id)
                    XCTAssertTrue(fetchedRecord.name == record.name)
                    XCTAssertTrue(fetchedRecord.age == record.age)
                    XCTAssertTrue(abs(fetchedRecord.creationDate.timeIntervalSince(record.creationDate)) < 1e-3)    // ISO-8601 is precise to the millisecond.
                    XCTAssertTrue(fetchedRecord.extra == 123)
                }
                
                do {
                    let fetchedRecord = MinimalPersonWithOverrides.fetchOne(db, "SELECT *, 123 as extra FROM persons")!
                    XCTAssertTrue(fetchedRecord.id == record.id)
                    XCTAssertTrue(fetchedRecord.name == record.name)
                    XCTAssertTrue(fetchedRecord.age == record.age)
                    XCTAssertTrue(abs(fetchedRecord.creationDate.timeIntervalSince(record.creationDate)) < 1e-3)    // ISO-8601 is precise to the millisecond.
                    XCTAssertTrue(fetchedRecord.extra == 123)
                }
            }
        }
    }
    
}
