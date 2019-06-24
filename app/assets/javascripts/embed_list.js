var exSettingsDialog;

function moduleClicked(modElem) {
    $(modElem.children[0]).toggleClass('fa-chevron-right');
    $(modElem.children[0]).toggleClass('fa-chevron-down');
}

function previewExercise(anchor, name, url, embed_code) {
    $('#iframe-container > iframe').replaceWith($.parseHTML(embed_code));
    $('#preview-title')[0].innerHTML = name;
    $('#preview-modal').modal();
}

function ltiExerciseSettingsChosen(selected, settings) {
    delete settings.isGradable;
    delete settings.required;

    var launchUrl = window.ltiLaunchBaseUrl + '?';
    var settingsJson = JSON.stringify(settings);
    launchUrl += 'custom_ex_short_name=' + selected.short_name;
    launchUrl += '&custom_ex_settings=' + encodeURIComponent(settingsJson);
    $('#lti-launch-url-input').val(launchUrl);
    $('#lti-launch-title')[0].innerHTML = 'LTI Launch Info - ' + selected.name;

    $('#lti-launch-base-url-input').val(window.ltiLaunchBaseUrl);
    $('#lti-launch-name-input').val(selected.short_name);
    $('#lti-launch-settings-input').val(settingsJson);
    
    $('#lti-launch-url-modal').modal();
}

function ltiResourceSelect(selected) {
    selected = selected.inst_exercise;
    selected.type = selected.ex_type;
    if ($.inArray(selected.type, ['ss', 'ff']) !== -1) {
        ltiExerciseSettingsChosen(selected, {});
    }
    else {
        exSettingsDialog.show(selected, {}, true, true);
    }
}

$(document).ready(function () {
    exSettingsDialog = new ExerciseSettingsDialog(ltiExerciseSettingsChosen, "Next");
});
