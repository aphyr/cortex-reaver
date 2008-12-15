$(window).load(function() {
  var bar = $('#bar');
  var photo = $('#photo');
  var canvas = $('#canvas');
  var timeout;
    
  canvas.hover(
    function() {
      if (timeout) clearTimeout(timeout);
      if (bar.is(':animated')) {
        bar.stop();
        bar.css('opacity', 1);
        bar.show();
      } else {
        bar.fadeIn('fast');
      }
    },
    function() {
      timeout = setTimeout("$('#bar').fadeOut('slow');", 1000);
    }
  )

  // Adjust margins for bar
  bar.css('margin-bottom', (- $('#bar').height()));

  // Resize canvas to photo
  canvas.width(photo.width());
  canvas.height(photo.height());

  // Resize bar to photo width
  bar.css('position', 'absolute');
  bar.width(photo.width());
});
