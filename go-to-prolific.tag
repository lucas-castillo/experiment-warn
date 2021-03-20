<go-to-prolific>
    <script>
        var self = this;
        self.onShown = function () {
            window.location.href = "https://app.prolific.co/submissions/complete?cc=" + self.experiment.settings.completionCode;
        }
    </script>
</go-to-prolific>