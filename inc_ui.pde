/*
 * SlitScanner
 * by Eduardo Morais - www.eduardomorais.pt
 */

/*
 * UI
 */


class UI {

    /*
     * Properties
     */

    // buttons:
    String files[]   = {"stopped", "pip",    "scroll", "dir",    "axis",   "save",  "folder",  "live",  "load",  "png"};

    // positions:
    int offsets[][]  = {{10,5},    {275,5},  {370,5},  {455,5},  {520,5},  {670,5}, {590,5},   {190,5}, {105,5}, {630,5}};

    // assets folder:
    String assetsDir = "ui/";

    PGraphics buffer;
    int posX, posY;
    PImage images[];



    /*
     * Constructor
     * (width, height)
     */
    UI(int w, int h) {
        buffer = createGraphics(w, h);
        images = new PImage[files.length];

        prepare();

        posX = (width - w) / 2;
        posY = (height - h) - 30;
    }


    /*
     * Load and prepare buttons:
     */
    void prepare() {
        for (int i = 0; i < files.length; i++) {
            images[i] = loadImage(assetsDir+files[i]+".png");
            if (
            (files[i] == "pip" && $pip) ||
            (files[i] == "scroll" && $scroll) ||
            (files[i] == "dir" && $scrollDir) ||
            (files[i] == "stopped" && $stopped) ||
            (files[i] == "axis" && $vertical) ||
            (files[i] == "live" && $live) ||
            (files[i] == "png" && $savePNG)
            ) {
                images[i] = loadImage(assetsDir+files[i]+"_on.png");
            }
            else if (
            (files[i] == "live" && $camNum < 1)
            ) {
                images[i] = loadImage(assetsDir+files[i]+"_disabled.png");
            }
        }
    }


    /*
     * Render UI:
     */
    void show() {
        // only if mouse over the window:
        if (mouseX > 20 && mouseX < width-20 && mouseY > 20 && mouseY < height-20) {

            // Draw buttons:
            buffer.beginDraw();
            buffer.background(0, 128);

            int s = 0; // mouse cursor? 1 or more points for hand

            for (int i = 0; i < files.length; i++) {
                buffer.image(images[i], offsets[i][0], offsets[i][1]);
                if (isOver(i)) {
                    // exclude these:
                    if (
                    (files[i] == "live" && ($camNum < 1 || $live))
                    ) {
                        continue;
                    }
                    // position button:
                    buffer.image(images[i], offsets[i][0], offsets[i][1]);
                    s++;
                }
            }

            if (s > 0) {
                cursor(HAND);
            } else {
                cursor(ARROW);
            }

            // position UI:
            buffer.endDraw();
            image(buffer, posX, posY);
        }
    }

    /*
     * Mouse over image #?
     */
    boolean isOver(int off) {
        // find out where that button is:
        int offX = offsets[off][0];
        int offY = posY + offsets[off][1];
        offX = offX + posX;

        if (mouseX > offX && mouseX < images[off].width+offX && mouseY > offY && mouseY < images[off].height+offY) {
            return true;
        }
        return false;
    }

} // end class UI


/*
 * Mouse Clicked
 */
void mouseClicked() {

    // pause
    if ($ui.isOver(0)) {
        $stopped = !$stopped;
    }

    // camera preview
    if ($ui.isOver(1)) {
        $pip = !$pip;
    }

    // scroll
    if ($ui.isOver(2)) {
        $buffer.background(0);
        $scroll = !$scroll;
    }

    // direction
    if ($ui.isOver(3)) {
        $scrollDir = !$scrollDir;
        $direction = 0 - $direction;
        $drawPos = 0;
    }

    // axis
    if ($ui.isOver(4)) {
        $vertical = !$vertical;
        prepareBuffer();
    }

    // save
    if ($ui.isOver(5)) {
        image($buffer, 0, 0, width, height);
        saveImage();
        $saving = true;
    }

    // select save folder
    if ($ui.isOver(6)) {
        selectFolder("Where do you want to save images?", "folderSelected");
    }
    
    // camera mode
    if ($ui.isOver(7)) {
        if ($camNum > 0 && !$live) {
            prepareCamera();
            prepareBuffer();
        }
    }
    
    // video file mode
    if ($ui.isOver(8)) {
        selectInput("Select a video file:", "selectVideo");
    }
    
    // select JPEG/PNG
    if ($ui.isOver(9)) {
        $savePNG = !$savePNG;
        $msgs = $savePNG ? "Images will be saved as PNG" : "Images will be saved as JPEG";
    }
    
    // get rid of help on click:
    $showHelp = false;

    // redraw:
    $ui.prepare();
}


/*
 * Drag & drop
 */
void dropEvent(DropEvent dropped) {
    if (dropped.isFile()) {
        $dragged = true;
        selectVideo(dropped.file());
    }
}
