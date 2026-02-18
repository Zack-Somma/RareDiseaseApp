
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class YesPageView extends WatchUi.View {
    
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Move text up to better use space
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            screenHeight / 2.8,
            Graphics.FONT_SMALL,
            "Are there any" +
            "\n symptoms \nto report?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        var buttonWidth = 115;
        var buttonHeight = 55;

        // YES button
        var yesX = (screenWidth * 28) / 100;
        var yesY = (screenHeight * 73) / 100;

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            yesX - buttonWidth/2,
            yesY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            10
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            yesX,
            yesY,
            Graphics.FONT_MEDIUM,
            "YES",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // NO button
        var noX = (screenWidth * 72) / 100;
        var noY = (screenHeight * 73) / 100;

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            noX - buttonWidth/2,
            noY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            10
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            noX,
            noY,
            Graphics.FONT_MEDIUM,
            "NO",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    
}

class YesPageDelegate extends WatchUi.BehaviorDelegate {
    
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Bottom half of screen (y > 180)
        if (y > 180) {
            // Left side - YES
            if (x < 180) {
                var checkView = new checkPageView();
                var checkDelegate = new checkPageDelegate(checkView);
                WatchUi.pushView(checkView, checkDelegate, WatchUi.SLIDE_UP);
                return true;
            }
            // Right side - NO
            else {
                var chartView = new ChartView(null);
                var chartDelegate = new ChartDelegate();
                chartDelegate.setView(chartView);
                WatchUi.pushView(chartView, chartDelegate, WatchUi.SLIDE_DOWN);
                return true;
            }
        }
        
        return false;
    }
}