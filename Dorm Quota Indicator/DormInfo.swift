//
//  BuildingInfo.swift
//  Dorm Quota Indicator
//
//  Created by Gamcheong Yuen on 23/6/2019.
//  Copyright © 2019 GreenYun Organization. All rights reserved.
//

import Foundation

class DormInfo {
    var error: Int = 0 {
        didSet {
            if self.error != 0 {
                errorHandler(self.error)
            }
        }
    }
    
    var errorHandler: (_ error: Int) -> Void = { error in return }
    
    typealias tupleBuilding = (Id: Int, name: String)
    
    static let campusNorthBuildings: [tupleBuilding] = [
        (6121, "乔林阁1-10层"),
        (6363, "乔林阁11-12层"),
        (6122, "乔木阁1-10层"),
        (6364, "乔木阁11-12层"),
        (7724, "乔梧阁2-10层"),
        (7725, "乔梧阁11-20"),
        (6875, "乔森阁2-10层"),
        (6876, "乔森阁11-20层"),
        (6877, "乔相阁2-10层"),
        (6878, "乔相阁11-20层"),
        (47,   "聚翰斋"),
        (49,   "紫薇斋1-5层"),
        (754,  "紫薇斋6-8层"),
        (50,   "木棉斋"),
        (51,   "拒霜斋"),
        (5377, "雨鹃斋2-8楼"),
        (5374, "雨鹃斋9-11楼"),
        (5375, "风槐斋2-8楼"),
        (5376, "风槐斋9-15楼"),
        (54,   "山茶斋"),
        (55,   "红榴斋"),
        (56,   "米兰斋"),
        (57,   "海桐斋"),
        (58,   "桃李斋"),
        (59,   "凌霄斋"),
        (60,   "蓬莱斋"),
        (61,   "银桦斋"),
        (62,   "红豆斋"),
        (63,   "木犀轩"),
        (64,   "丹枫轩"),
        (65,   "紫檀轩"),
        (66,   "石楠轩"),
        (67,   "苏铁轩"),
        (68,   "芸香阁"),
        (69,   "丁香阁"),
        (70,   "文杏阁"),
        (71,   "海棠阁"),
        (72,   "疏影阁"),
        (73,   "杜衡阁"),
        (74,   "辛夷阁"),
        (75,   "韵竹阁"),
        (76,   "云杉轩"),
        (77,   "紫藤轩"),
    ]
    
    static let campusSouthBuildings: [tupleBuilding] = [
        (6875, "一栋春笛3-8楼"),
        (6876, "二栋夏筝3-17楼"),
        (6877, "三栋秋瑟3-8楼"),
        (6878, "四栋冬筑3-6楼"),
        (7119, "一栋春笛9-17楼"),
        (7828, "三栋秋瑟9-17楼"),
        (8240, "四栋冬筑7-10楼"),
        (8241, "四栋冬筑11-14楼"),
        (8242, "四栋冬筑15-17楼"),
    ]
    
    static let campusXiliBuildings: [tupleBuilding] = [
        (10057, "A栋风信子"),
        (10934, "B栋山楂树"),
        (10935, "C栋胡杨林"),
    ]
    
    var campus: Int
    var buildingId: Int
    var room: Int
    
    var campusServer: String? {
        get {
            switch self.campus {
            case 0:
                return "192.168.84.1"
            case 1:
                return "192.168.84.110"
            case 2:
                return "172.21.101.11"
            default:
                return nil
            }
        }
    }
    
    init(campus: Int, building: Int, room: Int) {
        self.campus = campus
        self.buildingId = building
        self.room = room
    }
}
