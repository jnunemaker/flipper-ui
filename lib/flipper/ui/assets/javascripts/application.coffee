class Feature extends Spine.Model
  @configure "Feature", "id", "name", "state", "description", "gates"
  @extend Spine.Model.Ajax
  @extend url: "#{Flipper.Config.url}/features"

  constructor: ->
    super
    @gates = @gates.map (data) =>
      data.feature_id = @id
      new Gate(data)

  gate: (name) ->
    gates = @gates.filter (gate) ->
      gate.name == name
    gates[0]

window.Feature = Feature

class Gate extends Spine.Model
  @configure "Gate", "feature_id", "key", "name", "value"

  constructor: ->
    super

  url: ->
    "#{Flipper.Config.url}/features/#{encodeURIComponent @feature_id}/#{encodeURIComponent @name}"

  disableSetMember: (member, success_callback, error_callback) ->
    @setMember('disable', member, success_callback, error_callback)

  enableSetMember: (member, success_callback, error_callback) ->
    @setMember('enable', member, success_callback, error_callback)

  setMember: (operation, member, success_callback, error_callback) ->
    options =
      type: 'POST'
      url: @url()
      data:
        operation: operation
        value: member
      success: (data, status, xhr) =>
        @value = data.value
        success_callback(data, status, xhr) if success_callback
      error: (data, status, error) =>
        response = if data.responseText then $.parseJSON data.responseText else message: "Something went wrong..."
        alert "ERROR: #{response.message}"
        error_callback(data, status) if error_callback

    $.ajax options

  save: (opts) ->
    result = super
    @ajaxSave(opts)
    result

  ajaxSave: (opts) ->
    options =
      type: 'POST'
      url: @url()
      data:
        value: @value
      error: (data, status, error) =>
        response = if data.responseText then $.parseJSON data.responseText else message: "Something went wrong..."
        alert "ERROR: #{response.message}"

    $.ajax options

class App extends Spine.Controller
  constructor: ->
    super
    @feature_list = new App.FeatureList(el: $('#features'))

class App.FeatureList extends Spine.Controller
  constructor: ->
    super
    @feature_controllers = {}
    Feature.bind "refresh", @addAll

    Feature.one 'refresh', ->
      Spine.Route.setup
        history: true

    Feature.fetch()

    Spine.Route.add /features\/(.*)\/(.*)\/?/, (matches) =>
      params =
        id: matches.match[1]
        gate: matches.match[2]
      if controller = @feature_controllers[params.id]
        controller.edit()
        controller.activateGate(params)

    Spine.Route.add /features\/(.*)\/?/, (matches) =>
      params =
        id: matches.match[1]
      if controller = @feature_controllers[params.id]
        controller.edit()
        controller.openDefaultGate()

  addOne: (feature) =>
    controller = new App.Feature(feature: feature)
    @feature_controllers[feature.id] = controller
    @append controller.render()

  addAll: =>
    @html ''
    $('#no_features').hide()
    all_features = Feature.all()
    if all_features.length > 0
      @addOne feature for feature in all_features
    else
      $('#no_features').show()

class App.Feature extends Spine.Controller
  elements:
    '.feature': 'dom_feature'
    '.gates': 'dom_gates'

  events:
    'click .show-settings': 'openFeature'
    'click .hide-settings': 'hide'
    'click [data-tab]': 'clickTab'

  constructor: ->
    super
    throw "@feature required" if !@feature?

  render: ->
    @html @template(@feature)
    @gate_list = new App.GateList
      el: @dom_gates
    @el

  openFeature: (event) ->
    event.preventDefault() if event
    @navigate "#{Flipper.Config.url}/features/#{@feature.id}"

  openDefaultGate: ->
    @navigate "#{Flipper.Config.url}/features/#{@feature.id}/boolean"

  template: (feature) ->
    source   = $("#feature-template").html()
    template = Handlebars.compile(source)
    template(feature)

  clickTab: (event) ->
    event.preventDefault()
    tab = $(event.currentTarget)
    name = tab.attr('data-tab')
    @navigate "#{Flipper.Config.url}/features/#{@feature.id}/#{name}"

  activateGate: (params) ->
    name = params.gate
    @gate_list[name].active(params)
    @el.find('[data-tab]').removeClass('active')
    @el.find("[data-tab=#{name}]").addClass('active')

  edit: (event) ->
    event.preventDefault() if event
    @dom_feature.addClass('settings')

  hide: (event) ->
    event.preventDefault() if event
    @dom_feature.removeClass('settings')
    @navigate Flipper.Config.url

class App.Gate extends Spine.Controller
  constructor: ->
    super
    @active @renderForParams

  renderForParams: (params) ->
    @feature = Feature.find(params.id)
    @gate = @feature.gate(params.gate)
    @render()

  render: ->
    @html @template("#gate-#{@name.replace(/_/g, '-')}-template", @gate)

  template: (html_id, context) ->
    source   = $(html_id).html()
    template = Handlebars.compile(source)
    template(context)

class App.Gate.Boolean extends App.Gate
  elements:
    'input[value=true]': 'input'

  events:
    'submit form': 'submit'

  constructor: ->
    @name = 'boolean'
    super

  submit: (event) ->
    event.preventDefault()
    @gate.value = @input.is(':checked')
    @gate.save()

class App.Gate.Set extends App.Gate
  elements:
    '.disable': 'dom_disable'
    '.members': 'dom_members'
    'input[type=text]': 'dom_input'

  events:
    'click .disable': 'disable'
    'submit form': 'submit'

  disable: (event) ->
    event.preventDefault()
    member = $(event.currentTarget).closest('.member')
    value = member.attr('data-value')
    @gate.disableSetMember value, (data, status, xhr) ->
      member.remove()

  submit: (event) ->
    event.preventDefault()
    value = @dom_input.val()
    self = @

    @gate.enableSetMember value, (data, status, xhr) -> 
      html = self.template "#gate-member-template", value
      self.dom_members.append html
      self.dom_input.val ''

class App.Gate.Group extends App.Gate.Set
  constructor: ->
    @name = 'group'
    super

class App.Gate.Actor extends App.Gate.Set
  constructor: ->
    @name = 'actor'
    super

class App.Gate.Percentage extends App.Gate
  elements:
    'input[type=text]': 'input'

  events:
    'submit form': 'submit'

  validate: ()->
    float_value = parseFloat(@gate.value)
    valid = true

    if isNaN(float_value) || float_value < 0 || float_value > 100
      alert "The percentage value provided is not valid"
      valid = false

    return valid

  submit: (event) ->
    event.preventDefault()
    @gate.value = @input.val()
    return unless @validate()
    @gate.save()

class App.Gate.PercentageOfActors extends App.Gate.Percentage
  constructor: ->
    @name = 'percentage_of_actors'
    super

class App.Gate.PercentageOfRandom extends App.Gate.Percentage
  constructor: ->
    @name = 'percentage_of_random'
    super

class App.GateList extends Spine.Stack
  controllers:
    boolean: App.Gate.Boolean
    group: App.Gate.Group
    actor: App.Gate.Actor
    percentage_of_actors: App.Gate.PercentageOfActors
    percentage_of_random: App.Gate.PercentageOfRandom

jQuery ->
  new App(el: $('#app'))
