/*
 * SlitScanner
 * by Eduardo Morais 2012 - www.eduardomorais.pt
 *
 */

/*
 * PREPARE WEBCAM
 */
void prepareCamera() {
    if ($camNum > 0) {
        $cam = new Capture(this, $capWidth, $capHeight);
        $cam.start();   
        $feed = $cam;
        $live = true;
        if ($video != null) {
            $video.stop(); 
        }
        $ui.prepare();
        $msgs = "Live camera feed";
    }
}


/*
 * PREPARE VIDEO FILE
 */
void prepareVideo() {
    if ($videoFile != null) {
        if ($video != null) {
            $video.stop(); 
        }
        $video = new Movie(this, $videoFile);
        $video.jump(0);
        $video.loop();
        $video.play();
        $video.read(); // we need to know its size before calling prepareBuffer()
        $feed = $video;
        $live = false;        
        if ($cam != null) {
            $cam.stop(); 
        }
    }
}


/*
 * Select video file
 */
void selectVideo(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        $videoFile = null;
    } else {
        println("User selected " + selection.getAbsolutePath());
        String fn = selection.getName();
        String fext = fn.substring(fn.lastIndexOf(".") + 1, fn.length());
        String ext;
        boolean ok = false;
        
        for (int i = 0; i < $videoExts.length; i++) {
            ext = $videoExts[i];
            if (ext.equalsIgnoreCase(fext)) {
                ok = true;
                break;      
            }
        }
        
        if (ok) {
            $videoFile = selection.getAbsolutePath();
            boolean s = $stopped;
            $stopped = true;
            prepareVideo();
            prepareBuffer();
            $stopped = s;
            $ui.prepare();
            $msgs = "Loaded " + $videoFile;
        } else if (!$dragged) {
            selectInput("Please select a supported video file...", "selectVideo"); 
        }
    }
    $dragged = false;
}


/*
 * PREPARE DRAWING BUFFER
 */
void prepareBuffer() {
    int fw = width;
    int fh = height;
  
    if ($feed != null && $feed.width > 0 && $feed.height > 0) {
        fw = $feed.width;
        fh = $feed.height;
    }
  
    if ($vertical) { // vertical scanning
        $buffer = createGraphics(width, fw);
        $scanPos = fh/2;
    } else { // horizontal scanning
        $buffer = createGraphics(width, fh);
        $scanPos = fw/2;
    }
    $buffer.beginDraw();
    $buffer.background(0);
    $buffer.endDraw();
}


/*
 * Select Folder
 */
void folderSelected(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
    } else {
        println("User selected " + selection.getAbsolutePath());
        $saveFolder = selection.getAbsolutePath();
        $msgs = "Selected save folder " + $saveFolder;
    }
}


/*
 * Save image with the date in the filename
 */
void saveImage() {
    String ff = $savePNG ? ".png" : ".jpg";
    Date now = new Date();
    SimpleDateFormat df = new SimpleDateFormat("yyyyMMdd_hhmmss");
    save($saveFolder+"/scan_" + df.format(now) + ff);
    $msgs = "Saved image";
}


/*
 * DRAW
 */
void draw() {
    
    boolean ok = false; 
  
    if ($live && $cam != null && $cam.available()) {
        ok = true;
        $cam.read(); 
    } else if ($video != null && $video.available()) {
        ok = true;
        $video.read();
    }
  
    if (ok) {
        
        // step counter:
        $cycle++;
        if ($cycle % $stepping == 0) {
            // reset cycle:
            $cycle = 0;
          
            $feed.loadPixels();
            $buffer.beginDraw();
            $buffer.loadPixels();
    
            if ($scroll && !$stopped) {
            // scroll the entire buffer:
    
                if ($direction > 0) {
                    $drawPos = $buffer.width - 1;
                } else {
                    $drawPos = 0;
                }
    
                for (int iy = 0; iy < $buffer.height; iy++) {
    
                    if ($direction > 0) {
                        // scroll right:
                        for (int ix = 0; ix < $buffer.width-1; ix++) {
                            $pxl = $buffer.pixels[iy*$buffer.width+ix+1];
                            $buffer.pixels[iy*$buffer.width+ix] = $pxl;
                        }
                    } else {
                        // scroll left:
                        for (int ix = $buffer.width-1; ix > 0; ix--) {
                            $pxl = $buffer.pixels[iy*$buffer.width+ix-1];
                            $buffer.pixels[iy*$buffer.width+ix] = $pxl;
                        }
                    }
                }
    
            } else if (!$stopped) {
            // not scrolling:
    
                $drawPos = $drawPos + $direction;
    
                // wrap around:
                if ($drawPos >= $buffer.width) {
                    $drawPos = 1;
                }
                if ($drawPos <= 0) {
                    $drawPos = $buffer.width-1;
                }
            }
    
            if (!$stopped) {
             // get the scanline:
    
                int scanEnd = $vertical ? $feed.width : $feed.height;
                for (int i = 0; i < scanEnd; i++) {
                    if ($vertical) {
                        $pxl = $feed.pixels[$scanPos*$feed.width+i];
                    } else {
                        $pxl = $feed.pixels[i*$feed.width+$scanPos];
                    }
    
                    // draw the scanline:
                    $buffer.pixels[i*$buffer.width+$drawPos] = $pxl;
                }
            }
    
            // draw buffer:
            $buffer.updatePixels();
            $buffer.endDraw();            
        
        } // end step counter
        
        // draw buffer:
        image($buffer, 0, 0, width, height);

        // show picture-in-picture (cam preview):
        if ($pip || $pressing) {
            float pos = 20;
            float cw = width/4;
            float ch = ($feed.height/float($feed.width))*(width/4);
            image($feed, pos, pos, cw, ch);

            // draw scanline:
            stroke(#FF9933, 128);
            if ($vertical) {
                float cy = map($scanPos, 0, $feed.height, 0, ch);
                line(pos, pos+cy, cw+pos-1, pos+cy);
            } else {
                float cx = map($scanPos, 0, $feed.width, 0, cw);
                line(cx+pos, pos, cx+pos, ch+pos-1);
            }
           
        } 
        
        // draw messages:
        if ($msgCycle < 50 && $msgs != "") {
            fill(255);
            float tw = textWidth($msgs);
            text($msgs, width-20-tw, 36);
            $msgCycle++;
        } else {
            // clear messages:
            $msgs = "";
            $msgCycle = 0;
        }
        
        // flash screen on save:
        if ($saving) {
            background(255);
            $saving = false;
        }
        
        // show UI:
        if ($uiShow) {
            $ui.show();
        }
    
        // show help overlay:
        if ($showHelp) {
            image($help, (width-$help.width)/2, (height-$help.height)/2-40);
        }
    }
    
    if ($feed == null) {
        background(0);
        $ui.show();
        if ($showHelp) {
            image($help, (width-$help.width)/2, (height-$help.height)/2-40);
        }
    }
}


