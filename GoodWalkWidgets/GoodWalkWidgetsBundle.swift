import SwiftUI
import WidgetKit

@main
struct GoodWalkWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWalkWidget()
        WalkLiveActivity()
    }
}
