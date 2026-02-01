import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;

// -------------------------
// SPIDER DIAGRAM RATING SCREEN WITH ALL 31 QUESTIONS
// -------------------------
class questionPageView extends WatchUi.View {

    public var value as Number;           // 1..4
    public var currentQuestionIndex as Number;  // 0..30 (for 31 questions)
    public var questions as Array<String>;
    public var responses as Array<Number>;  // Store all responses

    // cached sizes + hitboxes
    public var screenW as Number;
    public var screenH as Number;

    public var decBox as Array<Number>;
    public var incBox as Array<Number>;
    public var continueBox as Array<Number>;
    public var backBox as Array<Number>;  // New: back button hitbox

    function initialize() {
        View.initialize();
        value = 0;
        currentQuestionIndex = 0;
        screenW = 0;
        screenH = 0;
        decBox = [0,0,0,0];
        incBox = [0,0,0,0];
        continueBox = [0,0,0,0];
        backBox = [0,0,0,0];
        
        // Initialize all 31 questions
        questions = [
            "Joint instability",  // 1
            "Muscle weakness",    // 2
            "Muscle spasms",      // 3
            "Balance & proprioception problems",  // 4
            "Tingling or loss of sensation",  // 5
            "Joint pain",  // 6
            "Widespread pain",  // 7
            "Headaches or migraines",  // 8
            "Pain from mild sensations",  // 9
            "Physical tiredness",  // 10
            "Mental tiredness",  // 11
            "Difficulty with sleep",  // 12
            "Faint when moving to standing",  // 13
            "Faint when standing upright",  // 14
            "Autonomic impact severity",  // 15 (changed from check-all to rating)
            "Impact on daily life",  // 16
            "Abdominal bloating/pain",  // 17
            "Diarrhea or constipation",  // 18
            "Nausea or vomiting",  // 19
            "Reflux or difficulty swallowing",  // 20
            "Full bladder sensation",  // 21
            "Urine loss",  // 22
            "Difficulty passing urine",  // 23
            "Genital discomfort",  // 24
            "Urinary infections",  // 25
            "Fear of movement",  // 26
            "Feeling worried or restless",  // 27
            "Feeling afraid",  // 28
            "Feeling down or hopeless",  // 29
            "No solutions to problems",  // 30
            "Little interest in things"  // 31
        ];
        
        // Initialize responses array - all start at 0 (Skip)
        responses = new [questions.size()];
        for (var i = 0; i < responses.size(); i++) {
            responses[i] = 0;
        }
        
        // Always start fresh at Question 1
        // Clear any previously saved progress so we don't skip ahead
        clearResponses();
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
    
    // Save responses to persistent storage
    public function saveResponses() as Void {
        for (var i = 0; i < responses.size(); i++) {
            Storage.setValue("response_" + i, responses[i]);
        }
        Storage.setValue("lastQuestionIndex", currentQuestionIndex);
    }
    
    // Load responses from persistent storage
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
    
    // Clear all saved data
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
        // Save current response
        responses[currentQuestionIndex] = value;
        
        if (currentQuestionIndex > 0) {
            currentQuestionIndex--;
            value = responses[currentQuestionIndex] as Number;
            WatchUi.requestUpdate();
        }
    }
    
    public function nextQuestion() as Void {
        // Save current response
        responses[currentQuestionIndex] = value;
        
        // Move to next question
        if (currentQuestionIndex < questions.size() - 1) {
            currentQuestionIndex++;
            // Load saved response for this question
            value = responses[currentQuestionIndex] as Number;
            WatchUi.requestUpdate();
        } else {
            // All questions completed - save and show results
            System.println("Spider Diagram Complete!");
            for (var i = 0; i < questions.size(); i++) {
                System.println("Q" + (i+1) + ": " + responses[i]);
            }
            
            // Save final responses
            saveResponses();
            
            // Navigate to completion screen
            var completionView = new CompletionView(responses);
            WatchUi.switchToView(completionView, new CompletionDelegate(completionView), WatchUi.SLIDE_LEFT);
            
        }
    }

    function onUpdate(dc as Dc) as Void {
        screenW = dc.getWidth();
        screenH = dc.getHeight();

        var cx = screenW / 2;
        var cy = screenH / 2;

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // White circle card
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;

        // Title with question counter
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var titleText = "Question " + (currentQuestionIndex + 1) + "/31";
        dc.drawText(
            cx,
            cy - r + 18,
            Graphics.FONT_XTINY,
            titleText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Question text - adjust font size for longer questions
        var questionY = cy - r + 50;
        var currentQuestion = questions[currentQuestionIndex] as String;
        var fontSize = Graphics.FONT_XTINY;
        
        // Adjust positioning for very long questions
        if (currentQuestion.length() > 30) {
            questionY = cy - r + 42;
        }
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Word wrapping
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
        
        // Draw last line
        if (currentLine.length() > 0) {
            dc.drawText(
                cx,
                lineY,
                fontSize,
                currentLine,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // Controls
        var controlsY = cy + 8;

        // Arrow positions (using minus/plus style)
        var leftX = cx - 70;
        var rightX = cx + 70;
        var arrowSize = 14;

        // Hitboxes for controls
        var boxW = 65;
        var boxH = 65;
        decBox = [leftX - boxW/2, controlsY - boxH/2, boxW, boxH];
        incBox = [rightX - boxW/2, controlsY - boxH/2, boxW, boxH];

        // Draw minus (decrease) on left
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawMinus(dc, leftX, controlsY, arrowSize);
        
        // Draw plus (increase) on right
        drawPlus(dc, rightX, controlsY, arrowSize);

        // Center display - always show the number (0-4)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            controlsY,
            Graphics.FONT_LARGE,
            value.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Impact label
        dc.drawText(
            cx,
            cy + r - 150,
            Graphics.FONT_XTINY,
            getLabelForValue(value),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Navigation buttons at bottom - always show both BACK and NEXT/DONE
        
        // --- BACK button ---
        var backBtnW = 75;
        var backBtnH = 40;
        var backBtnX = cx - 50;
        var backBtnY = cy + r - 80;
        
        backBox = [backBtnX - backBtnW/2, backBtnY - backBtnH/2, backBtnW, backBtnH];
        
        // Gray out BACK on first question
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
        
        // --- NEXT/DONE button ---
        var btnW = 75;
        var btnH = 40;
        var btnX = cx + 50;
        var btnY = cy + r - 80;

        continueBox = [btnX - btnW/2, btnY - btnH/2, btnW, btnH];

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(btnX - btnW/2, btnY - btnH/2, btnW, btnH, 6);
        dc.setPenWidth(1);

        // Show "DONE" on last question, "NEXT" otherwise
        var btnText = (currentQuestionIndex == questions.size() - 1) ? "DONE" : "NEXT";
        dc.drawText(
            btnX,
            btnY,
            Graphics.FONT_XTINY,
            btnText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    // Helper function to split string by delimiter
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

    // Draw a minus sign
    function drawMinus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawLine(x - size, y, x + size, y);
        dc.setPenWidth(1);
    }
    
    // Draw a plus sign
    function drawPlus(dc as Dc, x as Number, y as Number, size as Number) as Void {
        dc.setPenWidth(3);
        dc.drawLine(x - size, y, x + size, y);  // Horizontal
        dc.drawLine(x, y - size, x, y + size);  // Vertical
        dc.setPenWidth(1);
    }

    // Keep triangle functions for reference or alternative use
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
    
    // Draw left-pointing triangle (alternative to minus)
    function drawTriangleLeft(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var pts = [
            [x - size, y],
            [x + size, y - size],
            [x + size, y + size]
        ];
        dc.fillPolygon(pts);
    }
    
    // Draw right-pointing triangle (alternative to plus)
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
    
    function initialize(resp as Array<Number>) {
        View.initialize();
        responses = resp;
    }
    
    function onUpdate(dc as Dc) as Void {
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        
        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // White circle card with purple border
        var r = (screenW < screenH ? screenW : screenH) / 2 - 12;
        
        // Purple ring
        dc.setColor(0x7B2FBE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
        
        // White fill inside the ring
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r - 4);
        
        // Checkmark icon
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCheckmark(dc, cx, cy - 30, 30);
        
        // "Nice Job!" text
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy + 40,
            Graphics.FONT_MEDIUM,
            "Nice Job!",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        // Instruction text
        dc.drawText(
            cx,
            cy + 70,
            Graphics.FONT_XTINY,
            "Swipe up for results",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    // Draw a checkmark inside a circle
    function drawCheckmark(dc as Dc, x as Number, y as Number, size as Number) as Void {
        // Circle outline
        dc.setPenWidth(3);
        dc.drawCircle(x, y, size);
        
        // Checkmark lines
        dc.setPenWidth(3);
        // Short stroke (down-right)
        dc.drawLine(
            x - size * 5 / 10, 
            y, 
            x - size * 1 / 10, 
            y + size * 4 / 10
        );
        // Long stroke (up-right)
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
}

// Delegate for the completion screen
class CompletionDelegate extends WatchUi.BehaviorDelegate {
    private var view as CompletionView;
    
    function initialize(v as CompletionView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onTap(e as ClickEvent) as Lang.Boolean {
        // Tap anywhere to dismiss
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    
    function onSwipe(evt as SwipeEvent) as Lang.Boolean {
        var direction = evt.getDirection();
        
        // Swipe up to show spider diagram
        if (direction == WatchUi.SWIPE_UP) {
            var responses = view.getResponses();
            
            var symptomLabels = [
            "NMSK",
            "Pain",
            "Urogential",
            "Anxiety",
            "Depression",
            "Cardiac dysautonomia",
            "Gastrointestinal",
            "Fatigue"
            ];
            
            // Convert responses to checked states
            var checkedStates = new [responses.size()];
            for (var i = 0; i < responses.size(); i++) {
                checkedStates[i] = (responses[i] > 0);
            }
            
            var dateRecorded = Time.now();
            var spiderView = new SpiderDiagramView(symptomLabels, checkedStates, dateRecorded);
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