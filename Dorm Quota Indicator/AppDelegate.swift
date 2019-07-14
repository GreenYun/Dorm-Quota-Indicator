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
	var campusPopUpButton: NSPopUpButton!
	@IBOutlet
	var buildingPopUpButton: NSPopUpButton!
	@IBOutlet
	var roomTextField: NSTextField!
	
	var settingError: Int = 0
	var settingWindowController: NSWindowController?
	var settingWindowDelegate: SettingWindowDelegate?
	
	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	
	var campus: Int = 0
	var buildingIndex: Int = 0
	var room: Int = 0
	
	@IBAction
	func campusSelected(_ sender: NSMenuItem) {
		var buildingList: [DormInfo.tupleBuilding]?
		
		campus = sender.tag
		
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
				}
			}
			buildingList = DormInfo.campusNorthBuildings
		}
		
		buildingPopUpButton.menu?.removeAllItems()
		if buildingList != nil {
			var tag: Int = 0
			for item in buildingList! {
				let menuItem = NSMenuItem(title: item.name, action: #selector(buildingSelected(_:)), keyEquivalent: "")
				menuItem.tag = tag
				buildingPopUpButton.menu?.addItem(menuItem)
				if tag == buildingIndex {
					menuItem.state = .on
					buildingPopUpButton.selectItem(at: tag)
				}
				else {
					menuItem.state = .off
				}
				tag += 1
			}
		}
	}
	
	@IBAction
	func buildingSelected(_ sender: NSMenuItem) {
		if sender.tag >= 0 {
			buildingIndex = sender.tag
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
			
			self.roomDidChanged(self.roomTextField)
			
			if self.settingError != 0 {
				return false
			}
			return true
		}
		settingPanel.delegate = settingWindowDelegate
		
		NotificationCenter.default.addObserver(forName: NSPanel.willCloseNotification, object: settingPanel, queue: nil) { _ in
			self.saveUserDefaults()
			self.setStatusButton("Loading...")
			self.refreshQuota()
		}
		
		setStatusButton("Loading...")
		
		let statusMenu = NSMenu()
		addDefaultMenuItems(menu: statusMenu)
		statusItem.menu = statusMenu
		
		getUserDefaults()
		
		campusPopUpButton.selectItem(at: self.campus)
		self.campusSelected((self.campusPopUpButton.menu?.item(at: self.campus))!)
		self.buildingSelected((self.buildingPopUpButton.menu?.item(at: self.buildingIndex))!)
		if room != 0 {
			refreshQuota()
		}
		else {
			toShowSettingPanel()
		}
		
		let timer = Timer(timeInterval: 1800, target: self, selector: #selector(refreshQuota), userInfo: nil, repeats: true)
		timer.fire()
	}
	
	//func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	//}
	
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
	
	func setStatusButton(_ text: String) {
		if let statusButton = statusItem.button {
			statusButton.title = text
		}
	}
	
	func addDefaultMenuItems(menu: NSMenu) {
		menu.addItem(withTitle: "Refresh", action: #selector(refreshQuota), keyEquivalent: "R")
		menu.addItem(withTitle: "Set up", action: #selector(toShowSettingPanel), keyEquivalent: ",")
		menu.addItem(withTitle: "About", action: #selector(toShowAboutDialog), keyEquivalent: "")
		menu.addItem(NSMenuItem.separator())
		menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
	}
	
	func saveUserDefaults() {
		UserDefaults.standard.set(campus, forKey: "Campus")
		UserDefaults.standard.set(buildingIndex, forKey: "Building")
		UserDefaults.standard.set(room, forKey: "Room")
	}
	
	func getUserDefaults() {
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
	var settingPanel: NSPanel!
	
	@objc
	func toShowSettingPanel() {
		roomTextField.stringValue = "\(room)"
		settingWindowController?.showWindow(nil)
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
