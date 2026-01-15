import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class app_designView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc) {
    // --- 1. Get current time ---
    var clockTime = System.getClockTime(); // hour, min, sec

    // --- 2. Determine greeting based on hour ---
    var greeting;
    if (clockTime.hour < 12) {
        greeting = "Good morning";
    } else if (clockTime.hour < 18) {
        greeting = "Good afternoon";
    } else {
        greeting = "Good evening";
    }

    // --- 3. User name ---
    var userName = "Claire";

    // --- 4. Format time ---
    var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);

    // --- 5. Combine greeting, name, and time ---
    var displayText = Lang.format("$1$, $2$ - $3$", [greeting, userName, timeString]);

    // --- 6. Update text field ---
    var view = View.findDrawableById("TimeLabel") as Text;
    if (view != null) {
        view.setText(displayText);
    }

    // --- 7. Call parent to redraw layout ---
    View.onUpdate(dc);
}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
