//
//  RunDJWidgetBundle.swift
//  RunDJWidget
//
//  Created by Richard Cong on 6/8/25.
//

import WidgetKit
import SwiftUI

@main
struct RunDJWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Include the Live Activity widget
        RunDJLiveActivityWidget()
        
        // Include the home screen widget
        RunDJWidget()
    }
}

