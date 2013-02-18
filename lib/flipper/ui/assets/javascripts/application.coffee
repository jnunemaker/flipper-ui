class Feature extends Spine.Model
  @configure "Feature", "id", "name", "state", "description", "gates"
  @extend Spine.Model.Ajax
  @extend url: "/flipper/features"

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
    "/flipper/features/#{encodeURIComponent @feature_id}/#{encodeURIComponent @name}"

  disableSetMember: (member) ->
    options =
      type: 'POST'
      url: @url()
      data:
        operation: 'disable'
        value: member
      success: (data, status, xhr) =>
        @value = data.value
    $.ajax options

  enableSetMember: (member) ->
    options =
      type: 'POST'
      url: @url()
      data:
        operation: 'enable'
        value: member
      success: (data, status, xhr) =>
        @value = data.value
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
    $.ajax options

class App extends Spine.Controller
  constructor: ->
    super
    @features = new App.FeatureList(el: $('#features'))

class App.FeatureList extends Spine.Controller
  constructor: ->
    super
    @features = {}
    Feature.bind "refresh", @addAll

    Feature.one 'refresh', ->
      Spine.Route.setup
        history: true

    Feature.fetch()

    @routes
      '/flipper/features/:id': (params) ->
        if controller = @features[params.id]
          controller.edit()
          controller.openDefaultGate()

      '/flipper/features/:id/:gate': (params) ->
        if controller = @features[params.id]
          controller.edit()
          controller.activateGate(params)

  addOne: (feature) =>
    controller = new App.Feature(feature: feature)
    @features[feature.id] = controller
    @append controller.render()

  addAll: =>
    @html ''
    @addOne feature for feature in Feature.all()

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
    @navigate "/flipper/features/#{@feature.id}"

  openDefaultGate: ->
    @navigate "/flipper/features/#{@feature.id}/boolean"

  template: (feature) ->
    source   = $("#feature-template").html()
    template = Handlebars.compile(source)
    template(feature)

  clickTab: (event) ->
    event.preventDefault()
    tab = $(event.currentTarget)
    name = tab.attr('data-tab')
    @navigate "/flipper/features/#{@feature.id}/#{name}"

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
    @navigate '/flipper'

class App.Gate extends Spine.Controller
  constructor: ->
    super
    @active @renderForParams
    Gate.bind 'save', @saved

  saved: (data) ->
    console.log 'saved', data

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
    @gate.disableSetMember value
    member.remove()

  submit: (event) ->
    event.preventDefault()
    value = @dom_input.val()
    @gate.enableSetMember value
    html = @template "#gate-member-template", value
    @dom_members.append html
    @dom_input.val ''

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

  submit: (event) ->
    event.preventDefault()
    @gate.value = @input.val()
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
