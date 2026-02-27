import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;

class ScorePageView extends WatchUi.View {
    private var hrvAverage as Float?;
    private var hrvPercentile10 as Float?;
    private var hrvPercentile90 as Float?;
    private var daysIncluded as Number;
    private var hasData as Boolean;

    function initialize() {
        View.initialize();
        hrvAverage = null;
        hrvPercentile10 = null;
        hrvPercentile90 = null;
        daysIncluded = 0;
        hasData = false;
        loadHRVData();
    }

    private var morningPeak as Float?;    // how recovered you were when you woke up
private var currentLevel as Float?;   // right now
private var todayLow as Float?;       // lowest point today
private var trend as String?;         // "Recovering" / "Draining"

function loadHRVData() as Void {
    if (!(SensorHistory has :getBodyBatteryHistory)) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    // Get just today's data
    var bodyBattery = SensorHistory.getBodyBatteryHistory({
        :period => 1,
        :order => SensorHistory.ORDER_NEWEST_FIRST
    });

    if (bodyBattery == null) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    var values = [] as Array<Float>;
    var sample = bodyBattery.next();

    while (sample != null) {
        var val = sample.data;
        if (val != null) {
            values.add((val as Number).toFloat());
        }
        sample = bodyBattery.next();
    }

    if (values.size() == 0) {
        hasData = false;
        WatchUi.requestUpdate();
        return;
    }

    // Most recent = first sample (newest first order)
    currentLevel = values[0];

    // Peak = highest value (usually morning)
    var peak = values[0];
    var low = values[0];
    for (var i = 1; i < values.size(); i++) {
        if (values[i] > peak) { peak = values[i]; }
        if (values[i] < low) { low = values[i]; }
    }
    morningPeak = peak;
    todayLow = low;

    // Trend - compare last 3 samples
    if (values.size() >= 3) {
        if (values[0] > values[2]) {
            trend = "Recovering";
        } else if (values[0] < values[2]) {
            trend = "Draining";
        } else {
            trend = "Stable";
        }
    }

    hasData = true;
    WatchUi.requestUpdate();
}

    // Bubble sort
    function sortArray(arr as Array<Float>) as Array<Float> {
        var n = arr.size();
        for (var i = 0; i < n - 1; i++) {
            for (var j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    var tmp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = tmp;
                }
            }
        }
        return arr;
    }

    function getPercentile(sorted as Array<Float>, pct as Float) as Float {
        var idx = (pct / 100.0f) * (sorted.size() - 1);
        var lo = idx.toNumber();
        var hi = lo + 1;
        if (hi >= sorted.size()) {
            return sorted[sorted.size() - 1];
        }
        var frac = idx - lo.toFloat();
        return sorted[lo] + frac * (sorted[hi] - sorted[lo]);
    }

    function onUpdate(dc as Dc) as Void {
    var screenW = dc.getWidth();
    var screenH = dc.getHeight();
    var cx = screenW / 2;
    var cy = screenH / 2;

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    if (!hasData) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_SMALL, "No Data",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, "Wear watch longer",
            Graphics.TEXT_JUSTIFY_CENTER);
        return;
    }

    // Title
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, 40, Graphics.FONT_XTINY, "BODY BATTERY",
        Graphics.TEXT_JUSTIFY_CENTER);

    // Current value - big number
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, cy - 20, Graphics.FONT_NUMBER_HOT,
        currentLevel.format("%.0f"),
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    // Trend
    if (trend != null) {
        var trendColor = Graphics.COLOR_GREEN;
        if (trend.equals("Draining")) { trendColor = Graphics.COLOR_RED; }
        if (trend.equals("Stable")) { trendColor = Graphics.COLOR_YELLOW; }
        dc.setColor(trendColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 35, Graphics.FONT_XTINY, trend,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Peak and Low
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, cy + 60, Graphics.FONT_XTINY, "Peak    Low",
        Graphics.TEXT_JUSTIFY_CENTER);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var peakLowText = morningPeak.format("%.0f") + "       " + todayLow.format("%.0f");
    dc.drawText(cx, cy + 85, Graphics.FONT_XTINY, peakLowText,
        Graphics.TEXT_JUSTIFY_CENTER);

    drawPageIndicators(dc, screenH, 1);
}

    function drawPageIndicators(dc as Dc, screenH as Number, currentPage as Number) as Void {
        var dotRadius = 4;
        var dotSpacing = 15;
        var x = 20;
        var startY = (screenH / 2) - dotSpacing;

        for (var i = 0; i < 4; i++) {
            var y = startY + (i * dotSpacing);
            if (i == currentPage) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotRadius);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(x, y, dotRadius);
            }
        }
    }
}

class ScorePageDelegate extends WatchUi.BehaviorDelegate {
    private var view as ScorePageView;

    function initialize(v as ScorePageView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Press button to refresh
    function onSelect() as Boolean {
        view.loadHRVData();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

   function onSwipe(evt as SwipeEvent) as Boolean {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            var chartView = new ChartView(null);
            var chartDelegate = new ChartDelegate();
            chartDelegate.setView(chartView);
            WatchUi.pushView(chartView, chartDelegate, WatchUi.SLIDE_UP);
        }
        return false;
    }
}