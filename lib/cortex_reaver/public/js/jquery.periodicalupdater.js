/**
* PeriodicalUpdater - jQuery plugin for timed, decaying ajax calls
*
* Smokejumper Version by Robert Fischer, Smokejumper IT
* Based on version from http://www.360innovate.co.uk
*
* Copyright (c) 2009 by the following:
* * Robert Fischer (http://smokejumperit.com)
* * 360innovate (http://www.360innovate.co.uk)
* Dual licensed under the MIT and GPL licenses:
* http://www.opensource.org/licenses/mit-license.php
* http://www.gnu.org/licenses/gpl.html
*
* Version: 2.0
*/
 
(function($) {
    $.PeriodicalUpdater = function(url, options, callback){
 
        var settings = jQuery.extend(true, {
            url: url, // URL of ajax request
cache: false, // By default, don't allow caching
            method: 'GET', // method; get or post
            data: '', // array of values to be passed to the page - e.g. {name: "John", greeting: "hello"}
            minTimeout: 1000, // starting value for the timeout in milliseconds
            maxTimeout: 8000, // maximum length of time between requests
            multiplier: 2 // if set to 2, timerInterval will double each time the response hasn't changed (up to maxTimeout)
        }, options);
        
        // set some initial values, then begin
        var prevContent = null;
var knowIsSame = false;
        var timerInterval = settings.minTimeout;
 
// Function to boost the timer (nop unless multiplier > 1)
var boostPeriod = function() { return; };
if(settings.multiplier > 1) {
boostPeriod = function() {
timerInterval = timerInterval * settings.multiplier;
 
if(timerInterval > settings.maxTimeout) {
timerInterval = settings.maxTimeout;
}
};
}
 
var PeriodicalTimer = null; // Getting a handle on this for some reason
 
// Construct the settings for $.ajax based on settings
var ajaxSettings = jQuery.extend(true, {}, settings);
if(settings.type && !ajaxSettings.dataType) ajaxSettings.dataType = settings.type;
if(settings.sendData) ajaxSettings.data = settings.sendData;
ajaxSettings.type = settings.method; // 'type' is used internally for jQuery. Who knew?
ajaxSettings.ifModified = false;
ajaxSettings.success = function(data) {
if(knowIsSame || (prevContent || prevContent == "") && prevContent == data) {
boostPeriod();
} else {
if(console) {
console.log("Change in data: old data is " + prevContent + " and new data is " + data);
}
prevContent = data;
timerInterval = settings.minTimeout;
if(callback) {
callback(data);
}
}
PeriodicalTimer = setTimeout(getdata, timerInterval);
if(settings.success) { settings.success(data); }
};
ajaxSettings.error = function (XMLHttpRequest, textStatus) {
if(knowIsSame || textStatus == "notmodified") {
boostPeriod();
} else {
if(console) {
console.log("Resetting due to error: " + textStatus);
}
prevContent = null;
timerInterval = settings.minTimeout;
}
PeriodicalTimer = setTimeout(getdata, timerInterval);
if(settings.error) { settings.error(XMLHttpRequest, textStatus); }
};
 
var oldRawData = null;
ajaxSettings.dataFilter = function (data, type) {
if(settings.dataFilter) data = settings.dataFilter(data, type);
knowIsSame = (data && oldRawData && data == oldRawData);
oldRawData = data;
   return data;
};
 
function getdata() { $.ajax(ajaxSettings); }
 
// Make the first call
        $(function() { getdata(); });
    };
})(jQuery);
