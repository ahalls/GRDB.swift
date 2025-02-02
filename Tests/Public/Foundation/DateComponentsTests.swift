import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class DateComponentsTests : GRDBTestCase {
    
    override func setup(_ dbWriter: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createDates") { db in
            try db.execute(
                "CREATE TABLE dates (" +
                    "ID INTEGER PRIMARY KEY, " +
                    "creationDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ")")
        }
        try migrator.migrate(dbWriter)
    }
    
    func testDatabaseDateComponentsFormatHM() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HM)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HM)
                XCTAssertTrue(databaseDateComponents.dateComponents.year == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.month == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.day == nil)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertTrue(databaseDateComponents.dateComponents.second == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatHMS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HMS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11:12")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HMS)
                XCTAssertTrue(databaseDateComponents.dateComponents.year == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.month == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.day == nil)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatHMSS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "10:11:12.123")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.HMSS)
                XCTAssertTrue(databaseDateComponents.dateComponents.year == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.month == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.day == nil)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond!) / 1.0e6), round(Double(dateComponents.nanosecond!) / 1.0e6))
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertTrue(databaseDateComponents.dateComponents.hour == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.minute == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.second == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD_HM() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HM)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HM)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertTrue(databaseDateComponents.dateComponents.second == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }

    func testDatabaseDateComponentsFormatYMD_HMS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11:12")

                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatYMD_HMSS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "1973-09-18 10:11:12.123")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond!) / 1.0e6), round(Double(dateComponents.nanosecond!) / 1.0e6))
            }
        }
    }
    
    func testUndefinedDatabaseDateComponentsFormatYMD_HMSS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                let dateComponents = DateComponents()
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: [DatabaseDateComponents(dateComponents, format: .YMD_HMSS)])
                
                let string = String.fetchOne(db, "SELECT creationDate from dates")!
                XCTAssertEqual(string, "0000-01-01 00:00:00.000")
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, 1)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, 1)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, 0)
                XCTAssertEqual(databaseDateComponents.dateComponents.nanosecond, 0)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HM() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HM)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertTrue(databaseDateComponents.dateComponents.second == nil)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HMS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11:12"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertTrue(databaseDateComponents.dateComponents.nanosecond == nil)
            }
        }
    }
    
    func testDatabaseDateComponentsFormatIso8601YMD_HMSS() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                
                var dateComponents = DateComponents()
                dateComponents.year = 1973
                dateComponents.month = 9
                dateComponents.day = 18
                dateComponents.hour = 10
                dateComponents.minute = 11
                dateComponents.second = 12
                dateComponents.nanosecond = 123_456_789
                try db.execute("INSERT INTO dates (creationDate) VALUES (?)", arguments: ["1973-09-18T10:11:12.123"])
                
                let databaseDateComponents = DatabaseDateComponents.fetchOne(db, "SELECT creationDate FROM dates")!
                XCTAssertEqual(databaseDateComponents.format, DatabaseDateComponents.Format.YMD_HMSS)
                XCTAssertEqual(databaseDateComponents.dateComponents.year, dateComponents.year)
                XCTAssertEqual(databaseDateComponents.dateComponents.month, dateComponents.month)
                XCTAssertEqual(databaseDateComponents.dateComponents.day, dateComponents.day)
                XCTAssertEqual(databaseDateComponents.dateComponents.hour, dateComponents.hour)
                XCTAssertEqual(databaseDateComponents.dateComponents.minute, dateComponents.minute)
                XCTAssertEqual(databaseDateComponents.dateComponents.second, dateComponents.second)
                XCTAssertEqual(round(Double(databaseDateComponents.dateComponents.nanosecond!) / 1.0e6), round(Double(dateComponents.nanosecond!) / 1.0e6))
            }
        }
    }
    
    func testFormatYMD_HMSIsLexicallyComparableToCURRENT_TIMESTAMP() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                let calendar = Calendar(calendarIdentifier: .gregorian)!
                calendar.timeZone = TimeZone(forSecondsFromGMT: 0)
                do {
                    let date = Date().addingTimeInterval(-1)
                    let dateComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: date)
                    try db.execute(
                        "INSERT INTO dates (id, creationDate) VALUES (?,?)",
                        arguments: [1, DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                }
                do {
                    try db.execute(
                        "INSERT INTO dates (id) VALUES (?)",
                        arguments: [2])
                }
                do {
                    let date = Date().addingTimeInterval(1)
                    let dateComponents = calendar.components([.year, .month, .day, .hour, .minute, .second], from: date)
                    try db.execute(
                        "INSERT INTO dates (id, creationDate) VALUES (?,?)",
                        arguments: [3, DatabaseDateComponents(dateComponents, format: .YMD_HMS)])
                }
                
                let ids = Int.fetchAll(db, "SELECT id FROM dates ORDER BY creationDate")
                XCTAssertEqual(ids, [1,2,3])
            }
        }
    }
    
    func testDatabaseDateComponentsFromUnparsableString() {
        let databaseDateComponents = DatabaseDateComponents.fromDatabaseValue("foo".databaseValue)
        XCTAssertTrue(databaseDateComponents == nil)
    }
    
    func testDatabaseDateComponentsFailureFromNilDateComponents() {
        XCTAssertNil(DatabaseDateComponents(nil, format: .YMD))
    }
}
