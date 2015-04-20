require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class AddGroup < UI::Action
        route %r{features/[^/]*/groups/?\Z}

        def get
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          breadcrumb "Features", "/features"
          breadcrumb @feature.key, "/features/#{@feature.key}"
          breadcrumb "Add Group"

          view_response :add_group
        end

        def post
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          group_name = params["value"]

          case params["operation"]
          when "enable"
            feature.enable_group group_name
          when "disable"
            feature.disable_group group_name
          end

          redirect_to("/features/#{feature.key}")
        rescue Flipper::GroupNotRegistered => e
          error = Rack::Utils.escape("The group named #{group_name.inspect} has not been registered.")
          redirect_to("/features/#{feature.key}/groups?error=#{error}")
        end
      end
    end
  end
end
