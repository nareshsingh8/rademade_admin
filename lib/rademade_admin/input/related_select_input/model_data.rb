# -*- encoding : utf-8 -*-
module RademadeAdmin
  module Input
    class RelatedSelectInput
      module ModelData

        protected

        def model
          @model ||= @builder.object
        end

        def related_data_item
          @related_data_item ||= begin
            relation_from = options[:relation_from] || model.class
            model_info = Model::Graph.instance.model_info(relation_from)
            @related_data_item = model_info.data_items.data_item(attribute_name)
          end
        end

        def related_to
          related_data_item.relation.to || related_value.class
        end

        def relation_getter
          related_data_item.getter
        end

        def multiple?
          related_data_item.relation.has_many?
        end

        def related_value
          @related_value ||= begin
            if model.nil?
              if options[:selected].present?
                related_data_item.relation.related_entities(options[:selected])
              else
                multiple? ? [] : nil
              end
            else
              model.send(relation_getter)
            end
          end
        end

      end
    end
  end
end