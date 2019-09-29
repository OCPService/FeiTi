//
//  NSBundleExtension.swift
//  FeiTiVPN
//
//  Created by dl_support on 6/7/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

extension Bundle {
    class var applicationVersionNumber: String? {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return nil
    }
    
    class var applicationBuildNumber: String? {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return nil
    }
}

extension String {
    func local() -> String {
        return NSLocalizedString(self, comment: self)
    }
}
