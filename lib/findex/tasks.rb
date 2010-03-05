require 'rubygems'
require 'rake'
require 'rake/tasklib'

namespace :db do
  desc 'Finds indexes your application probably needs'
  task :indexes => [:environment, :prepare] do
    indices = @findex.get_indices(:geo, [:name, [:id, :type]], :reflection, [:type, [:boolean, :date, :datetime, :time]])
    @findex.send_indices(indices)
  end

  task :prepare do
    @findex = Findex.new
    @findex.generate_migration = ENV['migration'] == 'true'
    @findex.perform_index = ENV['perform'] == 'true'
    @findex.tables = ENV['tables'] ? ENV['tables'].split(',').map(&:strip) : nil
    Dir[File.join(Rails.root, 'app', 'models', '*.rb')].each do |file|
      load(file)
    end
  end

  namespace :indexes do
    desc 'Finds unindexed boolean columns'
    task :boolean => [:environment, :prepare] do
      @findex.migration_name = 'boolean'
      @findex.send_indices(@findex.get_indices([:type, [:boolean]]))
    end

    desc 'Finds unindexed date, time, and datetime columns'
    task :datetime => [:environment, :prepare] do
      @findex.migration_name = 'datetime'
      @findex.send_indices(@findex.get_indices([:type, [:date, :datetime, :time]]))
    end

    desc 'Finds unindexed geo columns'
    task :geo => [:environment, :prepare] do
      @findex.migration_name = 'geo'
      @findex.send_indices(@findex.get_indices(:geo))
    end

    desc 'Prints instructions on how to use rake:db:indexes'
    task :help do
      puts ''
      puts "  rake db:indexes will generate a list of indexes your application's database may or may not need."
      puts ''
      puts '  To see a list of all indexes it thinks you need, just use rake db:indexes'
      puts ''
      puts "  You can add migration=true to generate a migration file\n  or perform=true to perform the indexing immediately:"
      puts '    `rake db:indexes migration=true`'
      puts ''
      puts '  You can also target specific column types, like so:'
      [:boolean, :datetime, :geo, :relationships].each do |type|
        puts "    `rake db:indexes:#{type}`"
      end
      puts ''
      puts '  You can also filter by column names and types, or by whole tables:'
      puts '    `rake db:indexes:names names=type,state`'
      puts '    `rake db:indexes:types types=integer,decimal`'
      puts '    `rake db:indexes tables=users,posts`'
      puts ''
    end

    desc 'Generates a migration file with the recommended indexes'
    task :migration => :environment do
      @findex.generate_migration = true
      @findex.perform_index = false
      indices = @findex.get_indices(:geo, [:name, [:id, :type]], :reflection, [:type, [:boolean, :date, :datetime, :time]])
      @findex.send_indices(indices)
    end

    desc 'Finds unindexed columns matching the names you supply'
    task :names => [:environment, :prepare] do
      if ENV['names']
        indices = @findex.get_indices([:name, ENV['names'].split(',').map(&:strip).map(&:intern)])
        @findex.send_indices(indices)
      else
        puts ''
        puts '  You must pass in a comma-separated collection of names like so'
        puts '    `rake db:indexes:names names=type,state`'
        puts ''
      end
    end

    desc 'Performs a migration with the recommended indexes'
    task :perform => :environment do
      @findex.generate_migration = false
      @findex.perform_index = true
      indices = @findex.get_indices(:geo, [:name, [:id, :type]], :reflection, [:type, [:boolean, :date, :datetime, :time]])
      @findex.send_indices(indices)
    end

    desc 'Finds unindexed relationship foreign keys'
    task :relationships => [:environment, :prepare] do
      @findex.migration_name = 'relationship'
      @findex.send_indices(@findex.get_indices(:reflection))
    end

    desc 'Finds unindexed columns matching the types you supply'
    task :types => [:environment, :prepare] do
      if ENV['types']
        indices = @findex.get_indices([:type, ENV['types'].split(',').map(&:strip).map(&:intern)])
        @findex.send_indices(indices)
      else
        puts ''
        puts '  You must pass in a comma-separated collection of types like so'
        puts '    `rake db:indexes:types types=integer,decimal`'
        puts ''
      end
    end

  end
end

class Findex
  def check_index(*args)
    index = args.shift
    !args.any?{|array| array.any?{|comparison_index| comparison_index == index}}
  end

  def collect_indices(indices)
    indices.collect{|table, columns| [table, columns.sort{|a, b|
      if a == :id
        -1 
      elsif b == :id
        1
      else
        (a.is_a?(Array) ? a.map(&:to_s).join('_') : a.to_s) <=> (b.is_a?(Array) ? b.map(&:to_s).join('_') : b.to_s)
      end
    }]}.sort{|a, b| a[0].to_s <=> b[0].to_s}
  end

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  def get_indices(*args)
    indices = {}
    ObjectSpace.each_object(Class) do |model|
      next unless model.ancestors.include?(ActiveRecord::Base) && model != ActiveRecord::Base && model.table_exists?
      next if @tables && !@tables.include?(model.table_name.to_s)
      existing_indices = connection.indexes(model.table_name).map{|index| index.columns.length == 1 ? index.columns.first.to_sym : index.columns.map(&:to_sym) }
      args.each do |method, options|
        indices = send("get_model_#{method}_indices", *[model, options, indices, existing_indices].compact)
      end
    end
    collect_indices(indices)
  end

  def get_model_geo_indices(model, indices, existing_indices)
    indices[model.table_name] ||= []
    parse_columns(model) do |column, column_name|
      if column.type == :decimal && column.name =~ /(lat|lng)/ && model.column_names.include?(alternate_column_name = column.name.gsub(/(^|_)(lat|lng)($|_)/) { "#{$1}#{$2 == 'lat' ? 'lng' : 'lat'}#{$3}"})
        index = [column_name, alternate_column_name.to_sym]
        indices[model.table_name].push([column_name, alternate_column_name.to_sym]) if check_index(index, indices[model.table_name], existing_indices)
      end
    end
    indices
  end

  def get_model_name_indices(model, names, indices, existing_indices)
    indices[model.table_name] ||= []
    parse_columns(model) do |column, column_name|
      if names.include?(column_name) && check_index(column_name, indices[model.table_name], existing_indices)
        indices[model.table_name].push(column_name)
      end
    end
    indices  
  end

  def get_model_reflection_indices(model, indices, existing_indices)
    indices[model.table_name] ||= []
    model.reflections.each do |name, reflection|
      case reflection.macro.to_sym
      when :belongs_to
        foreign_key = reflection.primary_key_name.to_sym
        indices[model.table_name].push(foreign_key) if check_index(foreign_key, indices[model.table_name], existing_indices)
      when :has_and_belongs_to_many
        index = [reflection.primary_key_name.to_sym, reflection.association_foreign_key.to_sym]
        if (table_name = reflection.options[:join_table] || reflection.options['join_table']) && connection.table_exists?(table_name)
          indices[table_name] ||= []
          unless indices[table_name].any?{|existing_index| existing_index == index} || connection.indexes(table_name).map{|join_index| join_index.columns.length == 1 ? join_index.columns.first.to_sym : join_index.columns.map(&:to_sym) }.any?{|existing_index| existing_index == index}
            indices[table_name].push(index)
          end
        end
      end
    end
    indices
  end

  def get_model_type_indices(model, types, indices, existing_indices)
    indices[model.table_name] ||= []
    parse_columns(model) do |column, column_name|
      if types.include?(column.type) && check_index(column_name, indices[model.table_name], existing_indices)
        indices[model.table_name].push(column_name)
      end
    end
    indices
  end

  def parse_columns(model)
    model.columns.reject(&:primary).each{|column| yield(column, column.name.to_sym)} if block_given?
  end

  def send_indices(indices)
    if @generate_migration
      require 'rails_generator'
      migration_path = File.join(RAILS_ROOT, 'db', 'migrate')
      migration_number = 1
      migration_test = "add#{"_#{@migration_name}" if @migration_name}_indexes"
      Dir[File.join(migration_path, '*.rb')].each do |file|
        file = File.basename(file)
        next unless file =~ /^\d+_#{migration_test}(\d+)\.rb$/
        migration_number += 1
      end
      migration_name = "#{migration_test}#{migration_number}"
      Rails::Generator::Base.instance('migration', [migration_name], {:command => :create, :generator => 'migration'}).command(:create).invoke!
      if migration = Dir[File.join(migration_path, "*#{migration_name}.rb")].first
        migration_up = []
        migration_down = []
        indices.sort{|a, b| a[0].to_s <=> b[0].to_s}.each do |table, columns|
          next if columns.empty?
          index_up = []
          index_down = []
          index_up.push("\s\s\s\s# Indices for `#{table}`")
          index_down.push("\s\s\s\s# Remove indices for `#{table}`")
          columns.each do |column|
            index_up.push("\s\s\s\sadd_index :#{table}, #{column.inspect}")
            index_down.push("\s\s\s\sremove_index :#{table}, #{column.inspect}")
          end
          migration_up.push(index_up.join("\n"))
          migration_down.push(index_down.join("\n"))
        end
        migration_contents = File.read(migration).gsub("def self.up", "def self.up\n#{migration_up.join("\n\n")}").gsub("def self.down", "def self.down\n#{migration_down.join("\n\n")}")
        File.open(migration, 'w+') do |file|
          file.puts migration_contents
         end
      end
    else
      indices.sort{|a, b| a[0].to_s <=> b[0].to_s}.each do |table, columns|
        next if columns.empty?
        puts "\s\s# Indices for `#{table}`"
        columns.each do |column|
          if @perform_index
            ActiveRecord::Migration.add_index(table, column)
          else
            puts "\s\sadd_index :#{table}, #{column.inspect}"
          end
        end
        puts ''
      end
    end
  end

  def generate_migration=(value)
    @generate_migration = !!value
  end

  def perform_index=(value)
    @perform_index = !!value
  end

  def tables=(tables)
    @tables = tables
  end

  def migration_name=(value)
    @migration_name = value
  end
end