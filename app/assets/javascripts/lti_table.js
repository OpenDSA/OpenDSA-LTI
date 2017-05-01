(function() {

    console.dir("lti tablejs")

    $(document).ready(function() {
        $('#display').click(function() {
            console.log("clicked registered");
            return handle_display();
        });
    });


    handle_display = function() {
        var messages = check_dis_completeness();
        if (messages.length !== 0) {
            alert(messages);
            return;
        }
        //GET /course_offerings/:user_id/:inst_section_id
        var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + $('#comb').find('option:selected').val();

        var aj = $.ajax({
            url: request,
            type: 'get',
            data: $(this).serialize()
        }).done(function(data) {
            if (data.odsa_exercise_progress.length === 0) {
                var p = '<p style="font-size:24px; align=center;"> You have not Attempted this exercise <p>';
                $('#log').html(p);
            } else {
                var header = '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
                header += '<table>';
                header += '<tr>';
                var elem = '<tr>';
                header += buildProgressHeader();
                elem += getFieldMember(data.inst_section, data.odsa_exercise_progress[0], data.odsa_exercise_attempts);
                var header1 = '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table <p>';
                header1 += '<table>';
                header1 += '<tr>';
                var elem1 = '<tr>';
                header1 += getAttemptHeader();
                var proficiencyFlag = -1;
                for (var i = 0; i < data.odsa_exercise_attempts.length; i++) {
                    if (data.odsa_exercise_attempts[i].earned_proficiency != null && data.odsa_exercise_attempts[i].earned_proficiency && proficiencyFlag == -1) {
                        proficiencyFlag = 1;
                        elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag);
                        proficiencyFlag = 2;
                    } else {
                        elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag);
                    }
                }
                header1 += elem1;
                header += elem;
                header += '</table> ';
                header1 += '</table>';
                header += '<br>' + header1;
                $('#log').html(header);
            }
            change_courses(data);
        }).fail(function(data) {
            alert("failure")
            console.log('AJAX request has FAILED');
        });
    };

    getFieldMember = function(sData, pData, attempts) {
        // console.dir(pData)
        var member = '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.current_score + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.highest_score + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.total_correct + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + attempts.length + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.proficient_date.substring(0, 10) + " " + pData.proficient_date.substring(11, 16) + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.first_done.substring(0, 10) + " " + pData.first_done.substring(11, 16) + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.last_done.substring(0, 10) + " " + pData.last_done.substring(11, 16) + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + sData.lms_posted + '</th>';
        member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + sData.time_posted + '</th>';
        return member;
    }

    buildProgressHeader = function() {
        var elem = '<tr> <th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Current Score </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Highest Score </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Total Correct </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Total Attempts </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Proficient Date </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> First Done </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Last Done </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Posted to Canvas? </th>';
        elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Posted </th> </tr>';

        return elem
    }
    getAttemptHeader = function() {
        var head = '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Question name </th>';
        head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Request Type </th>';
        head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Correct </th>';
        head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Worth Credit </th>';
        head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Done </th>';
        head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Taken (s)</th>';
        return head;
    }
    getAttemptMemeber = function(aData, j) {
        var memb = "";
        console.dir(aData.earned_proficiency + " and j = " + j)
        if (aData.earned_proficiency != null && j == 1) {
            memb += '<tr bgcolor="#FF0000"><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
        } else {
            memb += '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
        }
        memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.request_type + '</th>';
        memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.correct + '</th>';
        memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.worth_credit + '</th>';
        memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_done.substring(0, 10) + " " + aData.time_done.substring(11, 16) + '</th>';
        memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_taken + '</th>';

        return memb;


    }
    check_dis_completeness = function() {
        var messages;
        messages = [];
        var selectbar1 = $('#combobox').find('option:selected').text();
        var selectbar2 = $('#comb').find('option:selected').text();
        if (selectbar1 === '' || selectbar2 === '') {
            messages.push("You need to select a student or assignment");
            return messages;
        }
        return messages
    };

}).call(this);