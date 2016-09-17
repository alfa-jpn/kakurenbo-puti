require 'spec_helper'

describe KakurenboPuti::ActiveRecordBase do
  define_active_record_model :NormalModel do; end

  define_active_record_model :SoftDeleteModel do |t|
    t.datetime :soft_destroyed_at
    t.datetime :deleted_at
  end

  define_active_record_model :SoftDeleteChild do |t|
    t.integer :soft_delete_model_id
    t.integer :normal_model_id
    t.datetime :soft_destroyed_at
  end

  let :model_class do
    options_cache = model_class_options
    SoftDeleteModel.tap do |klass|
      klass.class_eval do
        soft_deletable options_cache
        has_many :soft_delete_children

        before_soft_destroy :cb_mock
        after_soft_destroy  :cb_mock

        before_restore      :cb_mock
        after_restore       :cb_mock

        define_method(:cb_mock) { true }
      end
    end
  end

  let :child_class do
    options_cache = child_class_options
    SoftDeleteChild.tap do |klass|
      klass.class_eval do
        soft_deletable options_cache
        belongs_to :soft_delete_model
        belongs_to :normal_model
      end
    end
  end

  let :model_class_options do
    {}
  end

  let :child_class_options do
    { dependent_associations: [:soft_delete_model, :normal_model] }
  end

  let! :normal_model_instance do
    NormalModel.create!
  end

  let! :model_instance do
    model_class.create!
  end

  let! :child_instance do
    child_class.create!(soft_delete_model: model_instance, normal_model: normal_model_instance)
  end

  describe '.soft_delete_column' do
    it 'Return column name of soft-delete' do
      expect(model_class.soft_delete_column).to eq(:soft_destroyed_at)
    end

    context 'When with column option' do
      let :model_class_options do
        { column: :deleted_at }
      end

      it 'Return column name of option' do
        expect(model_class.soft_delete_column).to eq(model_class_options[:column])
      end
    end
  end

  describe '.only_soft_destroyed' do
    subject do
      child_class.only_soft_destroyed
    end

    context 'When soft-deleted' do
      it 'Return a relation without soft-deleted model.' do
        expect {
          child_instance.soft_destroy!
        }.to change {
          subject.count
        }.by(1)
      end
    end

    context 'When parent is soft-deleted' do
      it 'Return a relation without parent soft-deleted model.' do
        expect {
          child_instance.soft_delete_model.soft_destroy!
        }.to change {
          subject.count
        }.by(1)
      end

      context 'When dependent association is nothing' do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'Return a relation with parent soft-deleted model.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    context 'When parent is hard-deleted' do
      it 'Return a relation without parent soft-deleted model.' do
        expect {
          child_instance.normal_model.destroy!
        }.to change {
          subject.count
        }.by(1)
      end

      context 'When dependent association is nothing' do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'Return a relation with parent soft-deleted model.' do
          expect {
            child_instance.normal_model.destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end
  end

  describe '.without_soft_destroyed' do
    subject do
      child_class.without_soft_destroyed
    end

    context 'When dependent association use in `has_many`' do
      subject do
        model_class.without_soft_destroyed
      end

      let :model_class_options do
        { dependent_associations: [:soft_delete_children] }
      end

      it 'raise error' do
        expect { subject }.to raise_error
      end
    end

    context 'When soft-deleted' do
      it 'Return a relation without soft-deleted model.' do
        expect {
          child_instance.soft_destroy!
        }.to change {
          subject.count
        }.by(-1)
      end
    end

    context 'When parent is soft-deleted' do
      it 'Return a relation without parent soft-deleted model.' do
        expect {
          child_instance.soft_delete_model.soft_destroy!
        }.to change {
          subject.count
        }.by(-1)
      end

      context 'When dependent association is nothing' do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'Return a relation with parent soft-deleted model.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    context 'When parent is hard-deleted' do
      it 'Return a relation without parent soft-deleted model.' do
        expect {
          child_instance.normal_model.destroy!
        }.to change {
          subject.count
        }.by(-1)
      end

      context 'When dependent association is nothing' do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'Return a relation with parent soft-deleted model.' do
          expect {
            child_instance.normal_model.destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end
  end

  describe '#restore' do
    before :each do
      model_instance.soft_destroy
    end

    subject do
      model_instance.restore
    end

    it 'Restore soft-deleted model.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(1)
    end

    it 'Return truethy value.' do
      expect(subject).to be_truthy
    end

    it 'Run callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When raise exception.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'Return falsey value.' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#restore!' do
    subject do
      model_instance.restore!
    end

    context 'When raise exception.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'Raise Error.' do
        expect{ subject }.to raise_error
      end
    end
  end

  describe '#soft_delete' do
    subject do
      model_instance.soft_destroy
    end

    it 'Soft-delete model.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(-1)
    end

    it 'Return truethy value.' do
      expect(subject).to be_truthy
    end

    it 'Run callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When raise exception.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:touch) { raise }
      end

      it 'Return falsey value.' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#soft_delete!' do
    subject do
      model_instance.soft_delete!
    end

    context 'When raise exception.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'Raise Error.' do
        expect{ subject }.to raise_error
      end
    end
  end

  describe '#soft_destroyed?' do
    subject do
      model_instance.soft_destroyed?
    end

    it 'Return falsey' do
      expect(subject).to be_falsey
    end

    context 'When model is soft-deleted' do
      before :each do
        model_instance.soft_destroy!
      end

      it 'Return truthy' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '.soft_destroy_all' do
    subject do
      model_class.soft_destroy_all
    end
    let!(:model_instance) { model_class.create! }

    it 'SoftDelete model' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.to(0)
    end

    context 'with conditions' do
      subject do
        model_class.soft_destroy_all(id: model_instance.id)
      end

      it 'SoftDelete model' do
        expect {
          subject
        }.to change {
          model_class.without_soft_destroyed.count
        }.to(0)
      end
    end
  end
end
