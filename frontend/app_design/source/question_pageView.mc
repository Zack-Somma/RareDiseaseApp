import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;

// -------------------------
// SPIDER DIAGRAM RATING SCREEN WITH ALL 31 QUESTIONS
// -------------------------
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;

class questionPageView extends WatchUi.View {
    public var value as Number;
    public var currentQuestionIndex as Number;
    public var questions as Array<String>;
    public var responses as Array<Number>;
    
    private var activeCategories as Array<String>;
    private var allQuestions as Array<String>;
    private var questionCategories as Array<String>;
    private var filteredQuestionCategories as Array<String>;
    
    public var screenW as Number;
    public var screenH as Number;
    public var decBox as Array<Number>;
    public var incBox as Array<Number>;
    public var continueBox as Array<Number>;
    public var backBox as Array<Number>;
    
    function initialize(checkedSymptoms as Array<String>) {
        View.initialize();
        value = 0;
        currentQuestionIndex = 0;
        screenW = 0;
        screenH = 0;
        decBox = [0,0,0,0];
        incBox = [0,0,0,0];
        continueBox = [0,0,0,0];
        backBox = [0,0,0,0];
        
        activeCategories = checkedSymptoms;
        questions = [];  // Initialize here
        filteredQuestionCategories = [];
        
        // Define ALL questions with their category mapping
        allQuestions = [
            "Joint instability",                    // NMSK
            "Muscle weakness",                      // NMSK
            "Muscle spasms",                        // NMSK
            "Balance & proprioception problems",    // NMSK
            "Tingling or loss of sensation",        // NMSK
            "Joint pain",                           // Pain
            "Widespread pain",                      // Pain
            "Headaches or migraines",              // Pain
            "Pain from mild sensations",           // Pain
            "Physical tiredness",                   // Fatigue
            "Mental tiredness",                     // Fatigue
            "Difficulty with sleep",                // Fatigue
            "Faint when moving to standing",        // Cardiac dysautonomia
            "Faint when standing upright",          // Cardiac dysautonomia
            "Autonomic impact severity",            // Cardiac dysautonomia
            "Impact on daily life",                 // Cardiac dysautonomia
            "Abdominal bloating/pain",              // Gastrointestinal
            "Diarrhea or constipation",            // Gastrointestinal
            "Nausea or vomiting",                  // Gastrointestinal
            "Reflux or difficulty swallowing",     // Gastrointestinal
            "Full bladder sensation",               // Urogential
            "Urine loss",                           // Urogential
            "Difficulty passing urine",             // Urogential
            "Genital discomfort",                   // Urogential
            "Urinary infections",                   // Urogential
            "Fear of movement",                     // Anxiety
            "Feeling worried or restless",          // Anxiety
            "Feeling afraid",                       // Anxiety
            "Feeling down or hopeless",             // Depression
            "No solutions to problems",             // Depression
            "Little interest in things"             // Depression 
        ];
        
        questionCategories = [
            "NMSK", "NMSK", "NMSK", "NMSK", "NMSK",              // Q1-5
            "Pain", "Pain", "Pain", "Pain",                      // Q6-9
            "Fatigue", "Fatigue", "Fatigue",                     // Q10-12
            "Cardiac dysautonomia", "Cardiac dysautonomia",      // Q13-14
            "Cardiac dysautonomia", "Cardiac dysautonomia",      // Q15-16
            "Gastrointestinal", "Gastrointestinal",              // Q17-18
            "Gastrointestinal", "Gastrointestinal",              // Q19-20
            "Urogential", "Urogential", "Urogential",            // Q21-23
            "Urogential", "Urogential",                          // Q24-25
            "Anxiety", "Anxiety", "Anxiety",                     // Q26-28
            "Depression", "Depression", "Depression"             // Q29-31
        ];
        
        filterQuestions();

        responses = new [questions.size()];
        for (var i = 0; i < responses.size(); i++) {
            responses[i] = 0;
        }
        
        clearResponses();
    }
    
    function filterQuestions() as Void {
        questions = [];
        filteredQuestionCategories = [];
        
        for (var i = 0; i < allQuestions.size(); i++) {
            var category = questionCategories[i] as String;
            
            var isActive = false;
            for (var j = 0; j < activeCategories.size(); j++) {
                if (category.equals(activeCategories[j])) {
                    isActive = true;
                    break;
                }
            }
            
            if (isActive) {
                questions.add(allQuestions[i]);
                filteredQuestionCategories.add(category);
            }
        }
        
        if (questions.size() == 0) {
            questions = allQuestions;
            filteredQuestionCategories = questionCategories;
        }
    }
    
    public function getFilteredQuestionCategories() as Array<String> {
        return filteredQuestionCategories;
    }
    
    function clamp() as Void {
        if (value < 0) { value = 0; }
        if (value > 4) { value = 4; }
    }
    
    public function inc() as Void {
        value++;
        clamp();
        WatchUi.requestUpdate();
    }
    
    public function dec() as Void {
        value--;
        clamp();
        WatchUi.requestUpdate();
    }
    
    public function getLabelForValue(v as Number) as String {
        if (v == 0) { return "Skip"; }
        if (v == 1) { return "Mild Impact"; }
        if (v == 2) { return "Moderate Impact"; }
        if (v == 3) { return "Marked Impact"; }
        return "Disabling";
    }
    
    public function hit(box as Array<Number>, x as Number, y as Number) as Boolean {
        if (box == null || box.size() < 4) {
            return false;
        }
        var bx = box[0] as Number;
        var by = box[1] as Number;
        var bw = box[2] as Number;
        var bh = box[3] as Number;
        return (x >= bx && x <= bx + bw && y >= by && y <= by + bh);
    }
    
    public function saveResponses() as Void {
        for (var i = 0; i < responses.size(); i++) {
            Storage.setValue("response_" + i, responses[i]);
        }
        Storage.setValue("lastQuestionIndex", currentQuestionIndex);
    }
    
    public function loadResponses() as Void {
        for (var i = 0; i < responses.size(); i++) {
            var saved = Storage.getValue("response_" + i);
            if (saved != null) {
                responses[i] = saved as Number;
            }
        }
        var savedIndex = Storage.getValue("lastQuestionIndex");
        if (savedIndex != null) {
            currentQuestionIndex = savedIndex as Number;
            value = responses[currentQuestionIndex] as Number;
        }
    }
    
    public function clearResponses() as Void {
        for (var i = 0; i < responses.size(); i++) {
            Storage.deleteValue("response_" + i);
            responses[i] = 0;
        }
        Storage.deleteValue("lastQuestionIndex");
        currentQuestionIndex = 0;
        value = 0;
    }
    
    public function previousQuestion() as Void {
        responses[currentQuestionIndex] = value;
        
        if (currentQuestionIndex > 0) {
            currentQuestionIndex--;
            value = responses[currentQuestionIndex] as Number;
            WatchUi.requestUpdate();
        }
    }
    
    public function nextQuestion() as Void {
    responses[currentQuestionIndex] = value;
    
    if (currentQuestionIndex < questions.size() - 1) {
        currentQuestionIndex++;
        value = responses[currentQuestionIndex] as Number;
        WatchUi.requestUpdate();
    } else {
        System.println("Spider Diagram Complete!");
        for (var i = 0; i < questions.size(); i++) {
            System.println("Q" + (i+1) + ": " + responses[i]);
        }
        
        SurveyStorage.saveSurveyData(responses, activeCategories, filteredQuestionCategories);
        
        saveResponses(); 
        
        var completionView = new CompletionView(responses, activeCategories, filteredQuestionCategories);
        WatchUi.switchToView(completionView, new CompletionDelegate(completionView), WatchUi.SLIDE_LEFT);
    }
}
    
    function onUpdate(dc as Dc) as Void {
        screenW = dc.getWidth();
        screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var titleText = "Question " + (currentQuestionIndex + 1) + "/" + questions.size();
        dc.drawText(
            cx,
            cy - r + 18,
            Graphics.FONT_XTINY,
            titleText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var questionY = cy - r + 50;
        var currentQuestion = questions[currentQuestionIndex] as String;
        var fontSize = Graphics.FONT_XTINY;
        
        if (currentQuestion.length() > 30) {
            questionY = cy - r + 42;
        }
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var words = splitString(currentQuestion, " ");
        var currentLine = "";
        var lineY = questionY;
        var lineHeight = 18;
        var maxLineChars = currentQuestion.length() > 30 ? 18 : 22;
        
        for (var i = 0; i < words.size(); i++) {
            var word = words[i] as String;
            var testLine = currentLine;
            if (testLine.length() > 0) {
                testLine = testLine + " " + word;
            } else {
                testLine = word;
            }
            
            if (testLine.length() > maxLineChars && currentLine.length() > 0) {
                dc.drawText(
                    cx,
                    lineY,
                    fontSize,
                    currentLine,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
                lineY += lineHeight;
                currentLine = word;
            } else {
                currentLine = testLine;
            }
        }
        
        if (currentLine.length() > 0) {
            dc.drawText(
                cx,
                lineY,
                fontSize,
                currentLine,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        
        var controlsY = cy + 8;
        var leftX = cx - 70;
        var rightX = cx + 70;
        var arrowSize = 14;
        
        var boxW = 65;
        var boxH = 65;
        decBox = [leftX - boxW/2, controlsY - boxH/2, boxW, boxH];
        incBox = [rightX - boxW/2, controlsY - boxH/2, boxW, boxH];
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawMinus(dc, leftX, controlsY, arrowSize);
        drawPlus(dc, rightX, controlsY, arrowSize);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            controlsY,
            Graphics.FONT_LARGE,
            value.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        dc.drawText(
            cx,
            cy + r - 150,
            Graphics.FONT_XTINY,
            getLabelForValue(value),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var backBtnW = 75;
        var backBtnH = 40;
        var backBtnX = cx - 50;
        var backBtnY = cy + r - 80;
        
        backBox = [backBtnX - backBtnW/2, backBtnY - backBtnH/2, backBtnW, backBtnH];
        
        if (currentQuestionIndex > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(backBtnX - backBtnW/2, backBtnY - backBtnH/2, backBtnW, backBtnH, 6);
        dc.setPenWidth(1);
        
        dc.drawText(
            backBtnX,
            backBtnY,
            Graphics.FONT_XTINY,
            "BACK",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        var btnW = 75;
        var btnH = 40;
        var btnX = cx + 50;
        var btnY = cy + r - 80;
        continueBox = [btnX - btnW/2, btnY - btnH/2, btnW, btnH];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(btnX - btnW/2, btnY - btnH/2, btnW, btnH, 6);
        dc.setPenWidth(1);
        
        var btnText = (currentQuestionIndex == questions.size() - 1) ? "DONE" : "NEXT";
        dc.drawText(
            btnX,
            btnY,
            Graphics.FONT_XTINY,
            btnText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    function splitString(str as String, delimiter as String) as Array<String> {
        var result = [] as Array<String>;
        var current = "";
        
        for (var i = 0; i < str.length(); i++) {
            var char = str.substring(i, i + 1);
            if (char.equals(delimiter)) {
                if (current.length() > 0) {
                    result.add(current);
                    current = "";
                }
            } else {
                current = current + char;
            }
        }
        
        if (current.length() > 0) {
            result.add(current);
        }
        
        return result;
    }
    
    function drawMinus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawLine(x - size, y, x + size, y);
        dc.setPenWidth(1);
    }
    
    function drawPlus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawLine(x - size, y, x + size, y);
        dc.drawLine(x, y - size, x, y + size);
        dc.setPenWidth(1);
    }
    
    function drawTriangleUp(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var pts = [
            [x, y - size],
            [x - size, y + size],
            [x + size, y + size]
        ];
        dc.fillPolygon(pts);
    }
    
    function drawTriangleDown(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var pts = [
            [x, y + size],
            [x - size, y - size],
            [x + size, y - size]
        ];
        dc.fillPolygon(pts);
    }
    
    function drawTriangleLeft(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var pts = [
            [x - size, y],
            [x + size, y - size],
            [x + size, y + size]
        ];
        dc.fillPolygon(pts);
    }
    
    function drawTriangleRight(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var pts = [
            [x + size, y],
            [x - size, y - size],
            [x - size, y + size]
        ];
        dc.fillPolygon(pts);
    }
}
// Delegate for the rating screen
class QuestionPageDelegate extends WatchUi.BehaviorDelegate {
    private var view as questionPageView;

    function initialize(v as questionPageView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(e as ClickEvent) as Lang.Boolean {
        var c = e.getCoordinates();
        var x = c[0] as Number;
        var y = c[1] as Number;

        if (view.hit(view.decBox, x, y)) {
            view.dec();
            return true;
        }

        if (view.hit(view.incBox, x, y)) {
            view.inc();
            return true;
        }
        
        if (view.hit(view.backBox, x, y)) {
            view.previousQuestion();
            return true;
        }

        if (view.hit(view.continueBox, x, y)) {
            view.nextQuestion();
            return true;
        }

        return false;
    }

    function onBack() as Lang.Boolean {
        // Save progress before exiting
        view.saveResponses();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
// -------------------------
// COMPLETION SCREEN - "Nice Job!"
// -------------------------
class CompletionView extends WatchUi.View {
    
    private var responses as Array<Number>;
    private var activeCategories as Array<String>;
    private var questionCategories as Array<String>;
    
    function initialize(resp as Array<Number>, categories as Array<String>, qCategories as Array<String>) {
        View.initialize();
        responses = resp;
        activeCategories = categories;
        questionCategories = qCategories;
    }
    
    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        dc.setColor(0x7B2FBE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r - 4);
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCheckmark(dc, cx, cy - 30, 30);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy + 40,
            Graphics.FONT_MEDIUM,
            "Nice Job!",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        dc.drawText(
            cx,
            cy + 70,
            Graphics.FONT_XTINY,
            "Swipe up for results",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    function drawCheckmark(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawCircle(x, y, size);
        
        dc.setPenWidth(3);
        dc.drawLine(
            x - size * 5 / 10, 
            y, 
            x - size * 1 / 10, 
            y + size * 4 / 10
        );
        dc.drawLine(
            x - size * 1 / 10, 
            y + size * 4 / 10, 
            x + size * 6 / 10, 
            y - size * 4 / 10
        );
        dc.setPenWidth(1);
    }
    
    public function getResponses() as Array<Number> {
        return responses;
    }
    
    public function getActiveCategories() as Array<String> {
        return activeCategories;
    }
    
    public function getQuestionCategories() as Array<String> {
        return questionCategories;
    }
}
// Delegate for the completion screen
class CompletionDelegate extends WatchUi.BehaviorDelegate {
    private var view as CompletionView;
    
    function initialize(v as CompletionView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onTap(e as ClickEvent) as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
        var direction = evt.getDirection();
        
        if (direction == WatchUi.SWIPE_UP) {
            var responses = view.getResponses();
            var activeCategories = view.getActiveCategories();
            var questionCategories = view.getQuestionCategories();
            
            // Calculate average for each active category
            var symptomLabels = activeCategories;
            var percentageValues = new [activeCategories.size()];
            
            for (var c = 0; c < activeCategories.size(); c++) {
                var categoryName = activeCategories[c] as String;
                var sum = 0.0;
                var count = 0;
                
                // Find all responses that belong to this category
                for (var i = 0; i < responses.size(); i++) {
                    if (questionCategories[i].equals(categoryName)) {
                        sum += (responses[i].toFloat() / 4.0 * 100.0);
                        count++;
                    }
                }
                
                percentageValues[c] = (count > 0) ? (sum / count).toNumber() : 0;
                
                System.println("Category: " + categoryName + " = " + percentageValues[c] + "% (from " + count + " questions)");
            }
            
            var dateRecorded = Time.now();
            var spiderView = new SpiderDiagramView(symptomLabels, percentageValues, dateRecorded);
            WatchUi.pushView(spiderView, new SpiderDiagramDelegate(spiderView), WatchUi.SLIDE_UP);
            return true;
        }
        
        return false;
    }
    
    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}