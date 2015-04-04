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
      url: "" + Flipper.Config.url + "/features"
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
      return "" + Flipper.Config.url + "/features/" + (encodeURIComponent(this.feature_id)) + "/" + (encodeURIComponent(this.name));
    };

    Gate.prototype.disableSetMember = function(member, success_callback, error_callback) {
      return this.setMember('disable', member, success_callback, error_callback);
    };

    Gate.prototype.enableSetMember = function(member, success_callback, error_callback) {
      return this.setMember('enable', member, success_callback, error_callback);
    };

    Gate.prototype.setMember = function(operation, member, success_callback, error_callback) {
      var options,
        _this = this;
      options = {
        type: 'POST',
        url: this.url(),
        data: {
          operation: operation,
          value: member
        },
        success: function(data, status, xhr) {
          Feature.trigger('reload');
          _this.value = data.value;
          if (success_callback) {
            return success_callback(data, status, xhr);
          }
        },
        error: function(data, status, error) {
          var response;
          response = data.responseText ? $.parseJSON(data.responseText) : {
            message: "Something went wrong..."
          };
          alert("ERROR: " + response.message);
          if (error_callback) {
            return error_callback(data, status);
          }
        }
      };
      return $.ajax(options);
    };

    Gate.prototype.save = function(opts) {
      var result;
      result = Gate.__super__.save.apply(this, arguments);
      this.ajaxSave(opts);
      Feature.trigger('reload');
      return result;
    };

    Gate.prototype.ajaxSave = function(opts) {
      var options,
        _this = this;
      options = {
        type: 'POST',
        url: this.url(),
        data: {
          value: this.value
        },
        error: function(data, status, error) {
          var response;
          response = data.responseText ? $.parseJSON(data.responseText) : {
            message: "Something went wrong..."
          };
          return alert("ERROR: " + response.message);
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
      this.feature_list = new App.FeatureList({
        el: $('#features')
      });
    }

    return App;

  })(Spine.Controller);

  App.FeatureList = (function(_super) {

    __extends(FeatureList, _super);

    function FeatureList() {
      this.reload = __bind(this.reload, this);

      this.addAll = __bind(this.addAll, this);

      this.addOne = __bind(this.addOne, this);

      var _this = this;
      FeatureList.__super__.constructor.apply(this, arguments);
      this.feature_controllers = {};
      Feature.bind("refresh", this.addAll);
      Feature.bind("reload", this.reload);
      Feature.one('refresh', function() {
        return Spine.Route.setup({
          history: true
        });
      });
      Feature.fetch();
      Spine.Route.add(/features\/(.*)\/(.*)\/?/, function(matches) {
        var controller, params;
        params = {
          id: matches.match[1],
          gate: matches.match[2]
        };
        if (controller = _this.feature_controllers[params.id]) {
          controller.edit();
          return controller.activateGate(params);
        }
      });
      Spine.Route.add(/features\/(.*)\/?/, function(matches) {
        var controller, params;
        params = {
          id: matches.match[1]
        };
        if (controller = _this.feature_controllers[params.id]) {
          controller.edit();
          return controller.openDefaultGate();
        }
      });
    }

    FeatureList.prototype.addOne = function(feature) {
      var controller;
      controller = new App.Feature({
        feature: feature
      });
      this.feature_controllers[feature.id] = controller;
      return this.append(controller.render());
    };

    FeatureList.prototype.addAll = function() {
      var all_features, feature, _i, _len, _results;
      this.html('');
      $('#no_features').hide();
      all_features = Feature.all();
      if (all_features.length > 0) {
        _results = [];
        for (_i = 0, _len = all_features.length; _i < _len; _i++) {
          feature = all_features[_i];
          _results.push(this.addOne(feature));
        }
        return _results;
      } else {
        return $('#no_features').show();
      }
    };

    FeatureList.prototype.reload = function() {
      Feature.fetch();
      return this.addAll;
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
      return this.navigate("" + Flipper.Config.url + "/features/" + this.feature.id);
    };

    Feature.prototype.openDefaultGate = function() {
      return this.navigate("" + Flipper.Config.url + "/features/" + this.feature.id + "/boolean");
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
      return this.navigate("" + Flipper.Config.url + "/features/" + this.feature.id + "/" + name);
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
      return this.navigate("" + Flipper.Config.url + "/");
    };

    return Feature;

  })(Spine.Controller);

  App.Gate = (function(_super) {

    __extends(Gate, _super);

    function Gate() {
      Gate.__super__.constructor.apply(this, arguments);
      this.active(this.renderForParams);
    }

    Gate.prototype.renderForParams = function(params) {
      this.feature = Feature.find(params.id);
      this.gate = this.feature.gate(params.gate);
      return this.render();
    };

    Gate.prototype.render = function() {
      var $slider, $slider_value;
      this.html(this.template("#gate-" + (this.name.replace(/_/g, '-')) + "-template", this.gate));
      $slider = $(".slider-range");
      $slider_value = $slider.siblings("input[type='text']");
      $slider.slider({
        range: "min",
        value: this.gate.value,
        min: 0,
        max: 100,
        slide: function(event, ui) {
          $slider_value.val(ui.value);
        }
      });
      $slider_value.val($slider.slider("value"));
      return $slider_value.change(function() {
        $slider.slider("value", $(this).val());
      });
    };

    Gate.prototype.template = function(html_id, context) {
      var source, template;
      source = $(html_id).html();
      template = Handlebars.compile(source);
      return template(context);
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
      this.gate.save();
      return this.navigate("" + Flipper.Config.url + "/");
    };

    return Boolean;

  })(App.Gate);

  App.Gate.Set = (function(_super) {

    __extends(Set, _super);

    function Set() {
      return Set.__super__.constructor.apply(this, arguments);
    }

    Set.prototype.elements = {
      '.disable': 'dom_disable',
      '.members': 'dom_members',
      '[name=value]': 'dom_input'
    };

    Set.prototype.events = {
      'click .disable': 'disable',
      'submit form': 'submit'
    };

    Set.prototype.disable = function(event) {
      var member, value;
      event.preventDefault();
      member = $(event.currentTarget).closest('.member');
      value = member.attr('data-value');
      return this.gate.disableSetMember(value, function(data, status, xhr) {
        return member.remove();
      });
    };

    Set.prototype.submit = function(event) {
      var self, value;
      event.preventDefault();
      value = this.dom_input.val();
      self = this;
      return this.gate.enableSetMember(value, function(data, status, xhr) {
        var html;
        html = self.template("#gate-member-template", value);
        self.dom_members.append(html);
        return self.dom_input.val('');
      });
    };

    return Set;

  })(App.Gate);

  App.Gate.Group = (function(_super) {

    __extends(Group, _super);

    function Group() {
      this.name = 'group';
      Group.__super__.constructor.apply(this, arguments);
    }

    return Group;

  })(App.Gate.Set);

  App.Gate.Actor = (function(_super) {

    __extends(Actor, _super);

    function Actor() {
      this.name = 'actor';
      Actor.__super__.constructor.apply(this, arguments);
    }

    return Actor;

  })(App.Gate.Set);

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

    Percentage.prototype.validate = function() {
      var float_value, valid;
      float_value = parseFloat(this.gate.value);
      valid = true;
      if (isNaN(float_value) || float_value < 0 || float_value > 100) {
        alert("The percentage value provided is not valid");
        valid = false;
      }
      return valid;
    };

    Percentage.prototype.submit = function(event) {
      event.preventDefault();
      this.gate.value = this.input.val();
      if (!this.validate()) {
        return;
      }
      this.gate.save();
      return this.navigate("" + Flipper.Config.url + "/");
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

  App.Gate.PercentageOfTime = (function(_super) {

    __extends(PercentageOfTime, _super);

    function PercentageOfTime() {
      this.name = 'percentage_of_time';
      PercentageOfTime.__super__.constructor.apply(this, arguments);
    }

    return PercentageOfTime;

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
      percentage_of_time: App.Gate.PercentageOfTime
    };

    return GateList;

  })(Spine.Stack);

  jQuery(function() {
    return new App({
      el: $('#app')
    });
  });

}).call(this);
