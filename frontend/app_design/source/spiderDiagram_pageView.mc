import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

class SpiderDiagramView extends WatchUi.View {
    private var symptomLabels as Array<String>;
    private var symptomValues as Array<Number>;
    private var numSymptoms as Number;
    private var centerX as Float;
    private var centerY as Float;
    private var radius as Float;
    private var recordedDate as Time.Moment;
    
    function initialize(labels as Array<String>, checkedStates as Array<Boolean>, dateRecorded as Time.Moment) {
        View.initialize();
        symptomLabels = labels;
        numSymptoms = labels.size();
        recordedDate = dateRecorded;
        
        // Initialize drawing variables with default values
        centerX = 0.0;
        centerY = 0.0;
        radius = 0.0;
        
        // Convert boolean states to values (0-100)
        symptomValues = new Array<Number>[numSymptoms];
        for (var i = 0; i < numSymptoms; i++) {
            symptomValues[i] = checkedStates[i] ? 100 : 0;
        }
    }
    
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        
        // Calculate center and radius for spider diagram
        centerX = screenWidth / 2.0;
        centerY = screenHeight / 2.0;
        // Use smaller radius to leave room for labels
        radius = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.28;
        
        // Get date when symptoms were recorded
        var dateInfo = Time.Gregorian.info(recordedDate, Time.FORMAT_SHORT);
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var monthName = monthNames[dateInfo.month - 1];
        var dateText = Lang.format("$1$ $2$, $3$", [
            monthName,
            dateInfo.day,
            dateInfo.year
        ]);
        
        // Draw title with date
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            15,
            Graphics.FONT_XTINY,
            dateText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Draw grid circles (concentric circles for reference)
        drawGridCircles(dc);
        
        // Draw axes (lines from center to each symptom point)
        drawAxes(dc);
        
        // Draw the spider diagram polygon
        drawSpiderPolygon(dc);
        
        // Draw labels for each symptom
        drawLabels(dc);
    }
    
    function drawGridCircles(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        // Draw 3 concentric circles at 33%, 66%, and 100%
        for (var i = 1; i <= 3; i++) {
            var circleRadius = (radius * i) / 3;
            dc.drawCircle(centerX, centerY, circleRadius);
        }
    }
    
    function drawAxes(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var angleStep = (2 * Math.PI) / numSymptoms;
        
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2); // Start at top
            var endX = centerX + (radius * Math.cos(angle));
            var endY = centerY + (radius * Math.sin(angle));
            dc.drawLine(centerX, centerY, endX, endY);
        }
    }
    
    function drawSpiderPolygon(dc as Dc) as Void {
        if (numSymptoms == 0) {
            return;
        }
        
        var angleStep = (2 * Math.PI) / numSymptoms;
        var points = new [numSymptoms];
        var xCoords = new [numSymptoms];
        var yCoords = new [numSymptoms];
        
        // Calculate points for the polygon
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2); // Start at top
            var valueRadius = (radius * symptomValues[i]) / 100.0;
            var x = centerX + (valueRadius * Math.cos(angle));
            var y = centerY + (valueRadius * Math.sin(angle));
            points[i] = [x, y];
            xCoords[i] = x;
            yCoords[i] = y;
        }
        
        // Draw filled polygon
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
        
        // Draw polygon outline
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < numSymptoms; i++) {
            var nextI = (i + 1) % numSymptoms;
            dc.drawLine(xCoords[i], yCoords[i], xCoords[nextI], yCoords[nextI]);
        }
        dc.setPenWidth(1);
        
        // Draw points at each vertex
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < numSymptoms; i++) {
            dc.fillCircle(xCoords[i], yCoords[i], 3);
        }
    }
    
    function drawLabels(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var angleStep = (2 * Math.PI) / numSymptoms;
        var labelRadius = radius + 25; // Position labels outside the diagram
        
        for (var i = 0; i < numSymptoms; i++) {
            var angle = (i * angleStep) - (Math.PI / 2); // Start at top
            var labelX = centerX + (labelRadius * Math.cos(angle));
            var labelY = centerY + (labelRadius * Math.sin(angle));
            
            // Abbreviate long labels for better fit
            var label = symptomLabels[i];
            if (label.length() > 8) {
                // Use abbreviation for long labels
                if (label.equals("Cardiac dysautonomia")) {
                    label = "Cardiac";
                } else if (label.equals("Gastrointestinal")) {
                    label = "GI";
                } else if (label.equals("Urogential")) {
                    label = "Uro";
                }
            }
            
            dc.drawText(
                labelX,
                labelY,
                Graphics.FONT_XTINY,
                label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }
    
    // Add getter methods to access data
    public function getSymptomValues() as Array<Number> {
        return symptomValues;
    }
    
    public function getSymptomLabels() as Array<String> {
        return symptomLabels;
    }
}

class SpiderDiagramDelegate extends WatchUi.BehaviorDelegate {
    private var view as SpiderDiagramView;
    
    function initialize(v as SpiderDiagramView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
        var direction = evt.getDirection();
        
        // Swipe up to show chart view
        if (direction == WatchUi.SWIPE_UP) {
            // Get data from spider diagram
            var symptomValues = view.getSymptomValues();
            var symptomLabels = view.getSymptomLabels();
            
            // Convert values from 0-100 scale back to 0-4 scale for the chart
            var chartData = new [symptomValues.size()];
            for (var i = 0; i < symptomValues.size(); i++) {
                chartData[i] = symptomValues[i] > 0 ? 4 : 0; // Simplified: checked = 4, unchecked = 0
            }
            
            var chartView = new ChartView(chartData, symptomLabels);
            WatchUi.pushView(chartView, new ChartDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        
        return false;
    }
}

class ChartView extends WatchUi.View {
    private var data as Array<Number>;
    private var labels as Array<String>; // will add to it
    
    function initialize(chartData as Array<Number>, chartLabels as Array<String>) {
        View.initialize();
        data = chartData;
        labels = chartLabels;
    }
    
    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 15, Graphics.FONT_XTINY, "Todays Trends", Graphics.TEXT_JUSTIFY_CENTER);
        
        var chartSize = screenW < screenH ? screenW * 0.7 : screenH * 0.7;  // 70% of screen
        var chartTop = cy - chartSize / 2;
        var chartBottom = cy + chartSize / 2;
        var chartHeight = chartBottom - chartTop;
        var chartLeft = cx - chartSize / 2;
        var chartRight = cx + chartSize / 2;
        var chartWidth = chartRight - chartLeft;
        
        var maxValue = 4;
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(chartLeft, chartTop, chartWidth, chartHeight);
        
        // horiztonal
        for (var i = 0; i <= 4; i += 2) {
            var y = chartBottom - (i * chartHeight / 4);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(chartLeft, y, chartRight, y);
            
            // Y-axis labels
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(chartLeft - 8, y, Graphics.FONT_XTINY, i.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Draw the data line
        if (data.size() > 1) {
            var stepX = chartWidth / (data.size() - 1).toFloat();
            
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            
            for (var i = 0; i < data.size() - 1; i++) {
                var x1 = chartLeft + (i * stepX);
                var y1 = chartBottom - (data[i].toFloat() / maxValue * chartHeight);
                var x2 = chartLeft + ((i + 1) * stepX);
                var y2 = chartBottom - (data[i + 1].toFloat() / maxValue * chartHeight);
                
                dc.drawLine(x1, y1, x2, y2);
            }
            
            dc.setPenWidth(1);
            
            // data points
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < data.size(); i++) {
                var x = chartLeft + (i * stepX);
                var y = chartBottom - (data[i].toFloat() / maxValue * chartHeight);
                dc.fillCircle(x, y, 2);
            }
        }
    }
}

class ChartDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}