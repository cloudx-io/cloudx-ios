//
//  LineItemConditionService.swift
//  CloudXCore
//
//  Created by Xenoss on 25.04.2025.
//

import Foundation

class LineItemConditionService {
    
    enum ListKeys: String {
        case loopIndex = "loop-index"
        case age = "age"
        case age_group = "age_group"
        case gender = "gender"
        case marital_status = "marital_status"
    }
    
    static func checkPlacementConditions(_ placement: SDKConfig.Response.Placement, placementIndex: Int) -> String {
        var finalString = placement.id
        
        placement.line_items?.forEach { lineItem in
            let checkString = checkConditionsAnd(placementIndex: placementIndex, placementId: placement.id, lineItem: lineItem)
            if checkString != placement.id {
                finalString = checkString
            }
        }
        
        return finalString
    }
    
    private static func checkConditionsAnd(placementIndex: Int, placementId: String, lineItem: SDKConfig.Response.Placement.LineItem) -> String {
        var isConditionsValid: Bool = false
        
        guard let targeting = lineItem.targeting?.value() as? SDKConfig.Response.Placement.LineItem.Targeting, let suffix = lineItem.suffix else { return placementId }
        
        let bothListsConditionsInclude = targeting.conditionsAnd
        
        var isWhitelistConditionValid: Bool = false
        var isBlacklistConditionValid: Bool = false
        
        targeting.conditions.forEach { condition in
            let isAllListConditionsShouldBeValid = condition.and
            
            if let whitelist = condition.whitelist {
                let whitelistConditionResults = conditionResults(dicts: whitelist, placementIndex: placementIndex)
                isWhitelistConditionValid = isAllListConditionsShouldBeValid ? whitelistConditionResults.isAllMatch : whitelistConditionResults.atLeastOneMatch
            }
            
            if let blacklist = condition.blacklist, !blacklist.isEmpty {
                let blacklistConditionResults = conditionResults(dicts: blacklist, placementIndex: placementIndex)
                isBlacklistConditionValid = isAllListConditionsShouldBeValid ? blacklistConditionResults.isAllMatch : blacklistConditionResults.atLeastOneMatch
            } else {
                isBlacklistConditionValid = true
            }
        }
        
        isConditionsValid = bothListsConditionsInclude ? isWhitelistConditionValid && isBlacklistConditionValid : isWhitelistConditionValid || isBlacklistConditionValid
        
        let finalString = isConditionsValid ? placementId + suffix : placementId
        
        return finalString
    }
    
    static func conditionResults(dicts: [[String: SDKConfig.Response.Placement.LineItem.Targeting.Condition.QuantumValue]?], placementIndex: Int) -> (isAllMatch: Bool, atLeastOneMatch: Bool) {
        var isAllMatch: Bool = false
        var atLeastOneMatch: Bool = false
        for dict in dicts {
            guard let dict = dict, let userDict = UserDefaults.standard.dictionary(forKey: "userKeyValue") as? [String: String] else { continue }
            for key in dict.keys {
                let keys = ListKeys(rawValue: key)
                switch keys {
                case .loopIndex:
                    let value = dict[key]?.value() as? Int ?? 0
                    isAllMatch = value == placementIndex
                    atLeastOneMatch = atLeastOneMatch == true ? atLeastOneMatch : value == placementIndex
                case .age:
                    let value = dict[key]?.value() as? String
                    isAllMatch = value == userDict[key]
                    atLeastOneMatch = atLeastOneMatch == true ? atLeastOneMatch : value == userDict[key]
                case .age_group:
                    let value = dict[key]?.value() as? String
                    isAllMatch = value == userDict[key]
                    atLeastOneMatch = atLeastOneMatch == true ? atLeastOneMatch : value == userDict[key]
                case .gender:
                    let value = dict[key]?.value() as? String
                    isAllMatch = value == userDict[key]
                    atLeastOneMatch = atLeastOneMatch == true ? atLeastOneMatch : value == userDict[key]
                case .marital_status:
                    let value = dict[key]?.value() as? String
                    isAllMatch = value == userDict[key]
                    atLeastOneMatch = atLeastOneMatch == true ? atLeastOneMatch : value == userDict[key]
                default:
                    break
                }
            }
        }
        return (isAllMatch, atLeastOneMatch)
    }
}
