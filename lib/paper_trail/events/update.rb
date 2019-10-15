# frozen_string_literal: true

require "paper_trail/events/base"

module PaperTrail
  module Events
    # See docs in `Base`.
    #
    # @api private
    class Update < Base
      # - is_touch - [boolean] - Used in the two situations that are touch-like:
      #   - `after_touch` we call `RecordTrail#record_update`
      #   - `RecordTrail#touch_with_version` (deprecated) calls `RecordTrail#record_update`
      # - force_changes - [Hash] - Only used by `RecordTrail#update_columns`,
      #   because there dirty tracking is off, so it has to track its own changes.
      #
      # @api private
      def initialize(record, in_after_callback, is_touch, force_changes)
        super(record, in_after_callback)
        @is_touch = is_touch
        @changes = force_changes.nil? ? changes : force_changes
      end

      # Return attributes of nascent `Version` record.
      #
      # @api private
      def data
        data = {
          event: @record.paper_trail_event || "update",
          whodunnit: PaperTrail.request.whodunnit
        }
        if @record.respond_to?(:updated_at)
          data[:created_at] = @record.updated_at
        end
        if record_object?
          data[:object] = recordable_object(@is_touch)
        end
        if record_object_changes?
          data[:object_changes] = recordable_object_changes(@changes)
        end
        merge_metadata_into(data)
      end
    end
  end
end
