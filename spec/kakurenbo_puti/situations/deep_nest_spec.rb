require 'spec_helper'

describe KakurenboPuti::ActiveRecordBase do
  define_active_record_model :Parent do |t|
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :FirstChild do |t|
    t.integer :parent_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :SecondChild do |t|
    t.integer :first_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :ThirdChild do |t|
    t.integer :second_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :FourthChild do |t|
    t.integer :third_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :FifthChild do |t|
    t.integer :fourth_child_id
    t.datetime :soft_destroyed_at
  end


  let :parent_class do
    Parent.tap do |klass|
      klass.class_eval { soft_deletable }
    end
  end

  let :first_child_class do
    FirstChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:parent]
        belongs_to :parent
      end
    end
  end

  let :second_child_class do
    SecondChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:first_child]
        belongs_to :first_child
      end
    end
  end

  let :third_child_class do
    ThirdChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:second_child]
        belongs_to :second_child
      end
    end
  end

  let :fourth_child_class do
    FourthChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:third_child]
        belongs_to :third_child
      end
    end
  end

  let :fifth_child_class do
    FifthChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:fourth_child]
        belongs_to :fourth_child
      end
    end
  end

  let :parent do
    parent_class.create!
  end

  let :first_child do
    first_child_class.create!(parent: parent)
  end

  let :second_child do
    second_child_class.create!(first_child: first_child)
  end

  let :third_child do
    third_child_class.create!(second_child: second_child)
  end

  let :fourth_child do
    fourth_child_class.create(third_child: third_child)
  end

  let :fifth_child do
    fifth_child_class.create(fourth_child: fourth_child)
  end


  context 'When the root instance is deleted' do
    subject do
      parent.soft_destroy
    end

    it 'deletes the tail instance' do
      expect {
        subject
      }.to change {
        fifth_child.soft_destroyed?
      }.from(false).to(true)
    end
  end
end
