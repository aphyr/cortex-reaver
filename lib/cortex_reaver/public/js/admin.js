// Show the admin box by default if we have a cookie that asks for it.
$(document).ready(function() {
  if(Cookie.get('adminboxopen') == 'true') {
    $('.admin.box').show();
  }
});

$(document).bind('keydown', {combi:'Ctrl+x',}, function() {
  // Toggle admin tools
  var a = $('.admin.box');
  a.toggle('fast', function() {
    if ($('.admin.box:visible')) {
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
  if($('.admin.box').is(':visible')) {
    Cookie.set('adminboxopen', 'true', 14);
  } else {
    Cookie.erase('adminboxopen');
  }
});
