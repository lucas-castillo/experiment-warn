<slider-practice>
    <style>
        div#instructions{
            font-size: 22px;
            padding: 20px;
        }
        .psychErrorMessage{ /*override style*/
            font-size: 23px;
            text-align: center;
        }
        label {
            font-size: 20px;
        }
        span.dot {
            background-color: #d442422e;
            width: 78px;
            height: 46px;
            border-radius: 50%;
            display: inline-block;
            visibility: hidden;
            z-index: -1;
            position: relative;
            bottom: 32px;
        }
    </style>

    <div id = "instructions" ref="instructionText"> {instructions} </div>

    <div>
        <canvas width="950" height="400" style="border: solid black 2px" ref="myCanvas"></canvas>
        <div style="width: 950px">
            <label for="slider">Early</label>
            <label for="slider" style="float: right">Late</label>
        </div>
        <div class="slidecontainer" id="sliderCont">
            <input id = "slider" onmouseup="{sliderMouseUp}" type="range" min="1" max="200" value="100" class="slider" style="width:950px; z-index: 0" ref="mySlider">
            <span class="dot" ref="myPrompt"></span>
        </div>
        <br>
        <p class="psychErrorMessage" show="{hasErrors}" >{errorText}</p>
    </div>
    <script>
        var self = this;
        self.instructions = "Try making the screen flash as early as possible and press Next";
        self.errorText = "Try to move the slider more to the left so that the flash appears earlier";
        self.currentMoment = 0;
        self.timeStamps = [];

        self.resultDict = {"sliderTouches": [0,0,0], "nextAttempts": 0}; // nextAttempts = 3 for a perfect participant
        // define what a moving display is - common to all .tags (see inner starting comments for minor changes according to tag needs)
        self.MovingDisplay = function (colours, mirroring, launchTiming, extraObjs, squareDimensions, canvas, slider = null, speed, showFlash = false) {
            // What's different about this Moving Display?
            // no hole in blue square!
            var display = this;

            // def functions

            display.Square = function (colour, dimensions) {
                var sq = this;
                // colour
                sq.colourName = colour;
                switch (sq.colourName) {
                    case "red":
                        sq.colour = "#FF0000";
                        break;
                    case "green":
                        sq.colour = "#00FF00";
                        break;
                    case "blue":
                        sq.colour = "#0000FF";
                        break;
                    case "black":
                        sq.colour = "#000000";
                        break;
                    case "hidden":
                        sq.colour = "#FFFFFF";
                        break;
                    case "purple":
                        sq.colour = "#ec00f0";
                        break;
                }
                // geometry
                sq.dimensions = dimensions;
                sq.startPosition = [0, 0];
                sq.finalPosition = [0, 0];
                sq.moveAt = 0;
                sq.movedAt = -1; // the time it actually moved
                sq.position = [0, 0];
                sq.duration = 0;

                sq.animationTimer = 0;
                sq.pixelsPerStep = [0, 0];



                sq.draw = function (canvas, step) {
                    var myStep = Math.max(0, step - sq.moveAt);

                    if (myStep < sq.duration) {
                        sq.position[0] = sq.startPosition[0] + sq.pixelsPerStep[0] * myStep;
                        sq.position[1] = sq.startPosition[1] + sq.pixelsPerStep[1] * myStep;
                    } else {
                        sq.position[0] = sq.finalPosition[0];
                        sq.position[1] = sq.finalPosition[1];
                    }

                    sq.obedientDraw(canvas);


                    if (sq.movedAt === -1 && myStep > 0) {
                        sq.movedAt = step;
                    }
                };

                sq.obedientDraw = function (canvas) {
                    // draws sq in its position, without asking questions! useful sometimes
                    var ctx = canvas.getContext("2d");
                    ctx.fillStyle = sq.colour;
                    ctx.fillRect(sq.position[0], sq.position[1], sq.dimensions[0], sq.dimensions[1]);
                };


                sq.reset = function () {
                    sq.movedAt = -1;
                    sq.position = sq.startPosition.slice();
                    sq.pixelsPerStep = [(sq.finalPosition[0] - sq.startPosition[0]) / sq.duration,
                        (sq.finalPosition[1] - sq.startPosition[1]) / sq.duration];
                };

            };

            display.placeSquares = function () {
                for (var i = 0; i < 3; i++) {
                    var newSquare, squareColour;
                    squareColour = display.colours[i];
                    newSquare = new display.Square(squareColour, display.squareDimensions);
                    display.squareList.push(newSquare);
                }
                display.setUp();
            };
            display.setUp = function () {
                var canvasMargin = display.canvas.width / 4;

                for (var i = 0; i < 3; i++) {
                    // start/end positions
                    var square = display.squareList[i];
                    var sqWidth = display.squareDimensions[0];
                    var startPosition, endPosition;
                    if (i === 0) {
                        startPosition = display.mirrored ? canvasMargin + 5 * sqWidth : canvasMargin;
                        endPosition = display.mirrored ? startPosition - 2.5 * sqWidth : canvasMargin + 2.5 *
                            sqWidth;
                    } else {
                        var distanceTravelled = sqWidth + 2 * sqWidth * (i - 1);
                        startPosition = display.mirrored ?
                            display.squareList[0].finalPosition[0] - distanceTravelled: // if mirrored travel left from A
                            display.squareList[0].finalPosition[0] + distanceTravelled; // if not travel right
                        endPosition = display.mirrored ?
                            startPosition - sqWidth : // same idea
                            startPosition + sqWidth;
                    }
                    square.startPosition = [startPosition, 100];
                    square.finalPosition = [endPosition, 100];

                    // duration
                    square.duration = Math.abs(endPosition - startPosition) / display.speed;
                    display.durations.push(square.duration);
                }
                display.draw();

                // give "move At" instructions
                if (display.launchTiming === "canonical") {
                    display.squareList[0].moveAt = 0;
                    display.squareList[1].moveAt = display.squareList[0].duration;
                    display.squareList[2].moveAt = display.squareList[1].moveAt + display.squareList[1].duration;
                } else {
                    display.squareList[0].moveAt = 0;
                    display.squareList[2].moveAt = display.squareList[0].duration;
                    display.squareList[1].moveAt = display.squareList[2].moveAt + display.squareList[2].duration;
                }
            };
            display.reset = function () {
                // reset squares to startPosition
                for (var i = 0; i < 3; i++) {
                    display.squareList[i].reset();
                }
                // reset other animation markers
                display.flashOnset = -1;
                display.animationStarted = Infinity;
                display.animationEnded = false;
            };


            display.startAnimation = function () {
                display.animationStarted = Date.now();
                window.requestAnimationFrame(display.draw.bind(display));
            };
            display.endAnimation = function () {
                display.animationEnded = Date.now();
            };

            display.animate = function (startAt = 1000) {
                // stop timeouts
                for (var i = 0; i < display.animationTimer.length; i++) {
                    clearTimeout(display.animationTimer[i])
                }
                //
                // these two put everything back to start
                display.reset();
                display.draw();
                // and this starts the timing
                display.setTimeouts(startAt);
            };

            display.getLastFinish = function () {
                // get list of when each sq finishes moving
                var finishTimings = [];
                for (var i = 0; i < 3; i++) {
                    if (display.squareList[i].colourName !== "hidden") {
                        finishTimings.push((display.squareList[i].moveAt + display.squareList[i].duration));
                    }
                };
                // and what time is last
                return Math.max.apply(null, finishTimings);
            };

            display.setTimeouts = function (startInstructions = 1000) {
                // get list of when each sq finishes moving
                var finishTimings = display.squareList.map(function (obj) {
                    return obj.moveAt + obj.duration
                });
                var lastFinish = Math.max.apply(null, finishTimings); // and what time is last
                var startAt = startInstructions; // some external callings may want no delay when starting (e.g. check training tags). 1000ms lets page load up
                var timeoutId;  //  start timeouts for start and end and add to a list (which allows to stop everything if animation restarted, see self.animate())
                timeoutId = setTimeout(display.startAnimation.bind(display), startAt);
                display.animationTimer.push(timeoutId);
                timeoutId = setTimeout(display.endAnimation.bind(display), startAt + lastFinish);
                display.animationTimer.push(timeoutId);
                // timings for flash
                if (display.showFlash) {
                    var animationSpace = lastFinish + 1000; // add 1000s so one can set flash after lastFinish
                    var flashTime =  startAt - 750 + animationSpace / 200 * display.slider.value; // if slider.value == 0 flash 750ms before red starts moving (250ms after animation start).
                    // 0 ----------------------- 250 --------------------- 1000 ---------------------------- lastFinish ---------------- lastFinish + 1000 -----> // time arrow (ms)
                    //(animationStart) --- (earliestPossibleFlash) ------(startAt: red starts moving) -----(lastSquare stops moving) --(last possible Flash) --->

                    timeoutId = setTimeout(display.displayFlash.bind(display), flashTime);
                    display.animationTimer.push(timeoutId);
                    timeoutId = setTimeout(display.displayFlash.bind(display), flashTime + 25); // this makes the flash 25ms long
                    display.animationTimer.push(timeoutId);
                }
            };
            display.draw = function () {
                // empty canvas
                var ctx = display.canvas.getContext("2d");
                ctx.clearRect(0, 0, display.canvas.width, display.canvas.height);
                // draw squares
                var step = Date.now() - display.animationStarted;
                for (var i = 0; i < display.squareList.length; i++) {
                    display.squareList[i].draw(display.canvas, step);
                }

                // // draw the hole for middle third of the B square
                // if (display.squareList[1].colourName !== "hidden") {
                //     ctx.fillStyle = display.holeColour;
                //     ctx.fillRect(
                //         display.squareList[1].position[0],
                //         display.squareList[1].position[1] + 1 / 3 * display.squareList[1].dimensions[1],
                //         display.squareList[1].dimensions[0],
                //         1 / 3 * display.squareList[1].dimensions[1]
                //     );
                // }

                if (display.extraObjs) {
                    display.drawExtraObjects()
                }
                if (!display.animationEnded) {
                    window.requestAnimationFrame(display.draw.bind(display));
                }
            };
            display.drawExtraObjects = function () {
                var ctx = display.canvas.getContext('2d');
                // some vars to make more legible
                var squareA = display.squareList[0];
                var squareB = display.squareList[1];
                var squareC = display.squareList[2];

                // stick
                if (display.squareList[0].colourName !== "hidden") {
                    var stickSize = squareA.dimensions[0] * 2.5;

                    var startX, endX;
                    if (display.mirrored) {
                        startX = squareA.position[0];
                        endX = startX - stickSize;
                    } else {
                        startX = squareA.position[0] + squareA.dimensions[0];
                        endX = startX + stickSize;
                    }

                    // horizontal line
                    ctx.beginPath();
                    ctx.moveTo(startX, squareA.position[1] + 0.5 * squareA.dimensions[1]);
                    ctx.lineTo(endX,squareA.position[1] + 0.5 * squareA.dimensions[1]);
                    ctx.stroke();
                    // vertical line
                    ctx.beginPath();
                    ctx.moveTo(endX, squareA.position[1] + 0.5 * squareA.dimensions[1] - 5);
                    ctx.lineTo(endX, squareA.position[1] + 0.5 * squareA.dimensions[1] + 5);
                    ctx.stroke();
                }

                // draw chain
                if (display.squareList[1].colourName !== "hidden" && display.squareList[2].colourName !== "hidden") {
                    var squareBMiddleX, squareBY, squareCMiddleX, squareCY;
                    squareBMiddleX = squareB.position[0] + squareB.dimensions[0] * 1 / 2;
                    squareCMiddleX = squareC.position[0] + squareC.dimensions[0] * 1 / 2;
                    squareBY = squareB.position[1] + squareB.dimensions[1] * 9 / 10;
                    squareCY = squareC.position[1] + squareC.dimensions[1] * 9 / 10;

                    var distanceBetweenSquares, squareMiddlePoint;
                    distanceBetweenSquares = Math.abs(squareBMiddleX - squareCMiddleX);
                    squareMiddlePoint = display.mirrored ?
                        distanceBetweenSquares / 2 + squareCMiddleX :
                        distanceBetweenSquares / 2 + squareBMiddleX;

                    var controlPointY = squareB.position[1] + squareB.dimensions[1] + 120 - 0.75 * distanceBetweenSquares;

                    // chain is Q bezier curve defined by points (squareBMiddleX, squareBY), (squareMiddlePoint, controlPointY) and (squareCMiddleX, squareBY)
                    ctx.beginPath();
                    ctx.moveTo(squareBMiddleX, squareBY);
                    ctx.quadraticCurveTo(squareMiddlePoint, controlPointY, squareCMiddleX, squareCY);
                    ctx.stroke();
                }

                // wall
                if (display.drawWall) {
                    var wallX;
                    var wallY = display.squareList[2].startPosition[1] - display.squareDimensions[1];
                    var wallWidth = 1 * display.squareDimensions[1];
                    var wallHeight = 3 * display.squareDimensions[1];
                    if (self.mirroring) {
                        wallX = display.squareList[2].startPosition[0] + display.squareDimensions[0] - wallWidth - 1;
                    } else {
                        wallX = display.squareList[2].startPosition[0] + 1;
                    }

                    // ctx.beginPath();
                    // ctx.rect(wallX, wallY, wallWidth, wallHeight);
                    // ctx.stroke();
                    ctx.fillStyle = "#c87630";
                    ctx.fillRect(wallX, wallY, wallWidth, wallHeight);
                    // bricks
                    var brickWidth = wallWidth / 3;
                    var brickHeight = wallHeight / 10;
                    for (var r = 0; r < 10; r++) {
                        if (r !== 0) {
                            // hor lines
                            ctx.beginPath();
                            ctx.moveTo(wallX, wallY + r * brickHeight);
                            ctx.lineTo(wallX + wallWidth, wallY + r * brickHeight);
                            ctx.stroke();
                        }
                        if (r % 2 === 0) {
                            for (var c = 0; c < 3; c++) {
                                if (c !== 0) {
                                    ctx.beginPath();
                                    ctx.moveTo(wallX + c * brickWidth, wallY + r * brickHeight);
                                    ctx.lineTo(wallX + c * brickWidth, wallY + (r + 1) * brickHeight);
                                    ctx.stroke();
                                }
                            }
                        } else {
                            for (var c = 0; c < 3; c++) {
                                ctx.beginPath();
                                ctx.moveTo(wallX + (c + .5) * brickWidth, wallY + r * brickHeight);
                                ctx.lineTo(wallX + (c + .5) * brickWidth, wallY + (r + 1) * brickHeight);
                                ctx.stroke();
                            }
                        }
                    }
                }
            };
            display.displayFlash = function () {
                if (display.showFlash === true) {
                    if (display.flashState === false) {
                        display.flashOnset = Date.now();
                        display.canvas.style.backgroundColor = "black";
                        display.flashState = true;

                        // make squares black if they are hidden
                        for (var i = 0; i < display.squareList.length; i++) {
                            if (display.squareList[i].colourName === "hidden") {
                                display.squareList[i].colour = "#000000";
                                display.squareList[i].obedientDraw(display.canvas);
                            }
                        }
                    } else {
                        display.canvas.style.backgroundColor = "white";
                        display.flashState = false;
                        // make squares white again if they are hidden
                        for (var i = 0; i < display.squareList.length; i++) {
                            if (display.squareList[i].colourName === "hidden") {
                                display.squareList[i].colour = "#FFFFFF";
                                display.squareList[i].obedientDraw(display.canvas);
                            }
                        }
                    }
                    display.draw(); // avoids funky lines if animation has ended
                }
            };


            // initialize attributes
            display.colours = colours; // expressed in ABC order
            display.mirrored = mirroring;
            display.launchTiming = launchTiming;
            display.extraObjs = extraObjs;
            display.squareDimensions = squareDimensions;
            display.canvas = canvas;
            display.slider = slider;
            display.speed = speed;
            display.showFlash = showFlash;

            display.holeColour = "#d9d2a6";
            display.animationStarted = Infinity;
            display.drawWall = false;
            display.animationEnded = true;
            display.flashState = false; // is the canvas flashing at the moment?
            display.animationTimer = []; // holds all the timeout ids so cancelling is easy
            display.durations = [];
            display.squareList = [];
            display.flashOnset = -1; // time when flash starts

            display.placeSquares();
            display.reset();
        };


        // overwrite funcs
        self.onInit = function () {
            self.mirroring = self.experiment.condition.factors.mirroring;
            self.rectangle = new self.MovingDisplay(["red", "blue", "red"], self.mirroring, "canonical", false, [50, 50], self.refs.myCanvas, self.refs.mySlider, 0.3, true);
            // self.rectangle.squareList[1].moveAt = 0;
            self.rectangle.squareList[1].finalPosition[0] = self.mirroring ? self.rectangle.squareList[1].finalPosition[0] - self.rectangle.squareDimensions[0] : self.rectangle.squareList[1].finalPosition[0] + self.rectangle.squareDimensions[0];

            self.rectangle.squareList[0].startPosition = [self.rectangle.squareList[1].startPosition[0], self.rectangle.squareList[1].startPosition[1]];
            self.rectangle.squareList[0].finalPosition[0] = self.rectangle.squareList[1].finalPosition[0];
            self.rectangle.squareList[0].finalPosition[1] = self.rectangle.squareList[0].startPosition[1];

            self.rectangle.squareList[1].startPosition = [self.rectangle.squareList[1].startPosition[0], self.rectangle.squareList[1].startPosition[1] + 2 * self.rectangle.squareDimensions[1]];
            self.rectangle.squareList[1].finalPosition[0] = self.rectangle.squareList[1].finalPosition[0];
            self.rectangle.squareList[1].finalPosition[1] = self.rectangle.squareList[1].startPosition[1];

            self.rectangle.squareList[2].startPosition = [self.rectangle.squareList[1].startPosition[0], self.rectangle.squareList[1].startPosition[1] + 2 * self.rectangle.squareDimensions[1]];
            self.rectangle.squareList[2].finalPosition[0] = self.rectangle.squareList[1].finalPosition[0];
            self.rectangle.squareList[2].finalPosition[1] = self.rectangle.squareList[2].startPosition[1];

            for (var i = 0; i < 3; i++) {
                self.rectangle.squareList[i].moveAt = 400 + i * 400;
                self.rectangle.squareList[i].duration = Math.abs(self.rectangle.squareList[i].finalPosition[0] - self.rectangle.squareList[i].startPosition[0]) / self.rectangle.speed;
            }

            self.rectangle.reset();
        };
        self.onShown = function () {
            self.timeStamps.push(Date.now());
            self.rectangle.animate();
        };

        self.canLeave = function () {
            var PSS = self.rectangle.flashOnset - self.rectangle.animationStarted;
            self.resultDict["nextAttempts"]++;
            self.hasErrors = false;
            if(!self.rectangle.animationEnded || self.rectangle.flashOnset === -1) {  //  if animation hasn't ended or flash hasn't flashed
                if (self.rectangle.animationEnded && self.rectangle.flashOnset === -1) {
                    self.errorText = "Please wait to see the flash before pressing Next";
                } else if (!self.rectangle.animationEnded || self.rectangle.flashOnset === -1) {
                    self.errorText = "Please wait until the animation ends before pressing Next";
                }
                self.hasErrors = true;
                return false;
            } else if ((self.currentMoment === 0 && self.refs.mySlider.value < 20) || (self.currentMoment === 1 && self.refs.mySlider.value > 180)) {
                self.timeStamps.push(Date.now());
                self.currentMoment++;
                self.changeInstructions();
                return false;
            } else if (self.currentMoment === 2 && self.resultDict["sliderTouches"][2] !== 0) {
                self.timeStamps.push(Date.now());
                return true;
            } else {
                self.hasErrors = true;
                if (self.currentMoment === 0) {
                    self.errorText = "Try to move the slider more to the left so that the flash appears earlier. Use the blinking circle to help you.";
                    self.promptAnswer();
                } else if (self.currentMoment === 1) {
                    self.errorText = "Try to move the slider more to the right so that the flash appears later. Notice that the new instructions want you to make the flash appear as late as possible.Use the blinking circle to help you.";
                    self.promptAnswer();
                } else {
                    self.errorText = "Please rearrange the slider so that the flash appears when blue starts moving";

                }
            }
        };

        self.results = function () {
            var timeInOrderOfPresentation = [];
            // get time spent in each Stage by subtracting timestamps
            for (var i = 0; i < self.timeStamps.length; i++) {
                if (i > 0) {
                    var timeSpent = self.timeStamps[i] - self.timeStamps[i - 1];
                    timeInOrderOfPresentation.push(timeSpent);
                }
            }
            // get flashTime
            self.rectangle.flashOnset = self.rectangle.flashOnset - self.rectangle.animationStarted;
            // write in results dict
            // crucial times
            self.resultDict["blueMoved"] = self.rectangle.squareList[1].movedAt;
            self.resultDict["flashedAt"] = self.rectangle.flashOnset;
            self.resultDict["PSS"] = self.rectangle.flashOnset - self.rectangle.squareList[1].movedAt;
            self.resultDict["timeInOrderOfPresentation"] = timeInOrderOfPresentation;
            return self.resultDict;
            // slider touches = 2,1 -> participant touched slider twice when asked to sync early and once when asked late
            // nextAttempts = 2 -> participant pressed "Next" twice more than absolutely necessary (value starts at -2)
        };

        // page-specific funcs
        self.sliderMouseUp = function () {
            self.hideErrors();
            self.rectangle.animate();
            self.resultDict["sliderTouches"][self.currentMoment]++
        };

        self.changeInstructions = function () {
            if (self.currentMoment === 1) {
                self.instructions = "Excellent! Now make it flash as late as possible, then press Next. ";
                self.startTime = Date.now();
                window.requestAnimationFrame(self.fadeToBlack.bind(self, 60, 100, 50));
                window.clearTimeout(self.promptID);
                self.refs.myPrompt.style.visibility = "hidden";
                self.refs.myPrompt.style.left = "872px";
            } else if (self.currentMoment === 2) {
                window.clearTimeout(self.promptID);
                self.refs.myPrompt.style.visibility = "hidden";
                self.instructions = "Excellent! Now make it flash at the time when the blue square starts moving, then press Next (You can readjust the slider as many times as you need)";
                self.startTime = Date.now();
                window.requestAnimationFrame(self.fadeToBlack.bind(self, 60, 100, 50));
            }
            self.rectangle.animate();
        };

        self.hideErrors = function () {
            self.hasErrors = false;
            self.update();
        };

        self.promptAnswer = function () {
            if (self.refs.myPrompt.style.visibility === "hidden") {
                self.refs.myPrompt.style.visibility = "visible";
            } else {
                self.refs.myPrompt.style.visibility = "hidden";
            }
            clearTimeout(self.promptID); // avoids multiple calls
            self.promptID = window.setTimeout(self.promptAnswer, 300);
        };


        // color animation instruction change
        self.ms = 600;
        self.brightnessChange = 50;
        self.brightnessPerStep = self.brightnessChange / self.ms;
        self.startTime = -1;

        self.fadeToBlack = function (hue, sat, bri) {
            var step = Date.now() - self.startTime;
            var endBri = bri - step * self.brightnessPerStep;
            self.refs.instructionText.style.color = "hsl(" + hue + ", " + sat + "%," + endBri + "%)";

            // self.update();
            if (endBri > 0) {
                window.requestAnimationFrame(self.fadeToBlack.bind(self, hue, sat, bri));
            }
                    };




    </script>
</slider-practice>