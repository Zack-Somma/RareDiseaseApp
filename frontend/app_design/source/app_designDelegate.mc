import Toybox.WatchUi;
import Toybox.Lang;

class app_designDelegate extends WatchUi.BehaviorDelegate {
    
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Bottom half of screen (y > 180)
        if (y > 180) {
            // Left side - YES
            if (x < 180) {
                WatchUi.pushView(new YesPageView(), new YesPageDelegate(), WatchUi.SLIDE_UP);
                return true;
            }
            // Right side - SKIP
            else {
                WatchUi.pushView(new DashboardView(), new DashboardDelegate(), WatchUi.SLIDE_DOWN);
                return true;
            }
        }
        
        return false;
    }
}