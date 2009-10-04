// Show the admin box by default if we have a cookie that asks for it.
$(document).ready(function() {
  if(Cookie.get('adminboxopen') == 'true') {
    $('.admin.bar').show();
  }
});

$(document).bind('keydown', {combi:'Alt+Ctrl+a',}, function() {
  // Toggle admin tools
  var a = $('.admin.bar');
  a.slideToggle('fast', function() {
    if ($('.admin.bar:visible')) {
      // Focus tools
      if ($('#admin_login')) $('#admin_login').focus();
    } else {
      // Unfocus tools
      if ($('#admin_login')) $('#admin_login').blur();
    }
  });
});

// On leaving the page, remember the admin tool state.
$(window).unload(function() {
  if($('.admin.bar').is(':visible')) {
    Cookie.set('adminboxopen', 'true', 14);
  } else {
    Cookie.erase('adminboxopen');
  }
});
