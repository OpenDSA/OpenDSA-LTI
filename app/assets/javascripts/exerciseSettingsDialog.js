var ExerciseSettingsDialog = (function() {
  // constructor
  function ExerciseSettingsDialog(onSubmit, submitText) {
    this.onSubmit = onSubmit;
    initializeDialogForm.call(this, submitText);
  }

  function initializeDialogForm(submitText) {
    var container = $("#exercise-settings-dialog");
    var self = this;
    var buttons = {
      Cancel: function() {
        self.dialog.dialog("close");
        self._updateDialogErrors("");
      }
    };
    buttons[submitText] = this._exerciseSettingsHelper.bind(this);
    this.dialog = container.dialog({
      autoOpen: false,
      modal: true,
      width: 500,
      buttons: buttons,
      close: function() {
        exSettingsForm[0].reset();
      },
      open: function() {
        self._updateDialogErrors("");
      }
    });

    //$('#exercise-settings-submit').on('click', this._exerciseSettingsHelper.bind(this));

    var exSettingsForm = this.dialog.find("form").on("submit", function(event) {
      event.preventDefault();
      this._exerciseSettingsHelper();
    });

    var exSettingsFeedback = $("#exercise-settings-feedback");
    var exSettingsFix = $("#exercise-settings-fix");
    exSettingsFeedback.on("change", function() {
      if (exSettingsFeedback.val() === "continuous") {
        exSettingsFix.removeAttr("disabled");
      } else {
        exSettingsFix.attr("disabled", true);
      }
    });

    var pointsInput = $("#exercise-settings-points");
    $("#exercise-settings-gradable").on("change", function() {
      if (this.checked) {
        pointsInput.removeAttr("disabled");
      } else {
        pointsInput.val(0);
        pointsInput.attr("disabled", true);
      }
    });
  }

  /* Sets the error message on the dialog */
  ExerciseSettingsDialog.prototype._updateDialogErrors = function(msg) {
    var errors = this.dialog.find(".dialog-errors");
    if (!msg) {
      errors.text("");
      return;
    }
    errors.text(msg).addClass("ui-state-highlight");
    setTimeout(function() {
      errors.removeClass("ui-state-highlight", 1500);
    }, 500);
  };

  // parse settings from the dialog and apply them to the
  // target exercise
  ExerciseSettingsDialog.prototype._exerciseSettingsHelper = function() {
    var settings = {
      points: Number.parseFloat($("#exercise-settings-points").val())
    };
    if ($("#exercise-settings-gradable").is(":checked")) {
      settings.isGradable = true;
    } else {
      settings.isGradable = false;
      settings.points = 0.0;
    }
    if (this.currResourceInfo.type !== "extr") {
      settings.required = $("#exercise-settings-required").is(":checked");
      if (this.currResourceInfo.type === "ka") {
        settings.threshold = Number.parseInt(
          $("#exercise-settings-threshold").val()
        );
      }
      if (this.currResourceInfo.type === "pe") {
        settings.threshold = Number.parseFloat(
          $("#exercise-settings-threshold").val()
        );
        var feedback = $("#exercise-settings-feedback").val();
        if (feedback === "continuous") {
          settings["JXOP-feedback"] = feedback;
          settings["JXOP-fix"] = $("#exercise-settings-fix").val();
        }
        if ($("#exercise-settings-code").is(":checked")) {
          settings["JXOP-code"] = "none";
        }
      }
      if (this.currResourceInfo.type === "ae") {
        settings.threshold = Number.parseFloat(
          $("#exercise-settings-threshold").val()
        );
        var feedback = $("#exercise-settings-feedback").val();
        if (feedback === "continuous") {
          settings["JXOP-feedback"] = feedback;
          settings["JXOP-fix"] = $("#exercise-settings-fix").val();
        }
        if ($("#exercise-settings-code").is(":checked")) {
          settings["JXOP-code"] = "none";
        }
      }
    }
    this.onSubmit(this.currResourceInfo, settings);
    this.dialog.dialog("close");
  };

  ExerciseSettingsDialog.prototype.show = function(
    resourceInfo,
    defaultOptions,
    hideRequired,
    hideGradebookSettings
  ) {
    this.currResourceInfo = resourceInfo;
    this.dialog.find("form")[0].reset();
    var thresholdElem = $("#exercise-settings-threshold");
    var requiredSetting = hideRequired ? "none" : "";
    $("#gradebook-settings-container").css(
      "display",
      hideGradebookSettings ? "none" : ""
    );

    if (resourceInfo.type === "module") {
      $("#exercise-settings-dialog").attr("title", "Module Settings");
    } else {
      $("#exercise-settings-dialog").attr("title", "Exercise Settings");
    }
    showDialog = true;

    switch (resourceInfo.type) {
      case "ka":
        thresholdElem.attr("step", 1);
        thresholdElem.attr("min", 1);
        thresholdElem.removeAttr("max");
        $("#exercise-settings-pe").css("display", "none");
        $("#exercise-settings-required-group").css("display", requiredSetting);
        $("#exercise-settings-threshold-group").css("display", "");
        break;
      case "pe":
        thresholdElem.attr("step", 0.01);
        thresholdElem.attr("min", 0);
        thresholdElem.attr("max", 1);
        thresholdElem.val(1);
        $("#exercise-settings-pe").css("display", "");
        $("#exercise-settings-required-group").css("display", requiredSetting);
        $("#exercise-settings-threshold-group").css("display", "");
        break;
      case "ae":
        thresholdElem.attr("step", 0.01);
        thresholdElem.attr("min", 0);
        thresholdElem.attr("max", 1);
        thresholdElem.val(1);
        $("#exercise-settings-pe").css("display", "");
        $("#exercise-settings-required-group").css("display", requiredSetting);
        $("#exercise-settings-threshold-group").css("display", "");
        break;
      case "extr":
        $("#exercise-settings-pe").css("display", "none");
        $("#exercise-settings-required-group").css("display", "none");
        $("#exercise-settings-threshold-group").css("display", "none");
        showDialog = requiredSetting !== "none" || !hideGradebookSettings;
        break;
      case "ss":
        $("#exercise-settings-pe").css("display", "none");
        $("#exercise-settings-required-group").css("display", requiredSetting);
        $("#exercise-settings-threshold-group").css("display", "none");
        showDialog = requiredSetting !== "none" || !hideGradebookSettings;
        break;
      case "ff":
        $("#exercise-settings-pe").css("display", "none");
        $("#exercise-settings-required-group").css("display", requiredSetting);
        $("#exercise-settings-threshold-group").css("display", "none");
        showDialog = requiredSetting !== "none" || !hideGradebookSettings;
        break;
      case "module":
        $("#exercise-settings-pe").css("display", "none");
        $("#exercise-settings-required-group").css("display", "none");
        $("#exercise-settings-threshold-group").css("display", "none");
        showDialog = requiredSetting !== "none" || !hideGradebookSettings;
        break;
    }
    for (var option in defaultOptions) {
      var value = defaultOptions[option];
      option = option.replace("JXOP-", "");
      if (typeof value === "boolean") {
        $("#exercise-settings-" + option).prop("checked", value);
      } else {
        $("#exercise-settings-" + option).val(value);
      }
    }
    if (resourceInfo.type === "pe") {
      var hideCode =
        "JXOP-code" in defaultOptions && defaultOptions["JXOP-code"] === "none";
      $("#exercise-settings-" + option).prop("checked", hideCode);
      if ($("#exercise-settings-feedback").val() === "continuous") {
        $("#exercise-settings-fix").removeAttr("disabled");
      } else {
        $("#exercise-settings-fix").attr("disabled", true);
      }
    }
    if (resourceInfo.type === "ae") {
      var hideCode =
        "JXOP-code" in defaultOptions && defaultOptions["JXOP-code"] === "none";
      $("#exercise-settings-" + option).prop("checked", hideCode);
      if ($("#exercise-settings-feedback").val() === "continuous") {
        $("#exercise-settings-fix").removeAttr("disabled");
      } else {
        $("#exercise-settings-fix").attr("disabled", true);
      }
    }
    if (showDialog) {
      this.dialog.dialog("open");
    } else {
      this._exerciseSettingsHelper();
    }
  };

  return ExerciseSettingsDialog;
})();
