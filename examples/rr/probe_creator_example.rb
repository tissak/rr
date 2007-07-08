dir = File.dirname(__FILE__)
require "#{dir}/../example_helper"

module RR
describe ProbeCreator, :shared => true do
  before(:each) do
    @space = Space.new
    @subject = Object.new
  end

  it "initializes creator with passed in object" do
    class << @creator
      attr_reader :subject
    end
    @creator.subject.should === @subject
  end
end

describe ProbeCreator, ".new without block" do
  it_should_behave_like "RR::ProbeCreator"

  before do
    @creator = ProbeCreator.new(@space, @subject)
  end
end

describe ProbeCreator, ".new with block" do
  it_should_behave_like "RR::ProbeCreator"

  before do
    def @subject.foobar(*args)
      :original_foobar
    end
    @creator = ProbeCreator.new(@space, @subject) do |c|
      c.foobar(1, 2)
      c.foobar(1)
      c.foobar.with_any_args
    end
  end

  it "creates doubles" do
    @subject.foobar(1, 2).should == :original_foobar
    @subject.foobar(1).should == :original_foobar
    @subject.foobar(:something).should == :original_foobar
    proc {@subject.foobar(:nasty)}.should raise_error
  end
end

describe ProbeCreator, ".new where method takes a block" do
  it_should_behave_like "RR::ProbeCreator"

  before do
    def @subject.foobar(*args, &block)
      yield(*args)
    end
    @creator = ProbeCreator.new(@space, @subject)
  end

  it "calls the block" do
    @creator.foobar(1, 2)
    @subject.foobar(1, 2) {|arg1, arg2| [arg2, arg1]}.should == [2, 1]
  end
end


describe ProbeCreator, "#method_missing" do
  it_should_behave_like "RR::ProbeCreator"
  
  before do
    @subject = Object.new
    @creator = ProbeCreator.new(@space, @subject)
  end

  it "sets expectations on the subject while calling the original method" do
    def @subject.foobar(*args); :baz; end
    @creator.foobar(1, 2).twice
    @subject.foobar(1, 2).should == :baz
    @subject.foobar(1, 2).should == :baz
    proc {@subject.foobar(1, 2)}.should raise_error(Errors::TimesCalledError)
  end
end

end