$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip();
});

function update_form(type) {
    $("#attribute_list").children().each(function(){
      $(this).addClass("hidden");
      $(".hidden").prop('disabled', false)
    })
    console.log(type)
    if (type == "attempt") {
        $("#attribute_list").children().each(function(){
            console.log($(this).attr("class"));
            if ($(this).attr("class").includes("attempt hidden") || $(this).attr("class") == ("hidden attempt")) {
                $(this).removeClass("hidden");
            }
        });
    }
    if (type == "progress") {
        $("#attribute_list").children().each(function(){
            console.log($(this).attr("class"));
            if ($(this).attr("class") == ("prog hidden") || $(this).attr("class") == ("hidden prog")) {
                $(this).removeClass("hidden");
            }
        });
    }
    if (type == "interaction") {
        $("#attribute_list").children().each(function(){
            console.log($(this).attr("class"));
            if ($(this).attr("class") == ("interaction hidden") || $(this).attr("class") == ("hidden interaction")) {
                $(this).removeClass("hidden");
            }
        });
    }
}

function validate_form() {
    $(".hidden").prop('disabled', true)
    return true;
}