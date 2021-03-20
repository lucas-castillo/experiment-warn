<prolific>
    <style>
        .psychErrorMessage{ /*override style*/
            font-size: 23px;
            text-align: center;
        }

    </style>
    <div class="psychTextContentLarge" style="text-align: left">
        <p>You have reached the end of the task.</p>
        <div ref = "prolificIDRequest" show = "{requestID}">
            <p> Please write your Prolific ID here:</p>
            <textarea onclick="{hideErrors}" style="margin: 0px; width: 597px; height: 49px;" ref="prolificID"></textarea>
        </div>
        <p>Please click Next to return to Prolific and claim your payment</p>
        <p>Thank you very much for your time!</p>
    </div>
    <p class="psychErrorMessage" show="{hasErrors}">{errorText}</p>
    <script>
        var self = this;
        self.onInit = function () {
            self.returnCode = self.experiment.condition.factors.completionCode;
            self.returnPage = "https://app.prolific.co/submissions/complete?cc=" + self.returnCode;
            self.prolificID = self.getPIDfromURL();
            self.requestID = self.prolificID === null;

        };
        self.canLeave = function () {
            if (!self.prolificID && !self.refs.prolificID.value) {
                self.hasErrors = true;
                self.errorText = "Please write your Prolific ID";
                return false;
            } else {
                return true;
            }
        };

        self.results = function () {
            if (!self.prolificID) {
                self.prolificID = self.refs.prolificID.value;
            }
            var resultsDict = {"prolificID": self.prolificID};
            return resultsDict;
        };

        self.hideErrors = function () {
            self.hasErrors = false;
        };
        self.getPIDfromURL = function () {
            var queryString = window.location.search;
            var urlParams = new URLSearchParams(queryString);
            return urlParams.get("PROLIFIC_PID");
        }
    </script>
</prolific>