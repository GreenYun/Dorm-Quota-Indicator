//
//  QuotaQueryTask.swift
//  Dorm Quota Indicator
//
//  Created by Gamcheong Yuen on 23/6/2019.
//  Copyright © 2019 GreenYun Organization. All rights reserved.
//

import Foundation

class QuotaQueryTask: NSObject {
	var error: Int = 0 {
		didSet {
			if self.error != 0 {
				self.errorHandler(self.error)
			}
		}
	}
	
	var errorHandler: (_ error: Int) -> Void = { _ in }
	
	var dormInfo: DormInfo
	
	init(dorm: DormInfo) {
		self.dormInfo = dorm
	}
	
	func startLoad() {
		let url: URL = URL(string: "http://192.168.84.3:9090/cgcSims/login.do?client=\(self.dormInfo.campusServer ?? "")&buildingName=&buildingId=\(self.dormInfo.buildingId)&roomName=\(self.dormInfo.room)")!
		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			if error != nil {
				self.error = 1
				return
			}
			
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) else {
				self.error = 1
				return
			}
			
			if let data = data,
				let string = String(data: data, encoding: .ascii) {
				DispatchQueue.main.async {
					self.parseForRoomId(page: string)
					self.startLoadQuota()
				}
			}
		}
		
		task.resume()
	}
	
	var roomId: Int = 0
	
	private func parseForRoomId(page: String) {
		let data = Data(page.utf8)
		if let doc = TFHpple(htmlData: data) {
			if let elements = doc.search(withXPathQuery: "//input[@name='roomId']") as? [TFHppleElement] {
				for element in elements {
					if let roomIdString = element.object(forKey: "value") {
						self.roomId = Int(roomIdString)!
					}
				}
			}
		}
	}
	
	func startLoadQuota() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		
		let dateBeginFormatted = dateFormatter.string(from: Date(timeIntervalSinceNow: -604800))
		let dateEndFormatted = dateFormatter.string(from: Date())
		
		let url: URL = URL(string: "http://192.168.84.3:9090/cgcSims/selectList.do?hiddenType=&isHost=&beginTime=\(dateBeginFormatted)&endTime=\(dateEndFormatted)&type=2&client=\(self.dormInfo.campusServer ?? "")&roomId=\(self.roomId)&roomName=\(self.dormInfo.room)&building=")!
		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			if error != nil {
				self.error = 1
				return
			}
			
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) else {
				return
			}
			
			if let data = data,
				let string = String(data: data, encoding: .ascii) {
				DispatchQueue.main.async {
					self.parseForQuota(page: string)
				}
			}
		}
		
		task.resume()
	}
	
	var quotaData = [(time: String, quota: Double)]()
	
	private func parseForQuota(page: String) {
		let data = Data(page.utf8)
		if let doc = TFHpple(htmlData: data) {
			if let elements = doc.search(withXPathQuery: "//table[@id='oTable']") as? [TFHppleElement] {
				for element in elements {
					let rows = element.search(withXPathQuery: "//tr") as? [TFHppleElement]
					if let countRows = rows?.count, countRows >= 9 {
						for row in rows![1...countRows - 3] {
							let columns = row.search(withXPathQuery: "//td") as? [TFHppleElement]
							if let countColumns = columns?.count, countColumns > 0 {
								let quotaString = columns![2].text()!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
								let dateString = columns![5].text()!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
								let quota = Double(quotaString)!
								self.quotaData.append((dateString, quota))
							}
						}
					}
					else {
						self.error = 1
						self.finishCallBack()
						return
					}
				}
			}
		}
		
		self.finishCallBack()
	}
	
	var finishCallBack: () -> Void = {}
}
