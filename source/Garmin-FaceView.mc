import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class Garmin_FaceView extends WatchUi.WatchFace {

    var _sleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        // Get body battery
        var bbCurrent = 0;
        var bbDayHigh = 0;
        var bbIter = SensorHistory.getBodyBatteryHistory({:period => new Time.Duration(86400)});
        if (bbIter != null) {
            var sample = bbIter.next();
            while (sample != null) {
                var val = sample.data;
                if (val != null) {
                    if (bbCurrent == 0) {
                        bbCurrent = val.toNumber();
                    }
                    if (val.toNumber() > bbDayHigh) {
                        bbDayHigh = val.toNumber();
                    }
                }
                sample = bbIter.next();
            }
        }

        var screenW = dc.getWidth();
        var screenH = dc.getHeight();
        var cx = screenW / 2;
        var cy = screenH / 2;
        var radius = cx - 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Read visual settings
        var colorTheme = Application.getApp().getProperty("ColorTheme") as Number;
        var squareStyle = Application.getApp().getProperty("SquareStyle") as Number;

        // Color themes: [spent, remaining]
        var spentColor = Graphics.COLOR_RED;
        var remainColor = Graphics.COLOR_DK_GREEN;
        if (colorTheme == 1) {
            spentColor = 0xFF8800;
            remainColor = 0x0088FF;
        } else if (colorTheme == 2) {
            spentColor = 0x9933CC;
            remainColor = 0xFFCC00;
        } else if (colorTheme == 3) {
            spentColor = 0xFF3388;
            remainColor = 0x00CCCC;
        } else if (colorTheme == 4) {
            spentColor = 0x555555;
            remainColor = 0xDDDDDD;
        }

        // Always-on mode: dim colors, skip some tiles for AMOLED burn-in
        if (_sleeping) {
            spentColor = 0x330000;
            remainColor = 0x003300;
            if (colorTheme == 1) {
                spentColor = 0x332200;
                remainColor = 0x002233;
            } else if (colorTheme == 2) {
                spentColor = 0x220033;
                remainColor = 0x332200;
            } else if (colorTheme == 3) {
                spentColor = 0x330011;
                remainColor = 0x003333;
            } else if (colorTheme == 4) {
                spentColor = 0x222222;
                remainColor = 0x444444;
            }
        }

        // Draw grid
        var squareSize = bbDayHigh > 0 ? (2000 / bbDayHigh).toNumber() : 20;
        if (squareSize < 16) { squareSize = 16; }
        if (squareSize > 56) { squareSize = 56; }
        var gap = 2;

        var visibleX = new [200];
        var visibleY = new [200];
        var visibleCount = 0;
        var cols = (screenW + squareSize - 1) / squareSize;
        var rows = (screenH + squareSize - 1) / squareSize;
        var offsetX = (screenW - cols * squareSize) / 2;
        var offsetY = (screenH - rows * squareSize) / 2;
        for (var row = 0; row < rows; row++) {
            for (var col = 0; col < cols; col++) {
                var x = offsetX + col * squareSize;
                var y = offsetY + row * squareSize;
                var midX = x + squareSize / 2;
                var midY = y + squareSize / 2;
                var dx = midX - cx;
                var dy = midY - cy;
                if (dx * dx + dy * dy <= radius * radius) {
                    visibleX[visibleCount] = x;
                    visibleY[visibleCount] = y;
                    visibleCount++;
                }
            }
        }

        var greenCount = 0;
        if (bbDayHigh > 0) {
            greenCount = (bbCurrent * visibleCount / bbDayHigh).toNumber();
        }
        var redCount = visibleCount - greenCount;
        var tileSize = squareSize - gap;
        for (var i = 0; i < visibleCount; i++) {
            var color = i < redCount ? spentColor : remainColor;
            dc.setColor(color, color);
            var tx = visibleX[i];
            var ty = visibleY[i];
            if (squareStyle == 0) {
                dc.fillRectangle(tx, ty, tileSize, tileSize);
            } else if (squareStyle == 1) {
                dc.fillRoundedRectangle(tx, ty, tileSize, tileSize, tileSize / 4);
            } else if (squareStyle == 2) {
                var r = tileSize / 2;
                dc.fillCircle(tx + r, ty + r, r);
            } else {
                var half = tileSize / 2;
                var dmx = tx + half;
                var dmy = ty + half;
                dc.fillPolygon([[dmx, dmy - half], [dmx + half, dmy], [dmx, dmy + half], [dmx - half, dmy]]);
            }
        }

        // Low body battery warning bar at top
        var lowBbThreshold = Application.getApp().getProperty("LowBbThreshold") as Number;
        if (lowBbThreshold > 0 && bbCurrent > 0 && bbCurrent <= lowBbThreshold) {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx - 40, 8, 80, 4);
        }

        // Read text settings
        var timeFormat = Application.getApp().getProperty("TimeFormat") as Number;
        var showDate = Application.getApp().getProperty("ShowDate") as Boolean;
        var dateFormat = Application.getApp().getProperty("DateFormat") as Number;
        var showSeconds = Application.getApp().getProperty("ShowSeconds") as Boolean;
        var fontSizeSetting = Application.getApp().getProperty("FontSize") as Number;
        var textColor = Application.getApp().getProperty("TextColor") as Number;
        var showBbValue = Application.getApp().getProperty("ShowBbValue") as Boolean;
        var showSteps = Application.getApp().getProperty("ShowSteps") as Boolean;
        var showHeartRate = Application.getApp().getProperty("ShowHeartRate") as Boolean;
        var showDeviceBattery = Application.getApp().getProperty("ShowDeviceBattery") as Boolean;

        // Dim text in sleep mode
        if (_sleeping) {
            textColor = 0x888888;
        }

        // Select font
        var font = Graphics.FONT_MEDIUM;
        if (fontSizeSetting == 0) {
            font = Graphics.FONT_SMALL;
        } else if (fontSizeSetting == 2) {
            font = Graphics.FONT_LARGE;
        } else if (fontSizeSetting == 3) {
            font = Graphics.FONT_NUMBER_MILD;
        }
        var smallFont = Graphics.FONT_TINY;

        // Build time string
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var is12h = false;
        if (timeFormat == 1) {
            is12h = true;
        } else if (timeFormat == 0 && !System.getDeviceSettings().is24Hour) {
            is12h = true;
        }
        var ampm = "";
        if (is12h) {
            ampm = hours >= 12 ? " PM" : " AM";
            hours = hours % 12;
            if (hours == 0) { hours = 12; }
        }
        var timeString;
        if (showSeconds && !_sleeping) {
            timeString = Lang.format("$1$:$2$:$3$", [hours, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]);
        } else {
            timeString = Lang.format("$1$:$2$", [hours, clockTime.min.format("%02d")]);
        }
        if (is12h) {
            timeString = timeString + ampm;
        }

        // Build date string
        var dateString = "";
        if (showDate) {
            var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            if (dateFormat == 0) {
                dateString = Lang.format("$1$ $2$ $3$", [now.day_of_week, now.month, now.day]);
            } else if (dateFormat == 1) {
                dateString = Lang.format("$1$ $2$", [now.month, now.day]);
            } else {
                dateString = Lang.format("$1$ $2$", [now.day, now.month]);
            }
        }

        // Build bottom info line
        var infoItems = [];
        if (showBbValue && bbCurrent > 0) {
            infoItems.add(bbCurrent.toString() + "%");
        }
        if (showSteps) {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                infoItems.add(info.steps.toString() + " steps");
            }
        }
        if (showHeartRate) {
            var hrIter = SensorHistory.getHeartRateHistory({:period => new Time.Duration(60)});
            if (hrIter != null) {
                var hrSample = hrIter.next();
                if (hrSample != null && hrSample.data != null) {
                    var hr = hrSample.data.toNumber();
                    if (hr > 0) {
                        infoItems.add(hr.toString() + " bpm");
                    }
                }
            }
        }
        if (showDeviceBattery) {
            var stats = System.getSystemStats();
            infoItems.add(stats.battery.toNumber().toString() + "%");
        }

        // Calculate vertical layout
        var fontH = dc.getFontHeight(font);
        var smallFontH = dc.getFontHeight(smallFont);
        var lineCount = 1; // time always shown
        if (showDate) { lineCount++; }
        var hasInfo = infoItems.size() > 0;
        var totalH = lineCount * fontH;
        if (hasInfo) { totalH += smallFontH; }
        var topY = cy - totalH / 2;
        var textX = cx;
        var currentY = topY;

        // Draw date
        if (showDate) {
            drawOutlinedText(dc, textX, currentY, font, dateString, textColor);
            currentY += fontH;
        }

        // Draw time
        drawOutlinedText(dc, textX, currentY, font, timeString, textColor);
        currentY += fontH;

        // Draw info line
        if (hasInfo) {
            var infoString = "";
            for (var i = 0; i < infoItems.size(); i++) {
                if (i > 0) { infoString = infoString + "  "; }
                infoString = infoString + infoItems[i];
            }
            drawOutlinedText(dc, textX, currentY, smallFont, infoString, textColor);
        }
    }

    function drawOutlinedText(dc as Dc, x as Number, y as Number, font, text as String, color as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var ox = -1; ox <= 1; ox++) {
            for (var oy = -1; oy <= 1; oy++) {
                if (ox != 0 || oy != 0) {
                    dc.drawText(x + ox, y + oy, font, text, Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

}
