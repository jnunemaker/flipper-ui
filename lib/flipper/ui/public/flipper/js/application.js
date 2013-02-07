(function() {
  var App, Feature,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Feature = (function(_super) {

    __extends(Feature, _super);

    function Feature() {
      return Feature.__super__.constructor.apply(this, arguments);
    }

    Feature.configure("Feature", "id", "name");

    Feature.extend(Spine.Model.Ajax);

    Feature.extend({
      url: "/flipper/features"
    });

    return Feature;

  })(Spine.Model);

  window.Feature = Feature;

  App = (function(_super) {

    __extends(App, _super);

    function App() {
      App.__super__.constructor.apply(this, arguments);
      this.content = new App.Content({
        el: $('#content')
      });
    }

    return App;

  })(Spine.Controller);

  window.App = App;

  App.Content = (function(_super) {

    __extends(Content, _super);

    function Content() {
      Content.__super__.constructor.apply(this, arguments);
      this.features = new App.Features({
        el: $('#features')
      });
      this.append(this.features);
    }

    return Content;

  })(Spine.Controller);

  App.Features = (function(_super) {

    __extends(Features, _super);

    function Features() {
      this.addAll = __bind(this.addAll, this);

      this.addOne = __bind(this.addOne, this);
      Features.__super__.constructor.apply(this, arguments);
      Feature.bind("refresh", this.addAll);
      Feature.fetch();
    }

    Features.prototype.addOne = function(feature) {
      feature = new App.Feature({
        feature: feature
      });
      return this.append(feature.render());
    };

    Features.prototype.addAll = function() {
      var feature, _i, _len, _ref, _results;
      this.html('');
      _ref = Feature.all();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        feature = _ref[_i];
        _results.push(this.addOne(feature));
      }
      return _results;
    };

    return Features;

  })(Spine.Controller);

  App.Feature = (function(_super) {

    __extends(Feature, _super);

    function Feature() {
      Feature.__super__.constructor.apply(this, arguments);
      if (!(this.feature != null)) {
        throw "@feature required";
      }
    }

    Feature.prototype.render = function() {
      return this.html(this.template(this.feature));
    };

    Feature.prototype.template = function(feature) {
      var source, template;
      source = $("#feature-template").html();
      template = Handlebars.compile(source);
      return template(feature);
    };

    return Feature;

  })(Spine.Controller);

  jQuery(function() {
    return new App({
      el: $('#app')
    });
  });

}).call(this);
