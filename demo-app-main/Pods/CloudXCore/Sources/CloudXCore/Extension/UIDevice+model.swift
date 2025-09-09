//
//  UIDevice+model.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Foundation
import UIKit

extension UIDevice {
  static let deviceIdentifier: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    return machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }()

  static let (deviceType, deviceGeneration, ppi): (String, String, Int) = {
    return mapToDevice(identifier: deviceIdentifier)
  }()

  /// return value (device, model, ppi) ("iPhone", "12 Pro", 460)
  static func mapToDevice(identifier: String) -> (String, String, Int) {  // swiftlint:disable:this cyclomatic_complexity
    #if os(iOS)
      switch identifier {
      case "iPod5,1": return ("iPod touch", "5th generation", 326)
      case "iPod7,1": return ("iPod touch", "6th generation", 326)
      case "iPod9,1": return ("iPod touch", "7th generation", 326)
      case "iPhone3,1",
        "iPhone3,2",
        "iPhone3,3":
        return ("iPhone", "4", 326)
      case "iPhone4,1": return ("iPhone", "4s", 326)
      case "iPhone5,1",
        "iPhone5,2":
        return ("iPhone", "5", 326)
      case "iPhone5,3",
        "iPhone5,4":
        return ("iPhone", "5c", 326)
      case "iPhone6,1",
        "iPhone6,2":
        return ("iPhone", "5s", 326)
      case "iPhone7,2": return ("iPhone", "6", 326)
      case "iPhone7,1": return ("iPhone", "6 Plus", 401)
      case "iPhone8,1": return ("iPhone", "6s", 326)
      case "iPhone8,2": return ("iPhone", "6s Plus", 401)
      case "iPhone8,4": return ("iPhone", "SE", 326)
      case "iPhone9,1",
        "iPhone9,3":
        return ("iPhone", "7", 326)
      case "iPhone9,2",
        "iPhone9,4":
        return ("iPhone", "7 Plus", 401)
      case "iPhone10,1",
        "iPhone10,4":
        return ("iPhone", "8", 326)
      case "iPhone10,2",
        "iPhone10,5":
        return ("iPhone", "8 Plus", 401)
      case "iPhone10,3",
        "iPhone10,6":
        return ("iPhone", "X", 458)
      case "iPhone11,2": return ("iPhone", "XS", 458)
      case "iPhone11,4",
        "iPhone11,6":
        return ("iPhone", "XS Max", 458)
      case "iPhone11,8": return ("iPhone", "XR", 326)
      case "iPhone12,1": return ("iPhone", "11", 326)
      case "iPhone12,3": return ("iPhone", "11 Pro", 458)
      case "iPhone12,5": return ("iPhone", "11 Pro Max", 458)
      case "iPhone12,8": return ("iPhone", "SE (2nd generation)", 326)
      case "iPhone13,1": return ("iPhone", "12 mini", 476)
      case "iPhone13,2": return ("iPhone", "12", 460)
      case "iPhone13,3": return ("iPhone", "12 Pro", 460)
      case "iPhone13,4": return ("iPhone", "12 Pro Max", 458)
      case "iPhone14,2": return ("iPhone", "13 Pro", 460)
      case "iPhone14,3": return ("iPhone", "13 Pro Max", 458)
      case "iPhone14,4": return ("iPhone", "13 mini", 476)
      case "iPhone14,5": return ("iPhone", "13", 460)
      case "iPhone14,6": return ("iPhone", "SE (3rd generation)", 326)
      case "iPhone14,7": return ("iPhone", "14", 460)
      case "iPhone14,8": return ("iPhone", "14 Plus", 458)
      case "iPhone15,2": return ("iPhone", "14 Pro", 460)
      case "iPhone15,3": return ("iPhone", "14 Pro Max", 460)
      case "iPhone15,4": return ("iPhone", "15", 460)
      case "iPhone15,5": return ("iPhone", "15 Plus", 460)
      case "iPhone16,1": return ("iPhone", "15 Pro", 460)
      case "iPhone16,2": return ("iPhone", "15 Pro Max", 460)
      case "iPad2,1",
        "iPad2,2",
        "iPad2,3",
        "iPad2,4":
        return ("iPad", "2", 132)
      case "iPad3,1",
        "iPad3,2",
        "iPad3,3":
        return ("iPad", "3rd generation", 264)
      case "iPad3,4",
        "iPad3,5", "iPad3,6":
        return ("iPad", "4th generation", 264)
      case "iPad6,11",
        "iPad6,12":
        return ("iPad", "5th generation", 264)
      case "iPad7,5",
        "iPad7,6":
        return ("iPad", "6th generation", 264)
      case "iPad7,11",
        "iPad7,12":
        return ("iPad", "7th generation", 264)
      case "iPad11,6",
        "iPad11,7":
        return ("iPad", "8th generation", 264)
      case "iPad4,1",
        "iPad4,2", "iPad4,3":
        return ("iPad", "Air", 264)
      case "iPad5,3",
        "iPad5,4":
        return ("iPad", "Air 2", 326)
      case "iPad11,3",
        "iPad11,4":
        return ("iPad", "Air (3rd generation)", 264)
      case "iPad13,1",
        "iPad13,2":
        return ("iPad", "Air (4th generation)", 264)
      case "iPad2,5",
        "iPad2,6", "iPad2,7":
        return ("iPad", "mini", 163)
      case "iPad4,4",
        "iPad4,5", "iPad4,6":
        return ("iPad", "mini 2", 326)
      case "iPad4,7",
        "iPad4,8", "iPad4,9":
        return ("iPad", "mini 3", 264)
      case "iPad5,1",
        "iPad5,2":
        return ("iPad", "mini 4", 326)
      case "iPad11,1",
        "iPad11,2":
        return ("iPad", "mini (5th generation)", 326)
      case "iPad14,1",
        "iPad14,2":
        return ("iPad", "mini (6th generation)", 326)
      case "iPad6,3",
        "iPad6,4":
        return ("iPad", "Pro (9.7-inch)", 264)
      case "iPad7,3",
        "iPad7,4":
        return ("iPad", "Pro (10.5-inch)", 264)
      case "iPad8,1",
        "iPad8,2",
        "iPad8,3",
        "iPad8,4":
        return ("iPad", "Pro (11-inch) (1st generation)", 264)
      case "iPad8,9",
        "iPad8,10":
        return ("iPad", "Pro (11-inch) (2nd generation)", 264)
      case "iPad6,7",
        "iPad6,8":
        return ("iPad", "Pro (12.9-inch) (1st generation)", 264)
      case "iPad7,1",
        "iPad7,2":
        return ("iPad", "Pro (12.9-inch) (2nd generation)", 264)
      case "iPad8,5",
        "iPad8,6",
        "iPad8,7",
        "iPad8,8":
        return ("iPad", "Pro (12.9-inch) (3rd generation)", 264)
      case "iPad8,11",
        "iPad8,12":
        return ("iPad", "Pro (12.9-inch) (4th generation)", 264)
      case "iPad13,4",
        "iPad13,5",
        "iPad13,6",
        "iPad13,7":
        return ("iPad Pro", "(11-inch) (3rd generation)", 264)
      case "iPad13,8",
        "iPad13,9",
        "iPad13,10",
        "iPad13,11":
        return ("iPad Pro", "(12.9-inch) (5th generation)", 264)
      case "AudioAccessory1,1": return ("HomePod", "", 0)
      case "AudioAccessory5,1": return ("HomePod", "mini", 0)
      case "i386", "x86_64":
        return ("Simulator", "\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS").1)", 264)
      default: return ("\(identifier)", "", 0)
      }
    #elseif os(tvOS)
      switch identifier {
      case "AppleTV1,1": return ("Apple TV", "1st generation", 0)
      case "AppleTV2,1": return ("Apple TV", "2nd generation", 0)
      case "AppleTV3,1", "AppleTV3,2": return ("Apple TV", "3rd generation", 0)
      case "AppleTV5,3": return ("Apple TV", "4th generation", 0)
      case "AppleTV6,2": return ("Apple TV", "4K", 0)
      case "AppleTV11,1": return ("Apple TV", "4K (2nd generation", 0)
      case "i386", "x86_64":
        return ("Simulator", "\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS").1)", 0)
      default: return ("\(identifier)", "", 0)
      }
    #endif
  }
}

