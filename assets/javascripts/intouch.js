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
  $('div#content .intouch-tab-content').hide();
  $('div.intouch-tabs a').removeClass('selected');
  $('#intouch-tab-content-' + name).show();
  $('#intouch-tab-' + name).addClass('selected');
  //replaces current URL with the "href" attribute of the current link
  //(only triggered if supported by browser)

  return false;
}
