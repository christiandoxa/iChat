//
// Created by Christian Doxa Hamasiah on 2019-07-24.
// Copyright (c) 2019 Christian Doxa Hamasiah. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

//MARK: GLOBAL FUNCTIONS
private let dateFormat = "yyyyMMddHHmmss"

func dateFormatter() -> DateFormatter {

    let dateFormatter = DateFormatter()

    dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())

    dateFormatter.dateFormat = dateFormat

    return dateFormatter
}
