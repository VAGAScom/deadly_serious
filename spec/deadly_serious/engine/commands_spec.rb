require 'spec_helper'
include DeadlySerious::Engine

describe Commands do
  test_file = '/tmp/deadly_serious_test_file'

  before do
    FileUtils.rm_rf(test_file)
  end

  after do
    FileUtils.rm_rf(test_file)
  end

  it 'spawns lambdas' do
    pipeline = Pipeline.new do |p|
      p.spawn_lambda do
        `touch #{test_file}`
      end
    end
    expect(test_file).to_not exists
    pipeline.run
    expect(test_file).to exists
  end
end