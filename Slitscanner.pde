/*
 *   ____  _     _  _____  ____  ____   ____   __  _  __  _  ____ _____ 
 *  (_ (_`| |__ | ||_   _|(_ (_`/ (__` / () \ |  \| ||  \| || ===|| () )
 * .__)__)|____||_|  |_| .__)__)\____)/__/\__\|_|\__||_|\__||____||_|\_\
 * 
 * by Eduardo Morais 2012-2021 - www.eduardomorais.pt
 *
 */


// Libs
import processing.video.*;
import drop.*;
import test.*;
// needed by 2.08+
import java.util.*;
import java.text.*;
import java.awt.event.KeyEvent;

// GLOBALS (denoted by $)
String $version = "1.4";

int $windowWidth = 854;
int $windowHeight = 480;  // screen size
int $drawPos;  // draw X postion
int $direction;  // drawing direction (1 / -1)

Capture $cam;  // camera object
Movie $video;
PImage $feed;
SDrop $drop; // drag and drop object

int $capWidth = 640;
int $capHeight = 480;  // capture dimensions
int $scanPos;  // line to capture
color $pxl;  // a pixel

// default options:
boolean $live = true;
boolean $pip = false;
boolean $scroll = false;
boolean $scrollDir = false;
boolean $vertical = false;
boolean $uiShow = true;
boolean $stopped = false;
String $saveFolder = "Saved Images";
boolean $savePNG = true;

// allowed video file extensions:
String[] $videoExts = {"mov", "avi", "mp4", "mpg", "mpeg"};

// control flags:
boolean $saving = false;
boolean $pressing = false;
boolean $dragged = false;
boolean $showHelp = false;
int $camNum = 0;
String $videoFile;
int $stepping = 1;
int $cycle = 0;

PGraphics $buffer, $help;  // scanned image buffer
UI $ui;  // ui object

String $helpText;
String $msgs;
int $msgCycle = 0;
String $fontName = "ui/type/leaguegothic-regular.ttf";
PFont $font, $defaultFont;


/*
 * SETUP
 */
void setup() {
    size(800,400);

    // try to load config file:
    Config cfg = new Config();

    try {
        // load a configuration from a file inside the data folder
        InputStream cf = createInput("config.txt");
        if (cf != null) {
            cfg.load(cf);

            // all values returned by the getProperty() method are Strings
            // so we need to cast them into the appropriate type ourselves
            // this is done for us by the convenience Config class

            $windowWidth       = cfg.getInt("win.width", $windowWidth);
            $windowHeight      = cfg.getInt("win.height", $windowHeight);
            $capWidth          = cfg.getInt("cap.width", $capWidth);
            $capHeight         = cfg.getInt("cap.height", $capHeight);

            $scroll            = cfg.getBoolean("opt.scroll", $scroll);
            $pip               = cfg.getBoolean("opt.pip", $pip);
            $scrollDir         = cfg.getBoolean("opt.left_to_right", $scrollDir);
            $vertical          = cfg.getBoolean("opt.left_to_right", $vertical);

            $uiShow            = cfg.getBoolean("ui.show", $uiShow);

            $saveFolder        = cfg.getString("opt.save", $saveFolder);
            $savePNG           = cfg.getBoolean("opt.png", $savePNG);
        }
    } catch(IOException e) {
        println("couldn't read config file...");
    }

    // set screen:
    $windowWidth = $windowWidth < 800 ? 800 : $windowWidth;
    $windowHeight = $windowHeight < 480 ? 480 : $windowHeight;
    surface.setSize($windowWidth, $windowHeight);
    surface.setTitle("Slitscanner "+$version+" >>> press F1 for help");
    $defaultFont = createFont($fontName, 20, true);
    smooth();
    background(0);

    // initialise GUI:
    $ui = new UI(760, 50);
    if (!$uiShow) {
        noCursor();
    }
    $drop = new SDrop(this);

    // initialise camera:
    $camNum = Capture.list().length;

    if ($live && $camNum > 0) {
        // prepare camera and initialise scanned image buffer:
        prepareCamera();
        prepareBuffer();
    } else {
        // load a file:
        selectInput("Select a video file:", "selectVideo");
        prepareBuffer();
    }

    $drawPos = 0;
    $direction = $scrollDir ? 1 : -1;


    //
    // prepare Help
    //
    $help = createGraphics(760, 400);
    $help.beginDraw();
    $help.background(0, 128);
    $font = createFont($fontName, 48, true);
    $help.fill(255);
    $help.textFont($font, 48);
    $help.text("SLITSCANNER", 19, 60);
    float hw = $help.textWidth("SLITSCANNER");

    $font = createFont($fontName, 20, true);
    $help.fill(255, 128);
    $help.textFont($font, 20);
    $help.text($version, hw+25, 60);

    $font = createFont($fontName, 20, true);
    $help.fill(255);
    $help.textFont($font, 20);
    hw = $help.textWidth("EDUARDO MORAIS 2012-2013");
    $help.text("EDUARDO MORAIS 2012-2013", $help.width-20-hw, 40);


    $help.fill(#FF9933);
    $help.textFont($font, 20);
    hw = $help.textWidth("WWW.EDUARDOMORAIS.PT");
    $help.text("WWW.EDUARDOMORAIS.PT", $help.width-20-hw, 60);

    $help.stroke(#FF9933, 192);
    $help.line(20, 72, $help.width-20, 72);

    $help.textFont($defaultFont, 20);
    $help.fill(255, 192);

    $helpText =
          "[ C ]  Live camera mode\n"+
          "[ O ]  Open video file\n"+
          "[ S ]  Save image\n"+
          "[ F ]  Select saved images folder\n"+
          "[ G ]  Toggle saving images as JPEG / PNG\n\n"+
          "[ V ]  Toggle viewfinder display\n"+
          "[ H ]  Toggle on-screen user interface";
    $help.text($helpText, 20, 110);

    $helpText =
          "[ M ]  Toggle static / scrolling mode\n"+
          "[ D ]  Toggle scanning direction\n"+
          "[ A ]  Toggle vertical / horizontal axis\n\n"+
          "[ SPACE BAR ]  Pause / resume scanning\n"+
          "[ ARROW KEYS ]  Adjust scan line\n"+
          "[ PG UP/DOWN ]  Adjust scanning speed\n\n"+

          "[ F 1 ]  Show keyboard shortcuts";
    $help.text($helpText, 400, 110);
    $help.endDraw();

    textFont($defaultFont, 20);
}
