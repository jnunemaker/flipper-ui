(function() {
  var $, App, Content, Feature, FeatureList, Header,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = jQuery;

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

  FeatureList = (function(_super) {

    __extends(FeatureList, _super);

    function FeatureList() {
      this.render = __bind(this.render, this);
      FeatureList.__super__.constructor.apply(this, arguments);
      Feature.bind("refresh", this.render);
    }

    FeatureList.prototype.render = function() {
      var feature, features, source, template, _i, _len, _results;
      features = Feature.all();
      source = $("#feature-template").html();
      template = Handlebars.compile(source);
      this.html('');
      _results = [];
      for (_i = 0, _len = features.length; _i < _len; _i++) {
        feature = features[_i];
        _results.push(this.append(template(feature)));
      }
      return _results;
    };

    return FeatureList;

  })(Spine.Controller);

  Header = (function(_super) {

    __extends(Header, _super);

    function Header() {
      return Header.__super__.constructor.apply(this, arguments);
    }

    return Header;

  })(Spine.Controller);

  Content = (function(_super) {

    __extends(Content, _super);

    function Content() {
      Content.__super__.constructor.apply(this, arguments);
      this.feature_list = new FeatureList({
        el: $('#features')
      });
      this.append(this.feature_list);
    }

    return Content;

  })(Spine.Controller);

  App = (function(_super) {

    __extends(App, _super);

    function App() {
      App.__super__.constructor.apply(this, arguments);
      this.header = new Header({
        el: $('#header')
      });
      this.content = new Content({
        el: $('#content')
      });
      Feature.fetch();
      Feature.one('refresh', function() {
        return Spine.Route.setup({
          history: true
        });
      });
    }

    return App;

  })(Spine.Controller);

  $(function() {
    return new App({
      el: $('#app')
    });
  });

}).call(this);
