(function ($) {
  $.fn.idle = function (onIdle, onActive, options) {
    return this.each(function () {
      var isidle   = false,
          hasMoved = false,
          lastMove = (new Date()).getTime(),
          opts;

      if ($.isPlainObject(onActive)) {
        options = onActive;
      }

      if (!$.isFunction(onActive)) {
        onActive = $.noop;
      }

      opts = $.extend({}, $.fn.idle.defaults, options);

      $(this).bind("mousemove", function () {
        hasMoved = true;
        lastMove = (new Date()).getTime();
        if (isidle) {
          onActive.call(this);
          isidle = false;
        }
      });

      window.setInterval(function () {
        if ((new Date()).getTime() - lastMove > opts.after) {
          if (hasMoved) {
            onIdle.call(this);
          }
          lastMove = (new Date()).getTime();
          isidle = true;
        }
      }, opts.interval);
    });
  };
  // Set outside so they can be overridden globally before being called on an item
  $.fn.idle.defaults = {
    after: 30000,
    interval: 100
  };
}(jQuery));