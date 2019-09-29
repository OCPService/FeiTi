//
//  FeiTiAPIError.swift
//  FeiTiVPN
//
//  Created by FeiTi on 17/01/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import Foundation

enum FeiTiAPIError: Int, Error {
    case HTTP_COMMON_UNKNOWN = 800  // http unknown
    case HTTP_COMMON_INVALID_PARAMS = 1000  // invalid parameters
    case HTTP_COMMON_INVALID_JSON_RESPONSE = 1001  // invalid JSON response
    case HTTP_COMMON_INVALID_TOKEN = 1002  // invalid Token
    case HTTP_COMMON_TOKEN_TIMEOUT = 1003  // token timeout
    case HTTP_USER_SIGN_UP_FAILURE = 1500  // fail to sign up
    case HTTP_USER_SIGN_IN_FAILURE = 1501  // fail to sign in
    case HTTP_USER_UPDATE_PASSWORD_FAILURE = 1502  // fail to update password
    case HTTP_USER_FREE_REFRESH_FAILURE = 1503  // fail to refresh free usage
    case HTTP_USER_PURCHASE_FAILURE = 1504  // fail to purchase
    case HTTP_USER_POINTS_TO_VIP_FAILURE = 1505 //fail to points to vip
    case HTTP_AD_LOG_PRESENT_FAILURE = 2000  // fail to log ad present
    case HTTP_AD_LOG_CLICK_FAILURE = 2001  // fail to log ad click
    
    case LOCAL_COMMON_UNKNOWN = 2800 // local unknown
    case LOCAL_SAVE_FILE_FAILURE = 2810 // local file save
    case LOCAL_NETWORK_OFFLINE = 3000 // local wifi / wwan offline
    case LOCAL_TOKEN_INVALID = 3200 // local token is nil
    case LOCAL_USER_INVALID = 3201 // local user is nil
}
