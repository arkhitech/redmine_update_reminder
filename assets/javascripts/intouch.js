$(function () {
    $('#settings_template_id').change(function () {
        if ($(this).val() == '') {
            $('.intouch-settings').show()
        } else {
            $('.intouch-settings').hide()
        }
    });
});
