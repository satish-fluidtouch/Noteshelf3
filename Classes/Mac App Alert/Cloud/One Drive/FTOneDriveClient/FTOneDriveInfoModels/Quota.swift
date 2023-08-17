/* 
Copyright (c) 2019 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Quota : Codable {
	let deleted : Int64?
	let remaining : Int64?
	let state : String?
    var total : Int64 = 0
    var used : Int64 = 0

	enum CodingKeys: String, CodingKey {

		case deleted = "deleted"
		case remaining = "remaining"
		case state = "state"
		case total = "total"
		case used = "used"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		deleted = try values.decodeIfPresent(Int64.self, forKey: .deleted)
		remaining = try values.decodeIfPresent(Int64.self, forKey: .remaining)
		state = try values.decodeIfPresent(String.self, forKey: .state)
        total = try values.decodeIfPresent(Int64.self, forKey: .total) ?? 0
        used = try values.decodeIfPresent(Int64.self, forKey: .used) ?? 0
	}

}
