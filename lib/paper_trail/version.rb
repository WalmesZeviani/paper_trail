class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  validates_presence_of :event

  def reify
    unless object.nil?
      # Attributes

      attrs = YAML::load object

      # Normally a polymorphic belongs_to relationship allows us
      # to get the object we belong to by calling, in this case,
      # +item+.  However this returns nil if +item+ has been
      # destroyed, and we need to be able to retrieve destroyed
      # objects.
      #
      # Therefore we constantize the +item_type+ to get hold of
      # the class...except when the stored object's attributes
      # include a +type+ key.  If this is the case, the object
      # we belong to is using single table inheritance and the
      # +item_type+ will be the base class, not the actual subclass.
      # So we delve into the object's attributes for the +type+
      # and constantize that.

      class_name = attrs['type']
      class_name = item_type if class_name.blank?
      klass = class_name.constantize
      model = klass.new

      attrs.each do |k, v|
        begin
          model.send "#{k}=", v
        rescue NoMethodError
          RAILS_DEFAULT_LOGGER.warn "Attribute #{k} does not exist on #{item_type} (Version id: #{id})."
        end
      end

      # Associations

      # set the reified model's has_one associations to the current item's if possible.
      # NOTE: with this implementation we can't restore a destroyed item's associations.
      # TODO: test
      if item
        klass.send(:reflect_on_all_associations, :has_one).map(&:name).each do |assoc|
          model.send "#{assoc}=", item.send(assoc)
        end
      end

      model
    end
  end
end
