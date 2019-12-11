require 'spec_helper'

describe '#define_active_record_model' do
  define_active_record_model :Drink do |t|
    t.integer :price
  end

  it 'creates class Drink.' do
    expect(Object.const_defined? :Drink).to be_truthy
  end

  describe 'created class' do
    it 'has methods of ActiveRecord.' do
      expect(Drink).to respond_to(:create, :find, :where, :update_all)
    end
  end
end
