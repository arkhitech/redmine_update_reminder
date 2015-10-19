$(function () {
    $('#intouch_settings_settings_template_id').change(function () {
        if ($(this).val() == '') {
            $('.intouch-settings').show()
        } else {
            $('.intouch-settings').hide()
        }
    });
    $('.copyIssueUpdateSettings').click(function () {
      var currentTabContent = $(this).parents('.intouch-tab-content');
      var otherTabContents = currentTabContent.siblings('.intouch-tab-content');

      currentTabContent.find('input[type="checkbox"]:checked').each(function(index, element){
        otherTabContents.find( 'input[type="checkbox"].' + $(element).attr('class') ).prop('checked',true);
      });

      return false;
    });

    $('.copySettingsFromOtherTab').click(function () {
      currentTabContent = $('.copySettingsFromOtherTab').parents('.intouch-tab-content');
      var currentTabContent = $(this).parents('.intouch-tab-content');
      var otherTabId = currentTabContent.find('option:selected').val();
      var otherTabContent = $('#intouch-tab-content-' + otherTabId);

      otherTabContent.find('input[type="checkbox"]:checked').each(function(index, element){
        currentTabContent.find( 'input[type="checkbox"].' + $(element).attr('class') ).prop('checked',true);
      });

      return false;
    })
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
