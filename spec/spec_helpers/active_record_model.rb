require 'active_support'

# Use ActiveSupport::Inflector#classify
Inflector = Class.new.extend(ActiveSupport::Inflector)

# Define model of ActiveRecord.
#
# @param [Symbol] Model name.
# @yield [table] Table column definition.
def define_active_record_model(model_name, &block)
  raise 'No block is given to define columns!' unless block_given?

  tableize_name = Inflector.tableize(model_name)

  before :each do
    migration = ActiveRecord::Migration.new
    migration.verbose = false
    migration.create_table tableize_name, &block

    mock_class = Class.new(ActiveRecord::Base) do
      define_singleton_method(:name) { model_name.to_s }
      reset_table_name
    end

    Object.const_set model_name, mock_class
  end

  after :each do
    migration = ActiveRecord::Migration.new
    migration.verbose = false
    migration.drop_table tableize_name

    Object.class_eval { remove_const model_name }
  end
end
