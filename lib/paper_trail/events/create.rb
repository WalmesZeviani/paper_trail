# frozen_string_literal: true

require "paper_trail/events/base"

module PaperTrail
  module Events
    # See docs in `Base`.
    #
    # @api private
    class Create < Base
      # Return attributes of nascent `Version` record.
      #
      # @api private
      def data
        data = {
          event: @record.paper_trail_event || "create",
          whodunnit: PaperTrail.request.whodunnit
        }
        if @record.respond_to?(:updated_at)
          data[:created_at] = @record.updated_at
        end
        if record_object_changes? && changed_notably?
          data[:object_changes] = recordable_object_changes(changes)
        end
        merge_metadata_into(data)
      end
    end
  end
end
