require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)

    x = table_info.map do |row|
      row["name"]
    end.compact
  end

  def self.find_by_name(find_name)
    sql_find_name = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?
    SQL

    DB[:conn].execute(sql_find_name, find_name)
  end

  def self.find_by(find_by = {})
    sql_find_by = <<-SQL
      SELECT * FROM #{table_name}
      WHERE #{find_by.keys[0].to_s} = '#{find_by.values[0].to_s}'
    SQL

    DB[:conn].execute(sql_find_by)

  end

  def initialize(hash_in = {})
    hash_in.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def save
    #Creates new row in SQL db
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    #Gets new id
    sql_get_id = <<-SQL
      SELECT last_insert_rowid() from #{table_name_for_insert}
    SQL
    self.id = DB[:conn].execute(sql_get_id)[0][0]
  end

  def col_names_for_insert
    self.class.column_names.reject do |col_name|
      col_name == "id"
    end.join(", ")
  end

  def values_for_insert
    # binding.pry
    self.class.column_names.reject do |col_name|
      col_name == "id"
    end.map do |attribute|
      "'#{self.send(attribute)}'"
    end.join(', ')
  end

  def persisted?
    !!self.id
  end




end
