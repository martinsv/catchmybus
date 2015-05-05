//
//  AppDelegate.swift
//  catchmybus
//
//  Created by Kilian Koeltzsch on 11/11/14.
//  Copyright (c) 2014 Kilian Koeltzsch. All rights reserved.
//

//  The term 'Bus' is used for both busses and trams in this app

import Cocoa
import IYLoginItem
import PFAboutWindow

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

	// Settings window
	@IBOutlet weak var settingsWindow: NSWindow!
	@IBOutlet weak var numRowsToShowLabel: NSTextField!
	@IBOutlet weak var numRowsToShowSlider: NSSlider!
	@IBOutlet weak var notificationsCheckbox: NSButton!

	// About window
	let aboutWindowController = PFAboutWindowController()

	// NSMenu
	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var manualRefreshButtonLabel: NSMenuItem!
	@IBOutlet weak var startAtLoginMenuItem: NSMenuItem!

	var stopLabels: [NSMenuItem] = []

	let cm = ConnectionManager()

	var numRowsToShow = 3	// how many rows are shown in the menu
	var numShownRows = 0	// tmp variable to store how many rows can be cleared on the next update

	var updateTime = 1		// how often in minutes the app calls update()

	var showNotifications = true	// if the app should show notifications or not

	var notificationTime = NSDate()
	var notificationBlockingStatusItem = false
	var notification = NSUserNotification()		// hold a reference to the notification so there's only ever one

	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// initialize default NSUserDefaults
		let defaultStopDict = ["Helmholtzstraße": 1, "Zellescher Weg": 5, "Heinrich-Zille-Straße": 8, "Technische Universität": 1]
		let defaultNotificationDict = ["Helmholtzstraße": 5, "Zellescher Weg": 15, "Heinrich-Zille-Straße": 15, "Technische Universität": 3]
		var defaults: Dictionary<NSObject, AnyObject> = ["numRowsToShow" : 5, "stopDict" : defaultStopDict, "notificationDict": defaultNotificationDict, "selectedStop": "Helmholtzstraße", "updateTime" : 1]
		NSUserDefaults.standardUserDefaults().registerDefaults(defaults)

		// load NSUserDefaults
		numRowsToShow = NSUserDefaults.standardUserDefaults().integerForKey("numRowsToShow")
		numRowsToShowLabel.integerValue = numRowsToShow
		numRowsToShowSlider.integerValue = numRowsToShow
		cm.stopDict = NSUserDefaults.standardUserDefaults().objectForKey("stopDict") as! Dictionary
		cm.notificationDict = NSUserDefaults.standardUserDefaults().objectForKey("notificationDict") as! Dictionary
		cm.selectedStop = NSUserDefaults.standardUserDefaults().objectForKey("selectedStop") as! String
		updateTime = NSUserDefaults.standardUserDefaults().integerForKey("updateTime")

		// setup icons and NSMenuItems
		setupUI()

		// Set state for startAtLoginMenuItem
		if NSBundle.mainBundle().isLoginItem() {
			startAtLoginMenuItem.state = NSOnState
		}

		// Update data and UI
		update()

		// Fill about window with info
		aboutWindowController.appName = "catchmybus"
		aboutWindowController.appURL = NSURL(string: "http://catchmybus.kilian.io")
		aboutWindowController.appCopyright = NSAttributedString(string: "Copyright (c) 2015 Kilian Koeltzsch")
		aboutWindowController.appEULA = NSAttributedString(string: "The MIT License (MIT)\n\nCopyright (c) 2015 Kilian Koeltzsch\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.")
		aboutWindowController.appCredits = NSAttributedString(string: "Thanks for help and tipps @h4llow3En")


		// initialize timer to automatically call update() how ever often updateTime states
		let timer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(updateTime * 60), target: self, selector: Selector("update"), userInfo: nil, repeats: true)

		// necessary for sending notifications when app is not active
		NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
	}

	func applicationWillTerminate(notification: NSNotification) {
		NSUserDefaults.standardUserDefaults().setInteger(numRowsToShow, forKey: "numRowsToShow")
		NSUserDefaults.standardUserDefaults().setObject(cm.stopDict, forKey: "stopDict")
		NSUserDefaults.standardUserDefaults().setObject(cm.notificationDict, forKey: "notificationDict")
		NSUserDefaults.standardUserDefaults().setObject(cm.selectedStop, forKey: "selectedStop")
		NSUserDefaults.standardUserDefaults().setInteger(updateTime, forKey: "updateTime")
	}

	// necessary for sending notifications when app is not active
	func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
		return true
	}

	func setupUI() {
		let icon = NSImage(named: "statusIcon")
		icon?.setTemplate(true)

		// Initialize stops
		for stop in cm.stopDict {
			let stopMenuItem = NSMenuItem(title: stop.0, action: Selector("selectStop:"), keyEquivalent: "")
			stopLabels.append(stopMenuItem)
			statusMenu.insertItem(stopMenuItem, atIndex: 1)
			if (stop.0 == cm.selectedStop) {
				stopMenuItem.state = NSOnState
			}
		}

		statusItem.image = icon
		statusItem.menu = statusMenu
	}

	func updateUI() {
		// clear connection rows in menu, fuck DRY
		for i in 0..<numShownRows {
			self.statusMenu.removeItemAtIndex(0)
		}

		numShownRows = 0

		// is there any status item to be done here? I think not... Let's see

		if let pretime = cm.stopDict[cm.selectedStop] {
			var i = 0
			for connection in cm.connections {
				// stop adding rows if enough are already displayed
				if (i == self.numRowsToShow) {
					break
				}
				let connectionMenuItem = ConnectionMenuItem(connection: connection, title: connection.toString(), action: Selector("connectionSelected:"), keyEquivalent: "")
				if connection.selected {
					connectionMenuItem.state = NSOnState
				}
				statusMenu.insertItem(connectionMenuItem, atIndex: i)
				numShownRows++
				i++
			}
		}
	}

	func update() {
		// clear connection rows in menu
		for i in 0..<numShownRows {
			self.statusMenu.removeItemAtIndex(0)
		}

		// pull new data and update UI in callback
		numShownRows = 0
		cm.update({
			if self.notificationBlockingStatusItem {
				// A connection is selected, so that is displayed in the menubar
				// updated twice on purpose to clear the necessary space
				self.statusItem.title = "\(self.cm.selectedConnection.arrivalMinutes)"
				self.statusItem.title = "\(self.cm.selectedConnection.arrivalMinutes)"
			} else {
				var firstBusArrivalMinutes = 0
				// no connection is selected, so the next connection is displayed in the menubar
				if let pretime = self.cm.stopDict[self.cm.selectedStop] {
					for connection in self.cm.connections {
						if (connection.arrivalMinutes >= pretime) {
							// get the first bus with an arrivaltime after the pretime
							firstBusArrivalMinutes = connection.arrivalMinutes
							break
						}
					}
					// update the statusMenu.title
					// updated twice on purpose to clear the necessary space
					self.statusItem.title = "\(firstBusArrivalMinutes)"
					self.statusItem.title = "\(firstBusArrivalMinutes)"
				}
			}

			// loop through connections to update NSMenuItems
			if let pretime = self.cm.stopDict[self.cm.selectedStop] {
				var i = 0
				for connection in self.cm.connections {
					if (connection.arrivalMinutes >= pretime) {
						// stop adding rows if enough are already displayed
						if (i == self.numRowsToShow) {
							break
						}
						let connectionMenuItem = ConnectionMenuItem(connection: connection, title: connection.toString(), action: Selector("connectionSelected:"), keyEquivalent: "")
						if connection.selected {
							connectionMenuItem.state = NSOnState
						}
						self.statusMenu.insertItem(connectionMenuItem, atIndex: i)
						self.numShownRows++
						i++
					}
				}
			}
		})

		// show new busses in the menubar after a notified connection is through
		let currentTime = NSDate()
		if (currentTime.laterDate(notificationTime.dateByAddingTimeInterval(NSTimeInterval(15 * 60))) == currentTime) {
			notificationBlockingStatusItem = false
		}
	}

	// Settings window
	@IBAction func numRowsToShowSliderChanged(sender: NSSlider) {
		numRowsToShowLabel.integerValue = sender.integerValue
		numRowsToShow = sender.integerValue
		updateUI()
	}

	@IBAction func notificationsCheckboxClicked(sender: NSButton) {
		if (sender.state == NSOnState) {
			showNotifications = true
		} else {
			showNotifications = false
		}
	}

	// NSMenu
	@IBAction func refreshClicked(sender: NSMenuItem) {
		update()
	}

	@IBAction func settingsButtonPressed(sender: NSMenuItem) {
		settingsWindow.makeKeyAndOrderFront(sender)
		NSApp.activateIgnoringOtherApps(true)
	}

	@IBAction func startAtLoginButtonPressed(sender: NSMenuItem) {
		if sender.state == NSOnState {
			NSBundle.mainBundle().removeFromLoginItems()
			sender.state = NSOffState
		} else {
			NSBundle.mainBundle().addToLoginItems()
			sender.state = NSOnState
		}
	}

	@IBAction func aboutButtonPressed(sender: NSMenuItem) {
//		aboutWindow.makeKeyAndOrderFront(sender)
		aboutWindowController.showWindow(nil)
		NSApp.activateIgnoringOtherApps(true)
	}

	@IBAction func clearNotificationButtonPressed(sender: NSMenuItem) {
		NSUserNotificationCenter.defaultUserNotificationCenter().removeScheduledNotification(notification)
		for c in cm.connections {
			c.selected = false
		}
		notificationBlockingStatusItem = false
		update()
	}
	
	@IBAction func selectStop(sender: NSMenuItem) {
		self.cm.selectedStop = sender.title
		for label in stopLabels {
			label.state = NSOffState
		}
		sender.state = NSOnState

		// clear a blocking statusitem if it's set
		notificationBlockingStatusItem = false

		cm.nuke()
		update()
	}

	@IBAction func quitButtonPressed(sender: NSMenuItem) {
		NSApplication.sharedApplication().terminate(self)
	}

	func connectionSelected(sender: ConnectionMenuItem) {
//		NSLog("Set a notification for \(sender.connection.toString())")
		notificationTime = NSDate(timeInterval: NSTimeInterval(-(cm.notificationDict[cm.selectedStop]!) * 60), sinceDate: sender.connection.arrivalDate)

		// clear a possible previous notification
		NSUserNotificationCenter.defaultUserNotificationCenter().removeScheduledNotification(notification)

		let currentDate = NSDate()
		if (showNotifications && notificationTime.laterDate(currentDate) == notificationTime) {
			// send a notification right now to tell the user when he's being notified again
			let tmpnotification = NSUserNotification()
			tmpnotification.title = "Ist notiert!"
			// NSDate.dateWithCalendarFormat is actually deprecated as of OS X 10.10
			// TODO: use .descriptionWithLocale instead
			let dateformat = "%H:%M"
			let timezone = NSTimeZone(abbreviation: "CEST")
			tmpnotification.informativeText = "Du bekommst um \(notificationTime.dateWithCalendarFormat(dateformat, timeZone: timezone)) Uhr eine Benachrichtigung. \(cm.notificationDict[cm.selectedStop]!) Minuten vor Abfahrt."
			NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(tmpnotification)

			// register notification to be sent at time of notification
			notification = NSUserNotification()
			if (sender.connection.line.toInt() > 20) {
				// it's a bus!
				notification.title = "Dein Bus kommt!"
				// TODO: Replace \(15) with the notification time set for a single stop. This obviously isn't happening yet^^
				notification.informativeText = "Deine Buslinie \(sender.connection.line) Richtung \(sender.connection.direction) hält in \(cm.notificationDict[cm.selectedStop]!) Minuten an der Haltestelle \(cm.selectedStop)."
			} else {
				// it's a tram!
				notification.title = "Deine Bahn kommt!"
				notification.informativeText = "Deine Bahnlinie \(sender.connection.line) Richtung \(sender.connection.direction) hält in \(cm.notificationDict[cm.selectedStop]!) Minuten an der Haltestelle \(cm.selectedStop)."
			}
			notification.deliveryDate = notificationTime
			NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification)
		}

		notificationBlockingStatusItem = true

		cm.selectConnection(sender.connection)
		sender.connection.selected = true

		// update UI for the new statusitem.title
		update()
	}
}

