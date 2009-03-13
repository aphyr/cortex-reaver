/*
 * jQuery plugin: autoCompletefb(AutoComplete Facebook)
 * @requires jQuery v1.2.2 or later
 * using plugin:jquery.autocomplete.js
 *
 * Credits:
 * - Idea: Facebook
 * - Guillermo Rauch: Original MooTools script
 * - InteRiders <http://interiders.com/> 
 *
 * Modified by Michael 'manveru' Fellinger <m.fellinger@gmail.com>
 *
 * Copyright (c) 2008 Widi Harsojo <wharsojo@gmail.com>, http://wharsojo.wordpress.com/
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */

jQuery.fn.autoCompletefb = function(options) {
  var tmp = this;
  var root = tmp[0];
  if(!root){ return; } // fail fast if this is called on empty jquery collection

  var settings = {
    ul         : tmp,
    urlLookup  : [""],
    foundClass : ".acfb-data",
    inputClass : ".acfb-input",
    removeImg  : "/theme/light/media/delete.gif"
  }

  if(options){ jQuery.extend(settings, options); }
  
  var acfb = {
    params  : settings,
    getData : function(){
      var result = '';
      $(settings.foundClass, tmp).each(
        function(i) {
          if(i > 0){ result += ','; }
          result += $('span', this).html();
          result += $('input', this).html();
        });
      return result;
    },
    clearData : function(){
      $(settings.foundClass, tmp).remove();
      $(settings.inputClass, tmp).focus();
      return tmp.acfb;
    },
    removeFind : function(o, d){
      var without = [];

      for(i in root.acfb_data){
        var val = root.acfb_data[i];
        if(val !== d){ without.push(val); }
      }

      root.acfb_data = without;
      acfb.updateStore([]);

      $(o).unbind('click').parent().remove();
      $(settings.inputClass, tmp).focus();
      return tmp.acfb;
    },
    updateStore : function(d){
      for(i in d){ root.acfb_data.push(d[i]); }
      var input = $('.acfb-store', root);
      input.val(root.acfb_data.join(","));
    },
    addLi : function(data, value){
      if(value.length == 0){ return; }
      for(i in root.acfb_data){ if(root.acfb_data[i] == value){ return } }
      acfb.updateStore(data);

      var klass = settings.foundClass.replace(/\./,'');
      var li_tag = '<li class="' + klass + '"><span>' + data + '</span> <img class="p" src="' + settings.removeImg + '"/></li>';
      var li = $(settings.inputClass, tmp).before(li_tag);

      $('.p', li[0].previousSibling).click(function(){
        acfb.removeFind(this, data[0]);
      });
    },
    addLis : function(arr){
      for(i in arr){ acfb.addLi([arr[i]], arr[i]); }
    }
  }

  // using an array so we can easily join
  root.acfb_data = [];

  // add hidden input tag in the ul
  var orig_input = $(settings.inputClass, tmp)[0];
  var input_name = orig_input.name;
  var input_tag = '<input type="hidden" class="acfb-store" name="' + input_name + '" />';
  var input = $(settings.inputClass, tmp).before(input_tag)[0];

  var orig_values = orig_input.value.split(",");
  acfb.addLis(orig_values);

  // remove name from original input tag so it won't show up in the request and
  // reset the value so it is ready to take further input
  $(orig_input).removeAttr("name");
  orig_input.value = '';

  // add an add button... enter doesn't seem to work?
  var add_tag = '<span class="acfb-add">+</a>'
  $(settings.inputClass, tmp).after(add_tag);
  var add = $('.acfb-add', tmp);
  add.click(function(){
    var words = orig_input.value.split(/,+/);
    acfb.addLis(words);
    $(settings.inputClass, tmp).val('').focus();
    return false;
  });

  // $(settings.foundClass + " img.p").click(function(){ acfb.removeFind(this); });
  $(settings.inputClass, tmp).autocomplete(settings.urlLookup);
  $(settings.inputClass, tmp).result(function(ev, data, value) {
    acfb.addLi(data, value);
    $(settings.inputClass, tmp).val('').focus();
  });
  return acfb;
}

