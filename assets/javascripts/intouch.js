$(function () {
    $('#intouch_settings_settings_template_id').change(function () {
        if ($(this).val() == '') {
            $('.intouch-settings').show()
        } else {
            $('.intouch-settings').hide()
        }
    });
});

function showIntouchTab(name) {
  var selectedTab = $('#intouch-tab-' + name);
  var box = selectedTab.parents('.box');
  box.children('.intouch-tab-content').hide();
  box.find('.intouch-tab').removeClass('selected');
  box.children('#intouch-tab-content-' + name).show();
  selectedTab.addClass('selected');

  return false;
}
