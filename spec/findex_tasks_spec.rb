require 'findex/tasks'

describe Findex do
  describe "indexes task" do
    it "should exist" do
      Rake::Task['db:indexes'].should_not be_nil
    end

    it "should default to listing all missing indices"
  end

  it "should create an indexes:boolean task" do
    Rake::Task['db:indexes:boolean'].should_not be_nil
  end

  it "should create an indexes:datetime task" do
    Rake::Task['db:indexes:datetime'].should_not be_nil
  end

  it "should create an indexes:geo task" do
    Rake::Task['db:indexes:geo'].should_not be_nil
  end

  it "should create an indexes:help task" do
    Rake::Task['db:indexes:help'].should_not be_nil
  end

  it "should create an indexes:migration task" do
    Rake::Task['db:indexes:migration'].should_not be_nil
  end

  it "should create an indexes:names task" do
    Rake::Task['db:indexes:names'].should_not be_nil
  end

  it "should create an indexes:perform task" do
    Rake::Task['db:indexes:perform'].should_not be_nil
  end

  it "should create an indexes:primary task" do
    Rake::Task['db:indexes:primary'].should_not be_nil
  end

  it "should create an indexes:relationships task" do
    Rake::Task['db:indexes:relationships'].should_not be_nil
  end

  it "should create an indexes:types task" do
    Rake::Task['db:indexes:types'].should_not be_nil
  end
end