require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class FeaturesApi < UI::Action

        route %r{api/features/?\Z}

        def get
          features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }.sort_by(&:pretty_name)

          json_response features.map(&:as_json)
        end

        def post
          feature_name = params["value"]
          feature_names = flipper.features.map { |feature| feature.name.to_s }

          if Util.blank?(feature_name)
            response = {
              status: "error",
              message: "#{feature_name.inspect} is not a valid feature name.",
            }
            status 422
            json_response response
          elsif feature_names.include?(feature_name)
            response = {
              status: "error",
              message: "#{feature_name.inspect} already exists.",
            }
            status 422
            json_response response
          else
            status 201
            feature = flipper[feature_name]
            flipper.adapter.add(feature)
            json_response Decorators::Feature.new(feature).as_json
          end
        end
      end
    end
  end
end
