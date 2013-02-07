class Feature extends Spine.Model
  @configure "Feature", "id", "name"
  @extend Spine.Model.Ajax
  @extend url: "/flipper/features"

window.Feature = Feature

class App extends Spine.Controller
  constructor: ->
    super
    @content = new App.Content(el: $('#content'))

window.App = App

class App.Content extends Spine.Controller
  constructor: ->
    super
    @features = new App.Features(el: $('#features'))
    @append @features

class App.Features extends Spine.Controller
  constructor: ->
    super
    Feature.bind "refresh", @addAll
    Feature.fetch()

  addOne: (feature) =>
    feature = new App.Feature(feature: feature)
    @append feature.render()

  addAll: =>
    @html ''
    @addOne feature for feature in Feature.all()

class App.Feature extends Spine.Controller
  constructor: ->
    super
    throw "@feature required" if !@feature?

  render: ->
    @html @template(@feature)

  template: (feature) ->
    source   = $("#feature-template").html()
    template = Handlebars.compile(source)
    template(feature)

jQuery ->
  new App(el: $('#app'))
