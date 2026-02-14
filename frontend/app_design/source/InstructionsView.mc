import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Time;

class InstructionsView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }
    
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 40, Graphics.FONT_SMALL, "Instructions", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var y = 80;
        var lineHeight = 25;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "Rate each symptom", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "based on its impact", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "for today", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight + 10;
        
        // Rating scale
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "0 = No symptoms", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "1 = Mild Impact", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "2 = Moderate Impact", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "3 = Marked Impact", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        dc.drawText(cx, y, Graphics.FONT_XTINY, 
                    "4 = Disabling", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        
        // Start button
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 60, height - 70, 120, 45, 8);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height - 47, Graphics.FONT_SMALL, "BEGIN", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class InstructionsDelegate extends WatchUi.BehaviorDelegate {
    private var checkedSymptoms as Array<String>;
    
    function initialize(symptoms as Array<String>) {
        BehaviorDelegate.initialize();
        checkedSymptoms = symptoms;
    }
    
    function onSelect() as Boolean {
        startQuestionnaire();
        return true;
    }
    
    function onTap(clickEvent as ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        var height = System.getDeviceSettings().screenHeight;
        
        // Check if START button was tapped
        if (x >= 90 && x <= 270 && y >= height - 70 && y <= height - 25) {
            startQuestionnaire();
            return true;
        }
        
        return false;
    }
    
    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            startQuestionnaire();
            return true;
        }
        return false;
    }
    
    private function startQuestionnaire() as Void {
        var questionView = new questionPageView(checkedSymptoms);
        WatchUi.switchToView(questionView, new QuestionPageDelegate(questionView), WatchUi.SLIDE_LEFT);
    }
    
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}