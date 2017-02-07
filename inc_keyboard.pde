/*
 * SlitScanner
 * by Eduardo Morais - www.eduardomorais.pt
 */

/*
 * Keyboard
 */

void keyReleased() {
  
    // camera mode
    if (key == 'c' || key == 'C') {
        if ($camNum > 0 && !$live) {
            prepareCamera();
            prepareBuffer();
        }
    }

    // video file mode
    if (key == 'o' || key == 'O') {
        selectInput("Select a video file:", "selectVideo");
    }

    // camera preview
    if (key == 'v' || key == 'V') {
        $pip = !$pip;
    }

    // scroll mode
    if (key == 'm' || key == 'M') {
        $buffer.background(0);
        $scroll = !$scroll;
    }

    // direction
    if (key == 'd' || key == 'D') {
        $buffer.background(0);
        $scrollDir = !$scrollDir;
        $direction = 0 - $direction;
        $drawPos = 0;
    }

    // pause
    if (key == ' ') {
        $stopped = !$stopped;
    }

    // orientation
    if (key == 'a' || key == 'A') {
        $vertical = !$vertical;
        prepareBuffer();
    }

    // save png
    if (key == 'S' || key == 's') {
        image($buffer, 0, 0, width, height);
        saveImage();
        $saving = true;
    }

    // select save folder
    if (key == 'F' || key == 'f') {
        selectFolder("Where do you want to save images?", "folderSelected");
    }
    
    // select JPEG/PNG
    if (key == 'g' || key == 'G') {
        $savePNG = !$savePNG;
        $msgs = $savePNG ? "Images will be saved as PNG" : "Images will be saved as JPEG";
    }

    // show/hide UI
    if (key == 'h' || key == 'H') {
        $uiShow = !$uiShow;
        if (!$uiShow) {
            noCursor();
        }
    }


    if (key == CODED) {

        // show help:
        if (keyCode == KeyEvent.VK_F1) {
            $showHelp = !$showHelp;
            image($buffer, 0, 0, width, height);
        }
        
        $pressing = false;
        // move scan position
        if (keyCode == LEFT || keyCode == RIGHT || keyCode == UP || keyCode== DOWN) {
            // controls whether to overlay camera preview:
            
        }
    }

    // redraw UI
    $ui.prepare();
}



/*
 * KEY PRESSED
 */
void keyPressed() {

    // move scan position
    if (key == CODED) {
        if ((keyCode == LEFT && !$vertical)
        || (keyCode == UP && $vertical)) {
            $pressing = true;
            $scanPos--;
            if ($scanPos <10) {
                $scanPos = 5;
            }
        }

        if (keyCode == RIGHT && !$vertical) {
            $pressing = true;
            $scanPos++;
            if ($scanPos > $feed.width-10) {
                $scanPos = $feed.width-5;
            }
        }

        if (keyCode == DOWN && $vertical) {
            $pressing = true;
            $scanPos++;
            if ($scanPos > $feed.height-10) {
                $scanPos = $feed.height-5;
            }
        }
        
        // scanning stepping
        if (keyCode == KeyEvent.VK_PAGE_DOWN) {
            if ($stepping < 100) {
                $stepping++;
                $msgs = "Scanning every "+$stepping+" frames";
            }

        }
        if (keyCode == KeyEvent.VK_PAGE_UP) {
            if ($stepping > 1) {
                $stepping--;
                $msgs = $stepping > 1 ? "Scanning every "+$stepping+" frames" : "";
            }
        }
        
        // get rid of help on keys:
        if (keyCode != KeyEvent.VK_F1) {
            $showHelp = false;
        }
    } else {
        $showHelp = false;
    }   
}

