function moduleClicked(modElem) {
    $(modElem.children[0]).toggleClass('fa-chevron-right');
    $(modElem.children[0]).toggleClass('fa-chevron-down');
}

function previewExercise(anchor, name, url, embed_code) {
    $('#iframe-container > iframe').replaceWith($.parseHTML(embed_code));
    $('#preview-title')[0].innerHTML = name;
    $('#preview-modal').modal();
}
