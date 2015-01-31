module KakurenboPuti
  # Extension module of ActiveRecord::Base
  module ActiveRecordBase
    # Enable soft-delete.
    # @raise [StandardException] if Not found soft-deleted date column.
    #
    # @param [Symbol]        column                 name of soft-deleted date column.
    # @param [Array<Symbol>] dependent_associations names of dependency association.
    def soft_deletable(column: :soft_destroyed_at, dependent_associations: [])
      raise "`#{column}` is not defined in #{self.class.name}." unless column_names.include?(column.to_s)

      define_singleton_method(:soft_delete_column) { column }
      delegate :soft_delete_column, to: :class

      define_model_callbacks :restore
      define_model_callbacks :soft_destroy

      scope :only_soft_destroyed, -> { where.not(id: without_soft_destroyed.select(:id)) }
      scope :without_soft_destroyed, (lambda do
        dependent_associations.inject(where(soft_delete_column => nil)) do |relation, name|
          association = relation.klass.reflect_on_all_associations.find{|a| a.name == name }
          if association.klass.method_defined?(:soft_delete_column)
            relation.joins(name).merge(association.klass.without_soft_destroyed).references(name)
          else
            relation.joins(name).references(name)
          end
        end
      end)

      include InstanceMethods
    end

    module InstanceMethods
      # Restore model.
      # @return [Boolean] Return true if it is success.
      def restore
        true.tap { restore! }
      rescue
        false
      end

      # Restore model.
      # @raise [ActiveRecordError]
      def restore!
        run_callbacks(:restore) { update_column soft_delete_column, nil; self }
      end

      # Soft-Delete model.
      # @return [Boolean] Return true if it is success.
      def soft_destroy
        true.tap { soft_destroy! }
      rescue
        false
      end

      # Soft-Delete model.
      # @raise [ActiveRecordError]
      def soft_destroy!
        run_callbacks(:soft_destroy) { touch soft_delete_column; self }
      end

      # Check if model is soft-deleted.
      # @return [Boolean] Return true if model is soft-deleted.
      def soft_destroyed?
        self.class.only_soft_destroyed.where(id: id).exists?
      end
    end
  end
end
