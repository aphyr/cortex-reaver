// Show the admin box by default if we have a cookie that asks for it.
$(window).load(function() {
  if(Cookie.get('adminboxopen') == 'true') {
    $('#adminbox').show();
  }
});

$(document).bind('keydown', {combi:'Ctrl+x',}, function() {
  // Toggle admin tools
  var a = $('#adminbox');
  a.slideToggle('fast', function() {
    if ($('adminbox:visible')) {
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
  if($('#adminbox').is(':visible')) {
    Cookie.set('adminboxopen', 'true', 14);
  } else {
    Cookie.erase('adminboxopen');
  }
});
