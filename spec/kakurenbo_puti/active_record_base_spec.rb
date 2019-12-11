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
    it 'returns default column name to be soft-deleted' do
      expect(model_class.soft_delete_column).to eq(:soft_destroyed_at)
    end

    context "when the option 'column' is present and the option is passed as an argument of 'soft_deletable'" do
      let :model_class_options do
        { column: :deleted_at }
      end

      it 'returns column name given to option' do
        expect(model_class.soft_delete_column).to eq(model_class_options[:column])
      end
    end
  end

  describe '.only_soft_destroyed' do
    subject do
      child_class.only_soft_destroyed
    end

    context 'When soft-deleted' do
      it 'returns a relation only with soft-deleted records.' do
        expect {
          child_instance.soft_destroy!
        }.to change {
          subject.count
        }.by(1)
      end
    end

    context 'When the instance of parent_class is soft-deleted' do
      it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are included.' do
        expect {
          child_instance.soft_delete_model.soft_destroy!
        }.to change {
          subject.count
        }.by(1)
      end

      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are not included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    context 'When the instance of parent_class is hard-deleted' do
      it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are included.' do
        expect {
          child_instance.normal_model.destroy!
        }.to change {
          subject.count
        }.by(1)
      end

      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are not included.' do
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

    context "when the option 'dependent_associations' is an array and an association name as an argument of `has_many` is included" do
      subject do
        model_class.without_soft_destroyed
      end

      let :model_class_options do
        { dependent_associations: [:soft_delete_children] }
      end

      it 'raises error' do
        expect { subject }.to raise_error
      end
    end

    context 'When soft-deleted' do
      it 'returns a relation without soft-deleted records.' do
        expect {
          child_instance.soft_destroy!
        }.to change {
          subject.count
        }.by(-1)
      end
    end

    context 'When the instance of parent_class is soft-deleted' do
      it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are not included.' do
        expect {
          child_instance.soft_delete_model.soft_destroy!
        }.to change {
          subject.count
        }.by(-1)
      end

      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    context 'When the instance of parent_class is hard-deleted' do
      it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are not included.' do
        expect {
          child_instance.normal_model.destroy!
        }.to change {
          subject.count
        }.by(-1)
      end

      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are included.' do
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

    it 'restores soft-deleted record.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(1)
    end

    it 'returns truethy value.' do
      expect(subject).to be_truthy
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When an exception is raised.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'returns falsey value.' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#restore!' do
    subject do
      model_instance.restore!
    end

    context 'When an exception is raised.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'raises an error.' do
        expect{ subject }.to raise_error
      end
    end
  end

  describe '#soft_destroy' do
    subject do
      model_instance.soft_destroy
    end

    it 'soft-deletes record.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(-1)
    end

    it 'returns truethy value.' do
      expect(subject).to be_truthy
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When an exception is raised.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:touch) { raise }
      end

      it 'returns falsey value.' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#soft_delete!' do
    subject do
      model_instance.soft_delete!
    end

    context 'When an exception is raised.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise }
      end

      it 'raises an error.' do
        expect{ subject }.to raise_error
      end
    end
  end

  describe '#soft_destroyed?' do
    subject do
      model_instance.soft_destroyed?
    end

    it 'returns falsey value' do
      expect(subject).to be_falsey
    end

    context 'When model is soft-deleted' do
      before :each do
        model_instance.soft_destroy!
      end

      it 'returns truthy value' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '.soft_destroy_all' do
    subject do
      model_class.soft_destroy_all
    end
    let!(:model_instance) { model_class.create! }

    it 'soft-deletes records' do
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

      it 'soft-deletes records' do
        expect {
          subject
        }.to change {
          model_class.without_soft_destroyed.count
        }.to(0)
      end
    end
  end
end
