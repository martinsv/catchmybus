//
//  Connection.swift
//  catchmybus
//
//  Created by Kilian Koeltzsch on 14/11/14.
//  Copyright (c) 2014 Kilian Koeltzsch. All rights reserved.
//

import Foundation

struct Connection {

	let line: String
	let direction: String
	let arrivalMinutes: Int
	let arrivalTime: NSDate

	init (line: String, direction: String, arrivalMinutes: Int) {
		self.line = line
		self.direction = direction
		self.arrivalMinutes = arrivalMinutes
		self.arrivalTime = NSDate() // we'll do this later
	}

	func toString() -> String {
		return "\(line) \(direction): \(arrivalMinutes) Minuten"
	}

}