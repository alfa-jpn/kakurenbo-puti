require 'spec_helper'

describe KakurenboPuti::ActiveRecordBase do
  define_active_record_model :Parent do |t|
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :OneChild do |t|
    t.integer :parent_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :TwoChild do |t|
    t.integer :one_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :ThreeChild do |t|
    t.integer :two_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :FourChild do |t|
    t.integer :three_child_id
    t.datetime :soft_destroyed_at
  end

  define_active_record_model :FiveChild do |t|
    t.integer :four_child_id
    t.datetime :soft_destroyed_at
  end


  let :parent_class do
    Parent.tap do |klass|
      klass.class_eval { soft_deletable }
    end
  end

  let :one_child_class do
    OneChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:parent]
        belongs_to :parent
      end
    end
  end

  let :two_child_class do
    TwoChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:one_child]
        belongs_to :one_child
      end
    end
  end

  let :three_child_class do
    ThreeChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:two_child]
        belongs_to :two_child
      end
    end
  end

  let :four_child_class do
    FourChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:three_child]
        belongs_to :three_child
      end
    end
  end

  let :five_child_class do
    FiveChild.tap do |klass|
      klass.class_eval do
        soft_deletable dependent_associations: [:four_child]
        belongs_to :four_child
      end
    end
  end

  let :parent do
    parent_class.create!
  end

  let :one_child do
    one_child_class.create!(parent: parent)
  end

  let :two_child do
    two_child_class.create!(one_child: one_child)
  end

  let :three_child do
    three_child_class.create!(two_child: two_child)
  end

  let :four_child do
    four_child_class.create(three_child: three_child)
  end

  let :five_child do
    five_child_class.create(four_child: four_child)
  end


  context 'When delete root' do
    subject do
      parent.soft_destroy
    end

    it 'SoftDestroy dependent tail.' do
      expect {
        subject
      }.to change {
        five_child.soft_destroyed?
      }.from(false).to(true)
    end
  end
end
