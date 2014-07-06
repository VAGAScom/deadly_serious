require 'spec_helper'
include DeadlySerious::Engine

describe Commands do
  test_file = '/tmp/deadly_serious_test_file'
  result_file = '/tmp/deadly_serious_result_file'

  before do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
  end

  after do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
  end

  describe '#spawn_lambda' do
    def put_in_file(file_name, an_array)
      open(file_name, 'w') do |f|
        an_array.each do |data|
          f.puts JSON.generate(data)
        end
      end
    end

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
      put_in_file(test_file, [[1, 'a'], [2, 'b']])
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
      put_in_file(test_file, [[1, 'a'], [2, 'b']])
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
      put_in_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| [v, n] }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [['a', 1], ['b', 2]]
    end

    it 'filters when "real true" returns' do
      put_in_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| n % 2 == 0 }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[2, 'b']]
    end

    it 'transforms when thruthy, but no "real true" returns' do
      put_in_file(test_file, [[1, 'a'], [2, 'b']])
      pipeline = Pipeline.new do |p|
        p.from_file(test_file)
        p.spawn_lambda { |n, v| n % 2 }
        p.to_file(result_file)
      end
      pipeline.run
      expect(result_file).to have_content [[1], [0]]
    end

    it 'filters on "nil" values' do
      put_in_file(test_file, [[nil], ['a_value']])
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