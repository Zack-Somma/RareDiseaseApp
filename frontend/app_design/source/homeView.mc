import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;


class HomeView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
    
    function onUpdate(dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 60, Graphics.FONT_MEDIUM, "Today's Survey", 
                    Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_SMALL, "Complete!", 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 40, Graphics.FONT_XTINY, "Tap to view results", 
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onTap(clickEvent as ClickEvent) as Boolean {
        var today = SurveyStorage.getTodayString();
        var surveyData = SurveyStorage.getSurveyData(today);
        
        if (surveyData != null) {
            var responses = surveyData["responses"] as Array<Number>;
            var activeCategories = surveyData["categories"] as Array<String>;
            var questionCategories = surveyData["questionCategories"] as Array<String>;
            
            var symptomLabels = ["NMSK", "Pain", "Fatigue", "Gastrointestinal", "Cardiac dysautonomia", "Urogential", "Anxiety", "Depression"];
            var percentageValues = new [8];
            for (var c = 0; c < 8; c++) {
                var categoryName = symptomLabels[c] as String;
                var isActive = false;
                for (var j = 0; j < activeCategories.size(); j++) {
                    if (categoryName.equals(activeCategories[j])) {
                        isActive = true;
                        break;
                    }
                }
                if (!isActive) {
                    percentageValues[c] = 0;
                } else {
                    var sum = 0.0;
                    var count = 0;
                    for (var i = 0; i < responses.size(); i++) {
                        if (questionCategories[i].equals(categoryName)) {
                            sum += (responses[i].toFloat() / 4.0 * 100.0);
                            count++;
                        }
                    }
                    percentageValues[c] = (count > 0) ? (sum / count).toNumber() : 0;
                }
            }
            var timestamp = surveyData["timestamp"] as Number;
            var moment = new Time.Moment(timestamp);
            var spiderView = new SpiderDiagramView(symptomLabels, percentageValues, moment);
            WatchUi.pushView(spiderView, new SpiderDiagramDelegate(spiderView), WatchUi.SLIDE_LEFT);
            return true;
        }
        
        return false;
    }
    
    function onBack() as Boolean {
        System.exit();
    }

}