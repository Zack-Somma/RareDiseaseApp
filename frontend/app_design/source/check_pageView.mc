import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;

class checkPageView extends WatchUi.View {
    var checklistItems as Array<String>;
    var checklistSubtitles as Array<String>;
    var categoryKeys as Array<String>;
    var checkedStates as Array<Boolean>;
    var scrollOffset as Number;
    var itemsPerScreen as Number;
    var screenWidth as Number;
    var screenHeight as Number;
    var errorMessage as String?; 
    var errorTime as Number?; 
    
    function initialize() {
        View.initialize();
        
        checklistItems = [
            "NMSK",
            "Pain",
            "Urinary",
            "Anxiety",
            "Depression",
            "Heart rate",
            "Digestive",
            "Fatigue"
        ];

        checklistSubtitles = [
        "muscle joints\n& nerves",
        "",
        "and reproductive",
        "",
        "",
        "blood pressure\nregulation",
        "stomach/bowel",
        ""
        ];

        categoryKeys = [
            "NMSK",
            "Pain",
            "Urogential",
            "Anxiety",
            "Depression",
            "Cardiac dysautonomia",
            "Gastrointestinal",
            "Fatigue"
        ];
        
        // Initialize all as unchecked
        checkedStates = new Array<Boolean>[checklistItems.size()];
        for (var i = 0; i < checkedStates.size(); i++) {
            checkedStates[i] = false;
        }
        
        scrollOffset = 0;
        itemsPerScreen = 2;
        screenWidth = 360;
        screenHeight = 360;
    }
    
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        
        // Smaller title text
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            45,
            Graphics.FONT_XTINY,
            "check all that apply:",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var startY = 82;
        var itemHeight = 104;
        var checkboxSize = 38;
        
        // Calculation
        var startIdx = scrollOffset;
        var endIdx = startIdx + itemsPerScreen;
        if (endIdx > checklistItems.size()) {
            endIdx = checklistItems.size();
        }
        
        var topItemHasMultilineSubtitle = false;
        if (startIdx < checklistSubtitles.size() && checklistSubtitles[startIdx].find("\n") != null) {
            topItemHasMultilineSubtitle = true;
        }
        var secondRowExtraGap = topItemHasMultilineSubtitle ? 34 : 0;

        for (var i = startIdx; i < endIdx; i++) {
            var visibleIdx = i - startIdx;
            var yPos = startY + visibleIdx * itemHeight;
            if (visibleIdx > 0) {
                yPos += secondRowExtraGap;
            }
            
            var checkboxX = 50;
            var checkboxY = yPos;
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(checkboxX, checkboxY, checkboxSize, checkboxSize);
            
            // Fill checkbox if checked
            if (checkedStates[i]) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(checkboxX + 2, checkboxY + 2, checkboxSize - 4, checkboxSize - 4);
            }
            
            // Text labels
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                checkboxX + checkboxSize + 12,
                yPos + checkboxSize/2,
                Graphics.FONT_LARGE,
                checklistItems[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            if (checklistSubtitles[i].length() > 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                var subtitleY = yPos + 72;
                if (checklistSubtitles[i].find("\n") != null) {
                    subtitleY = yPos + (visibleIdx == 0 ? 92 : 78);
                }
                dc.drawText(
                checkboxX + checkboxSize + 15,
                subtitleY,
                Graphics.FONT_XTINY,
                checklistSubtitles[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
        
        // Scroll indicator - page dots on the right side
        var totalPages = (checklistItems.size() + itemsPerScreen - 1) / itemsPerScreen;
        var currentPage = scrollOffset / itemsPerScreen;
        var dotX = screenWidth - 22;
        var dotSpacing = 18;
        var dotsStartY = screenHeight / 2 - ((totalPages - 1) * dotSpacing) / 2;
        
        for (var p = 0; p < totalPages; p++) {
            var dotY = dotsStartY + p * dotSpacing;
            if (p == currentPage) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 5);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 4);
            }
        }
        
        // DONE button
        var buttonWidth = 160;
        var buttonHeight = 70;
        var buttonX = screenWidth / 2;
        var buttonY = (screenHeight * 88) / 100;
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            buttonX - buttonWidth/2,
            buttonY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            10
        );
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            buttonX,
            buttonY,
            Graphics.FONT_MEDIUM,
            "DONE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (errorMessage != null) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                screenWidth / 2,
                275,
                Graphics.FONT_XTINY,
                errorMessage,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }
    
    // Based y coordinate for what was tapped
    function getItemAtPosition(y as Number) as Number {
        var startY = 82;
        var itemHeight = 108;

        var startIdx = scrollOffset;
        var endIdx = startIdx + itemsPerScreen;
        if (endIdx > checklistItems.size()) {
            endIdx = checklistItems.size();
        }

        var topItemHasMultilineSubtitle = false;
        if (startIdx < checklistSubtitles.size() && checklistSubtitles[startIdx].find("\n") != null) {
            topItemHasMultilineSubtitle = true;
        }
        var secondRowExtraGap = topItemHasMultilineSubtitle ? 34 : 0;

        for (var i = startIdx; i < endIdx; i++) {
            var visibleIdx = i - startIdx;
            var yPos = startY + visibleIdx * itemHeight;
            if (visibleIdx > 0) {
                yPos += secondRowExtraGap;
            }

            if (y >= yPos && y <= yPos + itemHeight) {
                return i;
            }
        }

        return -1;
    }
    
    // Check if DONE button was tapped
    function isDoneTapped(x as Number, y as Number) as Boolean {
        var buttonWidth = 160;
        var buttonHeight = 70;
        var buttonX = screenWidth / 2;
        var buttonY = (screenHeight * 88) / 100;
        
        return (x >= buttonX - buttonWidth/2 && 
                x <= buttonX + buttonWidth/2 &&
                y >= buttonY - buttonHeight/2 && 
                y <= buttonY + buttonHeight/2);
    }
    
    function scrollUp() as Void {
        if (scrollOffset > 0) {
            scrollOffset -= itemsPerScreen;
            if (scrollOffset < 0) { scrollOffset = 0; }
            WatchUi.requestUpdate();
        }
    }
    
    function scrollDown() as Void {
        if (scrollOffset < checklistItems.size() - itemsPerScreen) {
            scrollOffset += itemsPerScreen;
            if (scrollOffset > checklistItems.size() - itemsPerScreen) {
                scrollOffset = checklistItems.size() - itemsPerScreen;
            }
            WatchUi.requestUpdate();
        }
    }
    
    function toggleItem(index as Number) as Void {
        if (index >= 0 && index < checkedStates.size()) {
            checkedStates[index] = !checkedStates[index];
            WatchUi.requestUpdate();
        }
    }
    
    function getCheckedItems() as Array<String> {
        var checked = [];
        for (var i = 0; i < checklistItems.size(); i++) {
            if (checkedStates[i]) {
                checked.add(categoryKeys[i]);
            }
        }
        return checked;
    }

    function showError(message as String) as Void {
        errorMessage = message;
        errorTime = Time.now().value();
        WatchUi.requestUpdate();
    }

    
}

class checkPageDelegate extends WatchUi.BehaviorDelegate {
    private var view as checkPageView;
    
    function initialize(v as checkPageView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Check if tap is on DONE button
        if (view.isDoneTapped(x, y)) {

            
            var checkedItems = view.getCheckedItems();
            System.println("Checked items: " + checkedItems);
            

            if (checkedItems.size() == 0) {
                view.showError("Select symptom(s)");
                return true;
            }
            // Pass the checked symptoms to questionPageView
            var instructionsView = new InstructionsView();
            WatchUi.switchToView(instructionsView, new InstructionsDelegate(checkedItems), WatchUi.SLIDE_LEFT);
            // var questionView = new questionPageView(checkedItems);
            // WatchUi.pushView(questionView, new QuestionPageDelegate(questionView), WatchUi.SLIDE_UP);
            return true;
        }
        
        // Check if tap is on any checklist item
        var itemIndex = view.getItemAtPosition(y);
        if (itemIndex >= 0) {
            view.toggleItem(itemIndex);
            return true;
        }
        
        return false;
    }
    
    function onPreviousPage() as Lang.Boolean {
        view.scrollUp();
        return true;
    }
    
    function onNextPage() as Lang.Boolean {
        view.scrollDown();
        return true;
    }
    
    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}