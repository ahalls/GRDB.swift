import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class DictionaryRowTests: GRDBTestCase {
    
    func testRowAsSequence() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        
        var columnNames = Set<String>()
        var ints = Set<Int>()
        var bools = Set<Bool>()
        for (columnName, databaseValue) in row {
            columnNames.insert(columnName)
            ints.insert(databaseValue.value() as Int)
            bools.insert(databaseValue.value() as Bool)
        }
        
        XCTAssertEqual(columnNames, ["a", "b", "c"])
        XCTAssertEqual(ints, [0, 1, 2])
        XCTAssertEqual(bools, [false, true, true])
    }
    
    func testRowValueAtIndex() {
        let dictionary: [String: DatabaseValueConvertible?] = ["a": 0, "b": 1, "c": 2]
        let row = Row(dictionary)
        
        let aIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "a")!)
        let bIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "b")!)
        let cIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "c")!)
        
        // Int extraction, form 1
        XCTAssertEqual(row.value(atIndex: aIndex) as Int, 0)
        XCTAssertEqual(row.value(atIndex: bIndex) as Int, 1)
        XCTAssertEqual(row.value(atIndex: cIndex) as Int, 2)
        
        // Int extraction, form 2
        XCTAssertEqual(row.value(atIndex: aIndex)! as Int, 0)
        XCTAssertEqual(row.value(atIndex: bIndex)! as Int, 1)
        XCTAssertEqual(row.value(atIndex: cIndex)! as Int, 2)
        
        // Int? extraction
        XCTAssertEqual((row.value(atIndex: aIndex) as Int?), 0)
        XCTAssertEqual((row.value(atIndex: bIndex) as Int?), 1)
        XCTAssertEqual((row.value(atIndex: cIndex) as Int?), 2)
        
        // Bool extraction, form 1
        XCTAssertEqual(row.value(atIndex: aIndex) as Bool, false)
        XCTAssertEqual(row.value(atIndex: bIndex) as Bool, true)
        XCTAssertEqual(row.value(atIndex: cIndex) as Bool, true)
        
        // Bool extraction, form 2
        XCTAssertEqual(row.value(atIndex: aIndex)! as Bool, false)
        XCTAssertEqual(row.value(atIndex: bIndex)! as Bool, true)
        XCTAssertEqual(row.value(atIndex: cIndex)! as Bool, true)
        
        // Bool? extraction
        XCTAssertEqual((row.value(atIndex: aIndex) as Bool?), false)
        XCTAssertEqual((row.value(atIndex: bIndex) as Bool?), true)
        XCTAssertEqual((row.value(atIndex: cIndex) as Bool?), true)
        
        // Expect fatal error:
        //
        // row.value(atIndex: -1)
        // row.value(atIndex: 3)
    }
    
    func testRowValueNamed() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        
        // Int extraction, form 1
        XCTAssertEqual(row.value(named: "a") as Int, 0)
        XCTAssertEqual(row.value(named: "b") as Int, 1)
        XCTAssertEqual(row.value(named: "c") as Int, 2)
        
        // Int extraction, form 2
        XCTAssertEqual(row.value(named: "a")! as Int, 0)
        XCTAssertEqual(row.value(named: "b")! as Int, 1)
        XCTAssertEqual(row.value(named: "c")! as Int, 2)
        
        // Int? extraction
        XCTAssertEqual((row.value(named: "a") as Int?)!, 0)
        XCTAssertEqual((row.value(named: "b") as Int?)!, 1)
        XCTAssertEqual((row.value(named: "c") as Int?)!, 2)
        
        // Bool extraction, form 1
        XCTAssertEqual(row.value(named: "a") as Bool, false)
        XCTAssertEqual(row.value(named: "b") as Bool, true)
        XCTAssertEqual(row.value(named: "c") as Bool, true)
        
        // Bool extraction, form 2
        XCTAssertEqual(row.value(named: "a")! as Bool, false)
        XCTAssertEqual(row.value(named: "b")! as Bool, true)
        XCTAssertEqual(row.value(named: "c")! as Bool, true)
        
        // Bool? extraction
        XCTAssertEqual((row.value(named: "a") as Bool?)!, false)
        XCTAssertEqual((row.value(named: "b") as Bool?)!, true)
        XCTAssertEqual((row.value(named: "c") as Bool?)!, true)
        
        // Expect fatal error:
        // row.value(named: "foo")
        // row.value(named: "foo") as Int?
    }
    
    func testRowDatabaseValueAtIndex() {
        assertNoError {
            let dictionary: [String: DatabaseValueConvertible?] = ["null": nil, "int64": 1, "double": 1.1, "string": "foo", "blob": "SQLite".data(using: .utf8)]
            let row = Row(dictionary)
            
            let nullIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "null")!)
            let int64Index = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "int64")!)
            let doubleIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "double")!)
            let stringIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "string")!)
            let blobIndex = dictionary.distance(from: dictionary.startIndex, to: dictionary.index(forKey: "blob")!)
            
            guard case .null = row.databaseValue(atIndex: nullIndex).storage else { XCTFail(); return }
            guard case .int64(let int64) = row.databaseValue(atIndex: int64Index).storage where int64 == 1 else { XCTFail(); return }
            guard case .double(let double) = row.databaseValue(atIndex: doubleIndex).storage where double == 1.1 else { XCTFail(); return }
            guard case .string(let string) = row.databaseValue(atIndex: stringIndex).storage where string == "foo" else { XCTFail(); return }
            guard case .blob(let data) = row.databaseValue(atIndex: blobIndex).storage where data == "SQLite".data(using: .utf8) else { XCTFail(); return }
        }
    }
    
    func testRowDatabaseValueNamed() {
        assertNoError {
            let dictionary: [String: DatabaseValueConvertible?] = ["null": nil, "int64": 1, "double": 1.1, "string": "foo", "blob": "SQLite".data(using: .utf8)]
            let row = Row(dictionary)

            guard case .null = row.databaseValue(named: "null")!.storage else { XCTFail(); return }
            guard case .int64(let int64) = row.databaseValue(named: "int64")!.storage where int64 == 1 else { XCTFail(); return }
            guard case .double(let double) = row.databaseValue(named: "double")!.storage where double == 1.1 else { XCTFail(); return }
            guard case .string(let string) = row.databaseValue(named: "string")!.storage where string == "foo" else { XCTFail(); return }
            guard case .blob(let data) = row.databaseValue(named: "blob")!.storage where data == "SQLite".data(using: .utf8) else { XCTFail(); return }
        }
    }
    
    func testRowCount() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        XCTAssertEqual(row.count, 3)
    }
    
    func testRowColumnNames() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        XCTAssertEqual(Array(row.columnNames).sorted(), ["a", "b", "c"])
    }
    
    func testRowDatabaseValues() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        XCTAssertEqual(row.databaseValues.sorted { ($0.value() as Int!) < ($1.value() as Int!) }, [0.databaseValue, 1.databaseValue, 2.databaseValue])
    }
    
    func testRowIsCaseInsensitive() {
        let row = Row(["name": "foo"])
        XCTAssertEqual(row.databaseValue(named: "name"), "foo".databaseValue)
        XCTAssertEqual(row.databaseValue(named: "NAME"), "foo".databaseValue)
        XCTAssertEqual(row.databaseValue(named: "NaMe"), "foo".databaseValue)
        XCTAssertEqual(row.value(named: "name") as String, "foo")
        XCTAssertEqual(row.value(named: "NAME") as String, "foo")
        XCTAssertEqual(row.value(named: "NaMe") as String, "foo")
    }
    
    func testMissingColumn() {
        let row = Row(["name": "foo"])
        XCTAssertFalse(row.hasColumn("missing"))
        XCTAssertTrue(row.databaseValue(named: "missing") == nil)
        XCTAssertTrue(row.value(named: "missing") == nil)
    }
    
    func testRowHasColumnIsCaseInsensitive() {
        let row = Row(["nAmE": "foo", "foo": 1])
        XCTAssertTrue(row.hasColumn("name"))
        XCTAssertTrue(row.hasColumn("NAME"))
        XCTAssertTrue(row.hasColumn("Name"))
        XCTAssertTrue(row.hasColumn("NaMe"))
        XCTAssertTrue(row.hasColumn("foo"))
        XCTAssertTrue(row.hasColumn("Foo"))
        XCTAssertTrue(row.hasColumn("FOO"))
    }
    
    func testSubRows() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        XCTAssertTrue(row.variant(named: "missing") == nil)
    }
    
    func testCopy() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        
        let copiedRow = row.copy()
        XCTAssertEqual(copiedRow.count, 3)
        XCTAssertEqual(copiedRow.value(named: "a") as Int, 0)
        XCTAssertEqual(copiedRow.value(named: "b") as Int, 1)
        XCTAssertEqual(copiedRow.value(named: "c") as Int, 2)
    }
    
    func testEqualityWithCopy() {
        let row = Row(["a": 0, "b": 1, "c": 2])
        
        let copiedRow = row.copy()
        XCTAssertEqual(row, copiedRow)
    }
}
