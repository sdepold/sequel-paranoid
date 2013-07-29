require 'spec_helper'

class SpecModel < Sequel::Model
  plugin :paranoid

  attr_accessor :before_destroy_value, :after_destroy_value

  def before_destroy
    @before_destroy_value = true
  end

  def after_destroy
    @after_destroy_value = true
  end
end

describe Sequel::Plugins::Paranoid do
  before do
    SpecModel.unfiltered.delete

    @instance1 = SpecModel.create :name => 'foo'
    @instance2 = SpecModel.create :name => 'bar'
  end

  context "without deletions" do
    describe "Model.all" do
      it "returns all entries" do
        expect(SpecModel.all).to have(2).items
      end
    end

    describe :unfiltered do
      it "returns all entries" do
        expect(SpecModel.unfiltered.all).to have(2).items
      end
    end
  end

  context "with deletion" do
    before do
      @instance1.destroy
    end

    it "doesn't return deleted entries" do
      expect(SpecModel.all).to have(1).items
    end

    it "returns deleted entries if the default scope has been extended" do
      expect(SpecModel.unfiltered.all).to have(2).items
    end

    it "marks the deleted entries with a specific timestamp" do
      instance = SpecModel.unfiltered.where(:id => @instance1.id).first
      expect(instance.deleted_at).to_not be_nil
    end

    describe :deleted do
      it "returns the deleted entries only" do
        instances = SpecModel.deleted.all

        expect(instances).to have(1).item
        expect(instances.first.deleted_at).to_not be_nil
      end
    end

    describe :existing do
      it "returns the not deleted entries only" do
        instances = SpecModel.existing.all

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
end
