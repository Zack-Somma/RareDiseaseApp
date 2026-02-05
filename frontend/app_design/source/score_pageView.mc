import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.System;

// -------------------------
// HRV ROLLING AVERAGE SCORE PAGE
// -------------------------
// NOTE: To use HTTP requests, you must add Communications permission:
// 1. Open VS Code Command Palette
// 2. Run "Monkey C: Edit Permissions"
// 3. Add "Communications" permission
//
// Also update BACKEND_URL below to your public ngrok URL (watch can't access localhost)
// -------------------------
class scorePageView extends WatchUi.View {
    
    // HRV statistics from backend
    private var hrvAverage as Float?;
    private var hrvPercentile10 as Float?;
    private var hrvPercentile90 as Float?;
    private var daysIncluded as Number;
    private var isLoading as Boolean;
    private var errorMessage as String?;
    
    // Backend URL - UPDATE THIS to your ngrok URL (e.g., "https://your-ngrok-url.ngrok-free.dev/hrv/rolling21")
    // Watch apps cannot access localhost, so use ngrok or a public server
    private const BACKEND_URL = "https://your-ngrok-url.ngrok-free.dev/hrv/rolling21";
    
    function initialize() {
        View.initialize();
        hrvAverage = null;
        hrvPercentile10 = null;
        hrvPercentile90 = null;
        daysIncluded = 0;
        isLoading = true;
        errorMessage = null;
        
        // Fetch HRV data on initialization
        loadHRVData();
    }
    
    function loadHRVData() as Void {
        isLoading = true;
        errorMessage = null;
        WatchUi.requestUpdate();
        
        // Make HTTP request to backend
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        
        Communications.makeWebRequest(
            BACKEND_URL,
            null,
            options,
            method(:onHRVDataReceived)
        );
    }
    
    function onHRVDataReceived(responseCode as Number, data as Dictionary?) as Void {
        isLoading = false;
        
        if (responseCode == 200 && data != null) {
            // Parse response
            if (data.hasKey("average") && data.get("average") != null) {
                hrvAverage = data.get("average") as Float;
            }
            if (data.hasKey("percentile10") && data.get("percentile10") != null) {
                hrvPercentile10 = data.get("percentile10") as Float;
            }
            if (data.hasKey("percentile90") && data.get("percentile90") != null) {
                hrvPercentile90 = data.get("percentile90") as Float;
            }
            if (data.hasKey("daysIncluded")) {
                daysIncluded = data.get("daysIncluded") as Number;
            }
            errorMessage = null;
        } else {
            // Handle error
            if (data != null && data.hasKey("error")) {
                errorMessage = data.get("error") as String;
            } else {
                errorMessage = "Failed to load HRV data";
            }
            hrvAverage = null;
            hrvPercentile10 = null;
            hrvPercentile90 = null;
        }
        
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // White circle card (similar to question_pageView style)
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy - r + 20,
            Graphics.FONT_XTINY,
            "Today's Score:",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Subtitle - 21 day window
        
        if (isLoading) {
            // Loading state
            dc.drawText(
                cx,
                cy,
                Graphics.FONT_SMALL,
                "Loading...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else if (errorMessage != null) {
            // Error state
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx,
                cy - 20,
                Graphics.FONT_XTINY,
                "Error",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            dc.drawText(
                cx,
                cy + 10,
                Graphics.FONT_XTINY,
                errorMessage,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else if (hrvAverage != null) {
            // Display HRV statistics
            
            // Main average value (large)
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var avgText = hrvAverage.format("%.1f");
            dc.drawText(
                cx,
                cy - 30,
                Graphics.FONT_NUMBER_HOT,
                avgText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            // Label
            dc.drawText(
                cx,
                cy + 10,
                Graphics.FONT_XTINY,
                "Average",
                Graphics.TEXT_JUSTIFY_CENTER
            );
            
            // Percentile range (below)
            if (hrvPercentile10 != null && hrvPercentile90 != null) {
                var rangeY = cy + r - 80;
                
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    cx,
                    rangeY,
                    Graphics.FONT_XTINY,
                    "Range (10th-90th)",
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                
                var rangeText = hrvPercentile10.format("%.1f") + " - " + hrvPercentile90.format("%.1f");
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    cx,
                    rangeY + 18,
                    Graphics.FONT_XTINY,
                    rangeText,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }
            
            // Days included
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx,
                cy + r - 40,
                Graphics.FONT_XTINY,
                daysIncluded.toString() + " days",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            // No data available
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx,
                cy,
                Graphics.FONT_SMALL,
                "No HRV data",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }
}

// Delegate for the score page
class ScorePageDelegate extends WatchUi.BehaviorDelegate {
    private var view as scorePageView;
    
    function initialize(v as scorePageView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onSelect() as Boolean {
        // Refresh data on select
        view.loadHRVData();
        return true;
    }
    
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();

        // Swipe up from score page to show trends screen (ChartView)
        if (direction == WatchUi.SWIPE_UP) {
            // For now, reuse the placeholder data/labels used elsewhere
            var chartView = new ChartView([0, 3, 4, 1, 2], ["Placeholder values"]);
            WatchUi.pushView(chartView, new ChartDelegate(), WatchUi.SLIDE_UP);
            return true;
        }

        return false;
    }
}

