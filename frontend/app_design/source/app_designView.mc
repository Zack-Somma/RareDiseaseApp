import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class app_designView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }
    
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }
    
    function onShow() as Void {
    }
    
    function onUpdate(dc) {
        // --- 1. Get current time ---
        var clockTime = System.getClockTime();
        
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
        var userName = "Claire!";
        var greetingText = Lang.format("$1$, $2$", [greeting, userName]);
        var timeText = Lang.format(
            "$1$:$2$",
            [clockTime.hour, clockTime.min.format("%02d")]
        );
        var questionText = "Ready to track?";
        
        var greetingView = View.findDrawableById("GreetingLabel") as Text;
        if (greetingView != null) {
            greetingView.setText(greetingText);
        }
        
        var timeView = View.findDrawableById("TimeLabel") as Text;
        if (timeView != null) {
            timeView.setText(timeText);
        }
        
        var questionView = View.findDrawableById("QuestionLabel") as Text;
        if (questionView != null) {
            questionView.setText(questionText);
        }
        
        var yesView = View.findDrawableById("YesLabel") as Text;
        if (yesView != null) {
            yesView.setText("YES");
        }
        
        var skipView = View.findDrawableById("SkipLabel") as Text;
        if (skipView != null) {
            skipView.setText("SKIP");
        }
        
        View.onUpdate(dc);
    }
    
    function getYesBounds(dc as Dc) as Array<Number> {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Calculate center position
        var centerX = (screenWidth * 25) / 100;
        var centerY = (screenHeight * 75) / 100;
        
        var dimensions = dc.getTextDimensions("YES", Graphics.FONT_MEDIUM);
        var width = dimensions[0];
        var height = dimensions[1];
        
        var padding = 30;
        
        // Return [x, y, width, height] - top-left corner based
        return [
            centerX - width/2 - padding,
            centerY - height/2 - padding,
            width + 2 * padding,
            height + 2 * padding
        ];
    }
    
    function getSkipBounds(dc as Dc) as Array<Number> {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Calculate center position
        var centerX = (screenWidth * 75) / 100;
        var centerY = (screenHeight * 75) / 100;
        
        var dimensions = dc.getTextDimensions("SKIP", Graphics.FONT_MEDIUM);
        var width = dimensions[0];
        var height = dimensions[1];
        
        var padding = 30;
        
        // Return [x, y, width, height] - top-left corner based
        return [
            centerX - width/2 - padding,
            centerY - height/2 - padding,
            width + 2 * padding,
            height + 2 * padding
        ];
    }
    
    function onHide() as Void {
    }
}