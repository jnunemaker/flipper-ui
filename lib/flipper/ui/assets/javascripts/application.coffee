$ = jQuery

class Feature extends Spine.Model
  @configure "Feature", "id", "name"
  @extend Spine.Model.Ajax
  @extend
    url: "/flipper/features"

class FeatureList extends Spine.Controller
  constructor: ->
    super
    Feature.bind "refresh", @render

  render: =>
    features = Feature.all()

    source   = $("#feature-template").html()
    template = Handlebars.compile(source)

    @html ''

    for feature in features
      @append template(feature)

class Header extends Spine.Controller

class Content extends Spine.Controller
  constructor: ->
    super

    @feature_list = new FeatureList(el: $('#features'))
    @append @feature_list

class App extends Spine.Controller
  constructor: ->
    super

    @header = new Header(el: $('#header'))
    @content = new Content(el: $('#content'))

    Feature.fetch()
    Feature.one 'refresh', ->
      Spine.Route.setup
        history: true

$ ->
  new App(el: $('#app'))
