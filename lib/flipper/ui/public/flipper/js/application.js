(function() {
  var App, Feature, Gate,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Feature = (function(_super) {

    __extends(Feature, _super);

    Feature.configure("Feature", "id", "name", "state", "description", "gates");

    Feature.extend(Spine.Model.Ajax);

    Feature.extend({
      url: "/flipper/features"
    });

    function Feature() {
      var _this = this;
      Feature.__super__.constructor.apply(this, arguments);
      this.gates = this.gates.map(function(data) {
        data.feature_id = _this.id;
        return new Gate(data);
      });
    }

    Feature.prototype.gate = function(name) {
      var gates;
      gates = this.gates.filter(function(gate) {
        return gate.name === name;
      });
      return gates[0];
    };

    return Feature;

  })(Spine.Model);

  window.Feature = Feature;

  Gate = (function(_super) {

    __extends(Gate, _super);

    Gate.configure("Gate", "feature_id", "key", "name", "value");

    function Gate() {
      Gate.__super__.constructor.apply(this, arguments);
    }

    Gate.prototype.url = function() {
      return "/flipper/features/" + (encodeURIComponent(this.feature_id)) + "/" + (encodeURIComponent(this.key));
    };

    Gate.prototype.save = function() {
      var result;
      result = Gate.__super__.save.apply(this, arguments);
      this.ajaxSave();
      return result;
    };

    Gate.prototype.ajaxSave = function() {
      var options;
      options = {
        type: 'POST',
        url: this.url(),
        data: {
          value: this.value
        }
      };
      return $.ajax(options);
    };

    return Gate;

  })(Spine.Model);

  App = (function(_super) {

    __extends(App, _super);

    function App() {
      App.__super__.constructor.apply(this, arguments);
      this.features = new App.FeatureList({
        el: $('#features')
      });
    }

    return App;

  })(Spine.Controller);

  App.FeatureList = (function(_super) {

    __extends(FeatureList, _super);

    function FeatureList() {
      this.addAll = __bind(this.addAll, this);

      this.addOne = __bind(this.addOne, this);
      FeatureList.__super__.constructor.apply(this, arguments);
      this.features = {};
      Feature.bind("refresh", this.addAll);
      Feature.one('refresh', function() {
        return Spine.Route.setup({
          history: true
        });
      });
      Feature.fetch();
      this.routes({
        '/flipper/features/:id': function(params) {
          var controller;
          if (controller = this.features[params.id]) {
            controller.edit();
            return controller.openDefaultGate();
          }
        },
        '/flipper/features/:id/:gate': function(params) {
          var controller;
          if (controller = this.features[params.id]) {
            controller.edit();
            return controller.activateGate(params);
          }
        }
      });
    }

    FeatureList.prototype.addOne = function(feature) {
      var controller;
      controller = new App.Feature({
        feature: feature
      });
      this.features[feature.id] = controller;
      return this.append(controller.render());
    };

    FeatureList.prototype.addAll = function() {
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

    return FeatureList;

  })(Spine.Controller);

  App.Feature = (function(_super) {

    __extends(Feature, _super);

    Feature.prototype.elements = {
      '.feature': 'dom_feature',
      '.gates': 'dom_gates'
    };

    Feature.prototype.events = {
      'click .show-settings': 'openFeature',
      'click .hide-settings': 'hide',
      'click [data-tab]': 'clickTab'
    };

    function Feature() {
      Feature.__super__.constructor.apply(this, arguments);
      if (!(this.feature != null)) {
        throw "@feature required";
      }
    }

    Feature.prototype.render = function() {
      this.html(this.template(this.feature));
      this.gate_list = new App.GateList({
        el: this.dom_gates
      });
      return this.el;
    };

    Feature.prototype.openFeature = function(event) {
      if (event) {
        event.preventDefault();
      }
      return this.navigate("/flipper/features/" + this.feature.id);
    };

    Feature.prototype.openDefaultGate = function() {
      return this.navigate("/flipper/features/" + this.feature.id + "/boolean");
    };

    Feature.prototype.template = function(feature) {
      var source, template;
      source = $("#feature-template").html();
      template = Handlebars.compile(source);
      return template(feature);
    };

    Feature.prototype.clickTab = function(event) {
      var name, tab;
      event.preventDefault();
      tab = $(event.currentTarget);
      name = tab.attr('data-tab');
      return this.navigate("/flipper/features/" + this.feature.id + "/" + name);
    };

    Feature.prototype.activateGate = function(params) {
      var name;
      name = params.gate;
      this.gate_list[name].active(params);
      this.el.find('[data-tab]').removeClass('active');
      return this.el.find("[data-tab=" + name + "]").addClass('active');
    };

    Feature.prototype.edit = function(event) {
      if (event) {
        event.preventDefault();
      }
      return this.dom_feature.addClass('settings');
    };

    Feature.prototype.hide = function(event) {
      if (event) {
        event.preventDefault();
      }
      this.dom_feature.removeClass('settings');
      return this.navigate('/flipper');
    };

    return Feature;

  })(Spine.Controller);

  App.Gate = (function(_super) {

    __extends(Gate, _super);

    function Gate() {
      Gate.__super__.constructor.apply(this, arguments);
      this.active(this.render);
    }

    Gate.prototype.render = function(params) {
      this.feature = Feature.find(params.id);
      this.gate = this.feature.gate(params.gate);
      return this.html(this.template());
    };

    Gate.prototype.template = function() {
      var html_id, source, template;
      html_id = "#gate-" + (this.name.replace(/_/g, '-')) + "-template";
      source = $(html_id).html();
      template = Handlebars.compile(source);
      return template(this.gate);
    };

    return Gate;

  })(Spine.Controller);

  App.Gate.Boolean = (function(_super) {

    __extends(Boolean, _super);

    Boolean.prototype.elements = {
      'input[value=true]': 'input'
    };

    Boolean.prototype.events = {
      'submit form': 'submit'
    };

    function Boolean() {
      this.name = 'boolean';
      Boolean.__super__.constructor.apply(this, arguments);
    }

    Boolean.prototype.submit = function(event) {
      event.preventDefault();
      this.gate.value = this.input.is(':checked');
      return this.gate.save();
    };

    return Boolean;

  })(App.Gate);

  App.Gate.Group = (function(_super) {

    __extends(Group, _super);

    function Group() {
      this.name = 'group';
      Group.__super__.constructor.apply(this, arguments);
    }

    return Group;

  })(App.Gate);

  App.Gate.Actor = (function(_super) {

    __extends(Actor, _super);

    function Actor() {
      this.name = 'actor';
      Actor.__super__.constructor.apply(this, arguments);
    }

    return Actor;

  })(App.Gate);

  App.Gate.Percentage = (function(_super) {

    __extends(Percentage, _super);

    function Percentage() {
      return Percentage.__super__.constructor.apply(this, arguments);
    }

    Percentage.prototype.elements = {
      'input[type=text]': 'input'
    };

    Percentage.prototype.events = {
      'submit form': 'submit'
    };

    Percentage.prototype.submit = function(event) {
      event.preventDefault();
      this.gate.value = this.input.val();
      return this.gate.save();
    };

    return Percentage;

  })(App.Gate);

  App.Gate.PercentageOfActors = (function(_super) {

    __extends(PercentageOfActors, _super);

    function PercentageOfActors() {
      this.name = 'percentage_of_actors';
      PercentageOfActors.__super__.constructor.apply(this, arguments);
    }

    return PercentageOfActors;

  })(App.Gate.Percentage);

  App.Gate.PercentageOfRandom = (function(_super) {

    __extends(PercentageOfRandom, _super);

    function PercentageOfRandom() {
      this.name = 'percentage_of_random';
      PercentageOfRandom.__super__.constructor.apply(this, arguments);
    }

    return PercentageOfRandom;

  })(App.Gate.Percentage);

  App.GateList = (function(_super) {

    __extends(GateList, _super);

    function GateList() {
      return GateList.__super__.constructor.apply(this, arguments);
    }

    GateList.prototype.controllers = {
      boolean: App.Gate.Boolean,
      group: App.Gate.Group,
      actor: App.Gate.Actor,
      percentage_of_actors: App.Gate.PercentageOfActors,
      percentage_of_random: App.Gate.PercentageOfRandom
    };

    return GateList;

  })(Spine.Stack);

  jQuery(function() {
    return new App({
      el: $('#app')
    });
  });

}).call(this);
