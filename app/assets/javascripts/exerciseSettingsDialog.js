var ExerciseSettingsDialog = (function () {

    // constructor
    function ExerciseSettingsDialog(onSubmit, submitText) {
        this.onSubmit = onSubmit;
        initializeDialogForm.call(this, submitText);
    }

    function initializeDialogForm(submitText) {
        var container = $('#exercise-settings-dialog');
        var self = this;
        var buttons = {
            'Cancel': function () {
                self.dialog.dialog('close');
                self._updateDialogErrors('');
            }
        };
        buttons[submitText] = this._exerciseSettingsHelper.bind(this);
        this.dialog = container.dialog({
            autoOpen: false,
            modal: true,
            width: 500,
            buttons: buttons,
            close: function () {
                exSettingsForm[0].reset();
            },
            open: function () {
                self._updateDialogErrors('');
            }
        });

        //$('#exercise-settings-submit').on('click', this._exerciseSettingsHelper.bind(this));

        var exSettingsForm = this.dialog.find('form').on('submit', function (event) {
            debugger;
            event.preventDefault();
            this._exerciseSettingsHelper();
        });

        var exSettingsFeedback = $('#exercise-settings-feedback');
        var exSettingsFix = $('#exercise-settings-fix');
        exSettingsFeedback.on('change', function() {
          if (exSettingsFeedback.val() === 'continuous') {
            exSettingsFix.removeAttr('disabled');
          }
          else {
            exSettingsFix.attr('disabled', true);
          }
        });
    }

    /* Sets the error message on the dialog */
    ExerciseSettingsDialog.prototype._updateDialogErrors = function(msg) {
        var errors = this.dialog.find('.dialog-errors');
        if (!msg) {
            errors.text('');
            return;
        }
        errors
            .text(msg)
            .addClass('ui-state-highlight');
        setTimeout(function () {
            errors.removeClass('ui-state-highlight', 1500);
        }, 500);
    };

    // parse settings from the dialog and apply them to the
    // target exercise
    ExerciseSettingsDialog.prototype._exerciseSettingsHelper = function() {
        var settings = {
            points: Number.parseFloat($('#exercise-settings-points').val()),
        };
        if (this.currExInfo.type !== 'extr') {
            settings.required = $('#exercise-settings-required').is(':checked');
            if (this.currExInfo.type === 'ka') {
                settings.threshold = Number.parseInt($('#exercise-settings-threshold').val());
            }
            if (this.currExInfo.type === 'pe') {
                settings.threshold = Number.parseFloat($('#exercise-settings-threshold').val());
                var feedback = $('#exercise-settings-feedback').val();
                if (feedback === 'continuous') {
                    settings['JXOP-feedback'] = feedback;
                    settings['JXOP-fix'] = $('#exercise-settings-fix').val();
                }
                if ($('#exercise-settings-code').is(':checked')) {
                    settings['JXOP-code'] = 'none';
                }
            }
        }
        this.onSubmit(this.currExInfo, settings);
        this.dialog.dialog('close');
    };

    ExerciseSettingsDialog.prototype.show = function(exInfo, defaultOptions, hideRequired) {
        this.currExInfo = exInfo;
        this.dialog.find('form')[0].reset();
        var thresholdElem = $('#exercise-settings-threshold');
        var requiredSetting = hideRequired ? 'none' : '';
        switch (exInfo.type) {
            case 'ka':
                thresholdElem.attr('step', 1);
                thresholdElem.attr('min', 1);
                thresholdElem.removeAttr('max');
                $('#exercise-settings-pe').css('display', 'none');
                $('#exercise-settings-required-group').css('display', requiredSetting);
                $('#exercise-settings-threshold-group').css('display', '');
                break;
            case 'pe':
                thresholdElem.attr('step', 0.01);
                thresholdElem.attr('min', 0);
                thresholdElem.attr('max', 1);
                $('#exercise-settings-pe').css('display', '');
                $('#exercise-settings-required-group').css('display', requiredSetting);
                $('#exercise-settings-threshold-group').css('display', '');
                break;
            case 'extr':
                $('#exercise-settings-pe').css('display', 'none');
                $('#exercise-settings-required-group').css('display', 'none');
                $('#exercise-settings-threshold-group').css('display', 'none');
                break;
            case 'ss':
                $('#exercise-settings-pe').css('display', 'none');
                $('#exercise-settings-required-group').css('display', requiredSetting);
                $('#exercise-settings-threshold-group').css('display', 'none');
                break;
            case 'ff':
                $('#exercise-settings-pe').css('display', 'none');
                $('#exercise-settings-required-group').css('display', requiredSetting);
                $('#exercise-settings-threshold-group').css('display', 'none');
                break;
        }
        for (var option in defaultOptions) {
            var value = defaultOptions[option];
            option = option.replace('JXOP-', '');
            if (typeof value === 'boolean') {
                $('#exercise-settings-' + option).prop('checked', value);
            }
            else {
                $('#exercise-settings-' + option).val(value);
            }
        }
        if (exInfo.type === 'pe') {
            var hideCode = 'JXOP-code' in defaultOptions && defaultOptions['JXOP-code'] === 'none';
            $('#exercise-settings-' + option).prop('checked', hideCode);
            if ($('#exercise-settings-feedback').val() === 'continuous') {
                $('#exercise-settings-fix').removeAttr('disabled');
            }
            else {
                $('#exercise-settings-fix').attr('disabled', true);
            }
        }
        this.dialog.dialog('option', 'exId', exInfo.id);
        this.dialog.dialog('open');
    };

    return ExerciseSettingsDialog;
})();