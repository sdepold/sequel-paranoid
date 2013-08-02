require 'spec_helper'

describe Sequel::Plugins::Paranoid do
  before do
    SpecModel.dataset.delete
    SpecFragment.dataset.delete

    @instance1 = SpecModel.create :name => 'foo'
    @instance2 = SpecModel.create :name => 'bar'
  end

  context "without deletions" do
    describe "Model.all" do
      it "returns all entries" do
        expect(SpecModel.present.all).to have(2).items
      end
    end

    describe :with_deleted do
      it "returns all entries" do
        expect(SpecModel.all).to have(2).items
      end
    end
  end

  context "with deletion" do
    before do
      @instance1.destroy
    end

    it "doesn't return deleted entries" do
      expect(SpecModel.present.all).to have(1).items
    end

    it "returns deleted entries if the default scope has been extended" do
      expect(SpecModel.all).to have(2).items
    end

    it "marks the deleted entries with a specific timestamp" do
      instance = SpecModel.where(:id => @instance1.id).first
      expect(instance.deleted_at).to_not be_nil
    end

    describe :deleted do
      it "returns the deleted entries only" do
        instances = SpecModel.deleted.all

        expect(instances).to have(1).item
        expect(instances.first.deleted_at).to_not be_nil
      end
    end

    describe :present do
      it "returns the not deleted entries only" do
        instances = SpecModel.present.all

        expect(instances).to have(1).item
        expect(instances.first.deleted_at).to be_nil
      end
    end
  end

  describe "callbacks" do
    it "executes the before_destroy callback" do
      @instance1.destroy
      expect(@instance1.before_destroy_value).to be_true
    end

    it "executes the after_destroy callback" do
      @instance1.destroy
      expect(@instance1.after_destroy_value).to be_true
    end
  end

  describe :recover do
    before do
      @instance1.destroy
    end

    it "undeletes an instance" do
      expect(SpecModel.present.all).to have(1).item
      @instance1.recover
      expect(SpecModel.present.all).to have(2).items
    end
  end

  describe :with_deleted do
    it "returns all instances" do
      @instance1.destroy
      expect(SpecModel.all).to have(2).items
    end

    it "works with scopes" do
      @instance1.destroy
      expect(SpecModel.dataset.with_deleted.all).to have(2).items
    end

    context "associations" do
      before do
        @fragment1 = SpecFragment.create(:name => 'fragment1')
        @fragment2 = SpecFragment.create(:name => 'fragment2')
        @fragment3 = SpecFragment.create(:name => 'fragment3')

        @instance1.add_spec_fragment @fragment1
        @instance1.add_spec_fragment @fragment2
        @instance2.add_spec_fragment @fragment3

        @fragment2.destroy
      end

      it "returns only fragments of instance1" do
        dataset = @instance1.spec_fragments_dataset
        expect(dataset.all).to have(2).items
      end
    end
  end

  describe :deleted? do
    before do
      @instance1.destroy
    end

    it "returns false if deleted_at is not null" do
      expect(@instance1.deleted?).to be_true
    end

    it "returns false if deleted_at is null" do
      expect(@instance2.deleted?).to be_false
    end
  end

  describe :default_scope do
    before do
      SpecModelWithDefaultScope.dataset.delete

      @instance1 = SpecModelWithDefaultScope.create(:name => 'foo')
      @instance2 = SpecModelWithDefaultScope.create(:name => 'bar')
    end

    it "does not return the deleted instances" do
      @instance1.destroy
      expect(SpecModelWithDefaultScope.all).to have(1).item
    end
  end

  describe :deleted_by do
    before do
      SpecModelWithDeletedBy.dataset.delete

      @instance = SpecModelWithDeletedBy.create(:name => 'foo')
    end

    it "does not save the deleted_by attributes if not passed to destroy" do
      @instance.destroy
      expect(@instance.reload.deleted_by).to be_nil
    end

    it "saves the deleted_by_attribute if passed to destroy" do
      @instance.destroy(:deleted_by => 'John Doe')
      expect(@instance.reload.deleted_by).to eq("John Doe")
    end

    it "gets deleted when the instance is recovered" do
      @instance.destroy(:deleted_by => 'John Doe')
      expect(@instance.reload.deleted_by).to eq("John Doe")
      @instance.recover
      expect(@instance.reload.deleted_by).to be_nil
    end
  end
end
