require 'spec_helper'
include DeadlySerious::Engine

describe Commands do
  test_file = '/tmp/deadly_serious_test_file'
  result_file = '/tmp/deadly_serious_result_file'
  tee_file = '/tmp/deadly_serious_tee_file'

  before do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
    FileUtils.rm_rf(tee_file)
  end

  after do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
    FileUtils.rm_rf(tee_file)
  end

  describe '#spawn_tee' do
    it 'fills a third file' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_tee(tee_file)
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[1, 'a'], [2, 'b']]
      expect(tee_file).to have_content [[1, 'a'], [2, 'b']]
    end

    it 'executes a parallel line' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_tee do
          p.to_file(tee_file)
        end
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[1, 'a'], [2, 'b']]
      expect(tee_file).to have_content [[1, 'a'], [2, 'b']]
    end
  end

  describe '#spawn_lambda' do
    it 'executes a lambda' do
      pipeline = Pipeline.new do |p|
        p.spawn_lambda do
          `touch #{test_file}`
        end
      end
      expect(test_file).to_not exists
      pipeline.run
      expect(test_file).to exists
    end

    it 'transforms when receives reader and writer' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda do |reader:, writer:|
          reader.each { |n, v| writer << [v, n] }
        end
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [['a', 1], ['b', 2]]
    end

    it 'transforms when receives writer' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda do |n, v, writer:|
          writer << [v, n]
        end
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [['a', 1], ['b', 2]]
    end

    it 'transforms when no writer' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| [v, n] }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [['a', 1], ['b', 2]]
    end

    it 'filters when "real true" returns' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| n % 2 == 0 }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[2, 'b']]
    end

    it 'transforms when thruthy, but no "real true" returns' do
      create_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| n % 2 }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[1], [0]]
    end

    it 'filters on "nil" values' do
      create_file(test_file, [[nil], ['a_value']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |it| it }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [['a_value']]
    end
  end
end