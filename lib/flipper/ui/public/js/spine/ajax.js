(function() {
  var $, Ajax, Base, Collection, Extend, Include, Model, Queue, Singleton, Spine,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Spine = this.Spine || require('spine');

  $ = Spine.$;

  Model = Spine.Model;

  Queue = $({});

  Ajax = {
    getURL: function(object) {
      return object && (typeof object.url === "function" ? object.url() : void 0) || object.url;
    },
    enabled: true,
    disable: function(callback) {
      if (this.enabled) {
        this.enabled = false;
        try {
          return callback();
        } catch (e) {
          throw e;
        } finally {
          this.enabled = true;
        }
      } else {
        return callback();
      }
    },
    queue: function(request) {
      if (request) {
        return Queue.queue(request);
      } else {
        return Queue.queue();
      }
    },
    clearQueue: function() {
      return this.queue([]);
    }
  };

  Base = (function() {

    function Base() {}

    Base.prototype.defaults = {
      contentType: 'application/json',
      dataType: 'json',
      processData: false,
      headers: {
        'X-Requested-With': 'XMLHttpRequest'
      }
    };

    Base.prototype.queue = Ajax.queue;

    Base.prototype.ajax = function(params, defaults) {
      return $.ajax(this.ajaxSettings(params, defaults));
    };

    Base.prototype.ajaxQueue = function(params, defaults) {
      var deferred, jqXHR, promise, request, settings;
      jqXHR = null;
      deferred = $.Deferred();
      promise = deferred.promise();
      if (!Ajax.enabled) {
        return promise;
      }
      settings = this.ajaxSettings(params, defaults);
      request = function(next) {
        return jqXHR = $.ajax(settings).done(deferred.resolve).fail(deferred.reject).then(next, next);
      };
      promise.abort = function(statusText) {
        var index;
        if (jqXHR) {
          return jqXHR.abort(statusText);
        }
        index = $.inArray(request, this.queue());
        if (index > -1) {
          this.queue().splice(index, 1);
        }
        deferred.rejectWith(settings.context || settings, [promise, statusText, '']);
        return promise;
      };
      this.queue(request);
      return promise;
    };

    Base.prototype.ajaxSettings = function(params, defaults) {
      return $.extend({}, this.defaults, defaults, params);
    };

    return Base;

  })();

  Collection = (function(_super) {

    __extends(Collection, _super);

    function Collection(model) {
      this.model = model;
      this.failResponse = __bind(this.failResponse, this);
      this.recordsResponse = __bind(this.recordsResponse, this);
    }

    Collection.prototype.find = function(id, params) {
      var record;
      record = new this.model({
        id: id
      });
      return this.ajaxQueue(params, {
        type: 'GET',
        url: Ajax.getURL(record)
      }).done(this.recordsResponse).fail(this.failResponse);
    };

    Collection.prototype.all = function(params) {
      return this.ajaxQueue(params, {
        type: 'GET',
        url: Ajax.getURL(this.model)
      }).done(this.recordsResponse).fail(this.failResponse);
    };

    Collection.prototype.fetch = function(params, options) {
      var id,
        _this = this;
      if (params == null) {
        params = {};
      }
      if (options == null) {
        options = {};
      }
      if (id = params.id) {
        delete params.id;
        return this.find(id, params).done(function(record) {
          return _this.model.refresh(record, options);
        });
      } else {
        return this.all(params).done(function(records) {
          return _this.model.refresh(records, options);
        });
      }
    };

    Collection.prototype.recordsResponse = function(data, status, xhr) {
      return this.model.trigger('ajaxSuccess', null, status, xhr);
    };

    Collection.prototype.failResponse = function(xhr, statusText, error) {
      return this.model.trigger('ajaxError', null, xhr, statusText, error);
    };

    return Collection;

  })(Base);

  Singleton = (function(_super) {

    __extends(Singleton, _super);

    function Singleton(record) {
      this.record = record;
      this.failResponse = __bind(this.failResponse, this);
      this.recordResponse = __bind(this.recordResponse, this);
      this.model = this.record.constructor;
    }

    Singleton.prototype.reload = function(params, options) {
      return this.ajaxQueue(params, {
        type: 'GET',
        url: Ajax.getURL(this.record)
      }).done(this.recordResponse(options)).fail(this.failResponse(options));
    };

    Singleton.prototype.create = function(params, options) {
      return this.ajaxQueue(params, {
        type: 'POST',
        data: JSON.stringify(this.record),
        url: Ajax.getURL(this.model)
      }).done(this.recordResponse(options)).fail(this.failResponse(options));
    };

    Singleton.prototype.update = function(params, options) {
      return this.ajaxQueue(params, {
        type: 'PUT',
        data: JSON.stringify(this.record),
        url: Ajax.getURL(this.record)
      }).done(this.recordResponse(options)).fail(this.failResponse(options));
    };

    Singleton.prototype.destroy = function(params, options) {
      return this.ajaxQueue(params, {
        type: 'DELETE',
        url: Ajax.getURL(this.record)
      }).done(this.recordResponse(options)).fail(this.failResponse(options));
    };

    Singleton.prototype.recordResponse = function(options) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      return function(data, status, xhr) {
        var _ref, _ref1;
        if (Spine.isBlank(data) || _this.record.destroyed) {
          data = false;
        } else {
          data = _this.model.fromJSON(data);
        }
        Ajax.disable(function() {
          if (data) {
            if (data.id && _this.record.id !== data.id) {
              _this.record.changeID(data.id);
            }
            return _this.record.updateAttributes(data.attributes());
          }
        });
        _this.record.trigger('ajaxSuccess', data, status, xhr);
        if ((_ref = options.success) != null) {
          _ref.apply(_this.record);
        }
        return (_ref1 = options.done) != null ? _ref1.apply(_this.record) : void 0;
      };
    };

    Singleton.prototype.failResponse = function(options) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      return function(xhr, statusText, error) {
        var _ref, _ref1;
        _this.record.trigger('ajaxError', xhr, statusText, error);
        if ((_ref = options.error) != null) {
          _ref.apply(_this.record);
        }
        return (_ref1 = options.fail) != null ? _ref1.apply(_this.record) : void 0;
      };
    };

    return Singleton;

  })(Base);

  Model.host = '';

  Include = {
    ajax: function() {
      return new Singleton(this);
    },
    url: function() {
      var args, url;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      url = Ajax.getURL(this.constructor);
      if (url.charAt(url.length - 1) !== '/') {
        url += '/';
      }
      url += encodeURIComponent(this.id);
      args.unshift(url);
      return args.join('/');
    }
  };

  Extend = {
    ajax: function() {
      return new Collection(this);
    },
    url: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      args.unshift(this.className.toLowerCase() + 's');
      args.unshift(Model.host);
      return args.join('/');
    }
  };

  Model.Ajax = {
    extended: function() {
      this.fetch(this.ajaxFetch);
      this.change(this.ajaxChange);
      this.extend(Extend);
      return this.include(Include);
    },
    ajaxFetch: function() {
      var _ref;
      return (_ref = this.ajax()).fetch.apply(_ref, arguments);
    },
    ajaxChange: function(record, type, options) {
      if (options == null) {
        options = {};
      }
      if (options.ajax === false) {
        return;
      }
      return record.ajax()[type](options.ajax, options);
    }
  };

  Model.Ajax.Methods = {
    extended: function() {
      this.extend(Extend);
      return this.include(Include);
    }
  };

  Ajax.defaults = Base.prototype.defaults;

  Spine.Ajax = Ajax;

  if (typeof module !== "undefined" && module !== null) {
    module.exports = Ajax;
  }

}).call(this);
