//
//  AppDelegate.swift
//  Dorm Quota Indicator
//
//  Created by Gamcheong Yuen on 23/6/2019.
//  Copyright © 2019 GreenYun Organization. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet
	var settingPanel: NSPanel!
	
	@IBOutlet
	var campusComboBox: NSComboBox!
	@IBOutlet
	var buildingComboBox: NSComboBox!
	@IBOutlet
	var roomTextField: NSTextField!
	
	var settingError: Int = 0
	var settingWindowController: NSWindowController?
	var settingWindowDelegate: SettingWindowDelegate?
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
	
	var campus: Int = -1
	var buildingIndex: Int = -1
	var room: Int = -1
	
	@IBAction
	func campusDidChanged(_ sender: NSComboBox) {
		if campus != sender.indexOfSelectedItem {
			campus = sender.indexOfSelectedItem
			buildingIndex = 0
		}
		var buildingList: [DormInfo.tupleBuilding]?
		switch campus {
		case 0:
			buildingList = DormInfo.campusNorthBuildings
		case 1:
			buildingList = DormInfo.campusSouthBuildings
		case 2:
			buildingList = DormInfo.campusXiliBuildings
		default:
			if settingError != 0 {
				return
			}
			else {
				settingError = 1
				let alert = NSAlert()
				alert.addButton(withTitle: "OK")
				alert.messageText = "Invalid Input."
				alert.alertStyle = .critical
				alert.beginSheetModal(for: settingPanel) { _ in
					self.campus = 0
					self.campusComboBox.selectItem(at: 0)
				}
			}
			buildingList = DormInfo.campusNorthBuildings
		}
		
		buildingComboBox.removeAllItems()
		if buildingList != nil {
			for item in buildingList! {
				buildingComboBox.addItem(withObjectValue: item.name)
			}
		}
		buildingComboBox.selectItem(at: buildingIndex)
	}
	
	@IBAction
	func buildingDidChanged(_ sender: NSComboBox) {
		if sender.indexOfSelectedItem >= 0 {
			buildingIndex = sender.indexOfSelectedItem
		}
		else {
			if settingError != 0 {
				return
			}
			else {
				settingError = 1
				let alert = NSAlert()
				alert.addButton(withTitle: "OK")
				alert.messageText = "Invalid Input."
				alert.alertStyle = .critical
			}
		}
	}
	
	@IBAction
	func roomDidChanged(_ sender: NSTextField) {
		if let room = Int(sender.stringValue) {
			self.room = room
		}
		else {
			if settingError != 0 {
				return
			}
			else {
				settingError = 1
				let alert = NSAlert()
				alert.addButton(withTitle: "OK")
				alert.messageText = "Invalid Input."
				alert.alertStyle = .critical
				alert.beginSheetModal(for: settingPanel) { _ in
					self.roomTextField.stringValue = ""
				}
			}
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		settingWindowController = NSWindowController(window: settingPanel)
		
		settingWindowDelegate = SettingWindowDelegate()
		settingWindowDelegate?.shouldCloseHandler = {
			self.settingError = 0
			
			self.buildingDidChanged(self.buildingComboBox)
			self.campusDidChanged(self.campusComboBox)
			self.roomDidChanged(self.roomTextField)
			
			if self.settingError != 0 {
				return false
			}
			return true
		}
		settingPanel.delegate = settingWindowDelegate
		
		NotificationCenter.default.addObserver(forName: NSPanel.willCloseNotification, object: settingPanel, queue: nil) { _ in
			self.saveUserDefault()
			self.setStatusButton("Loading...")
			self.refreshQuota()
		}
		
		setStatusButton("Loading...")
		
		let statusMenu = NSMenu()
		addDefaultMenuItems(menu: statusMenu)
		statusItem.menu = statusMenu
		
		campusComboBox.addItems(withObjectValues: ["North", "South", "Xili"])
		
		getUserDefault()
		if room != 0 {
			refreshQuota()
		}
		else {
			toShowSettingPanel()
		}
		
		let timer = Timer(timeInterval: 1800, target: self, selector: #selector(refreshQuota), userInfo: nil, repeats: true)
		timer.fire()
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func addDefaultMenuItems(menu: NSMenu) {
		menu.addItem(withTitle: "Refresh", action: #selector(refreshQuota), keyEquivalent: "R")
		menu.addItem(withTitle: "Set up", action: #selector(toShowSettingPanel), keyEquivalent: ",")
		menu.addItem(withTitle: "About", action: #selector(toShowAboutDialog), keyEquivalent: "")
		menu.addItem(NSMenuItem.separator())
		menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
	}
	
	@objc
	func refreshQuota() {
		var buildingList: [DormInfo.tupleBuilding]?
		switch campus {
		case 0:
			buildingList = DormInfo.campusNorthBuildings
		case 1:
			buildingList = DormInfo.campusSouthBuildings
		case 2:
			buildingList = DormInfo.campusXiliBuildings
		default:
			buildingList = nil
			return
		}
		let building = buildingList![self.buildingIndex].Id
		
		let query = QuotaQueryTask(dorm: DormInfo(campus: campus, building: building, room: room))
		query.finishCallBack = {
			let quotaData = query.quotaData
			let statusMenu = NSMenu()
			
			if let data = quotaData.last?.quota {
				self.setStatusButton("\(data) kW⋅h")
				statusMenu.addItem(NSMenuItem(title: "The quota in recent days of \(self.room):", action: nil, keyEquivalent: ""))
				for quota in quotaData {
					statusMenu.addItem(NSMenuItem(title: "\(quota.time)\t-\t\(quota.quota) kW⋅h", action: nil, keyEquivalent: ""))
				}
			}
			else {
				self.setStatusButton("No Data.")
			}
			
			self.addDefaultMenuItems(menu: statusMenu)
			self.statusItem.menu = statusMenu
		}
		query.startLoad()
	}
	
	@objc
	func toShowSettingPanel() {
		if campus >= 0 || campus < 3 {
			campusComboBox.selectItem(at: campus)
		}
		campusDidChanged(campusComboBox)
		if buildingIndex >= 0 {
			buildingComboBox.selectItem(at: buildingIndex)
		}
		roomTextField.stringValue = "\(room)"
		settingWindowController?.showWindow(nil)
	}
	
	func setStatusButton(_ text: String) {
		if let statusButton = statusItem.button {
			// statusButton.font = NSFont.systemFont(ofSize: 12)
			statusButton.title = text
			statusItem.length = statusButton.title.size(withAttributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 16.0)]).width
		}
	}
	
	func saveUserDefault() {
		UserDefaults.standard.set(campus, forKey: "Campus")
		UserDefaults.standard.set(buildingIndex, forKey: "Building")
		UserDefaults.standard.set(room, forKey: "Room")
	}
	
	func getUserDefault() {
		if let campus = UserDefaults.standard.value(forKey: "Campus") as? Int {
			self.campus = campus
		}
		if let buildingIndex = UserDefaults.standard.value(forKey: "Building") as? Int {
			self.buildingIndex = buildingIndex
		}
		if let room = UserDefaults.standard.value(forKey: "Room") as? Int {
			self.room = room
		}
	}
	
	@IBOutlet
	var aboutDialog: NSWindow!
	@IBOutlet
	var urlLabel: HyperlinkTextField!
	
	@IBAction
	func toShowAboutDialog(_ sender: NSMenuItem) {
		urlLabel.url = URL(fileURLWithPath: "https://github.com/GreenYun/Dorm-Quota-Indicator")
		urlLabel.resetCursorRects()
		let windowController = NSWindowController(window: aboutDialog)
		windowController.showWindow(nil)
	}
}
