// Copyright @ MyScript. All rights reserved.

//
// Refinements of the MyScript Interactive Ink Runtime API for Swift
//

extension IINKParameterSet {
    func boolean(for key: String) throws -> Bool {
        let v = try boolean(forKey: key)
        return v.value;
    }
    func number(for key: String) throws -> Double {
        let v = try number(forKey: key)
        return v.value;
    }
}
