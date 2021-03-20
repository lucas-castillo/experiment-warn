<condition-selector>
    <div class='input-container'>
        <span class='input-label'>Knowledge:</span>
        <psych-input prompt="Please Select" name="knowledge" options="{['informed', 'uninformed']}"></psych-input>
    </div>
    <div class='input-container'>
        <span class='input-label'>Timing:</span>
        <psych-input prompt="Please Select" name="timing" options="{['canonical', 'reversed']}"></psych-input>
    </div>
    <script>
        var self = this;
        self.canLeave = function(){
            if (typeof self.knowledge !== 'undefined'){
                self.experiment.condition.factors.knowledge = self.knowledge;
            }
            if (typeof self.timing !== 'undefined'){
                self.experiment.condition.factors.timing = self.timing;
            }
            return true
        }
    </script>
</condition-selector>