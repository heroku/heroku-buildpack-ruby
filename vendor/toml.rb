require "ostruct"
require "date"

# From charlie Somerville
# https://github.com/charliesome/toml2
# https://github.com/hone/toml2
#
# Cloned and patched
module TOML
  def self.safe_load
    raise NotImplementedError, "whoops"
  end

  def self.load(__toml)
    __b = binding
    __b.eval(to_ruby(__toml))
    hashize(binding_vars(__b))
  end

  class << self
  private
    def _section(mergee)
      b = nil
      c = Object.new
      c.singleton_class.send(:define_method, :[]) { |b_| b = b_ }
      yield c
      mergee.merge! binding_vars(b)
    end

    def binding_vars(b)
      Hash[b.eval("local_variables").reject{|v|v[0,2]=="__"}.map{|l| [l, b.eval("#{l}")] }]
    end

    def hashize(obj, seen = {}.compare_by_identity)
      return if seen[obj]
      seen[obj] = true
      case obj
      when OpenStruct; hashize(obj.instance_variable_get(:@table), seen)
      when Hash; Hash[obj.reject{|k,_|k[0, 2] == "__"}.map { |k,v| v = hashize(v, seen); v.nil? ? nil : [k, v] }.compact]
      when Array; obj.map { |v| hashize(v, seen) }.compact
      when Integer, Float, true, false, nil; seen[obj] = false; obj
      else obj
      end
    end

    def to_ruby(toml)
      "if true\n#{toml.gsub(/^\s*\[([a-z0-9_.]+)\]\s*$/i){|sec|" end; #{1.
      upto($1.split(".").length-1).map { |i| "#{$1.split(".")[0...i].join(
      ".")}||=OpenStruct.new"}.join";"}; #{$1} = OpenStruct.new; _section(
      #{$1}.instance_variable_get(:@table)) do |__| __[binding]; " }.gsub(
      /\d{4}(-\d{2}){2}T(\d{2}:){2}\d{2}Z/){|x|"Date.parse(%{#{x}})"}}end"
    end
  end

  # pulled from https://github.com/emancu/toml-rb/blob/master/lib/toml-rb/dumper.rb
  class Dumper
    def initialize(hash)
      @toml_str = ''

      visit(hash, [])
    end

    def to_s
      @toml_str
    end

    private

    def visit(hash, prefix, extra_brackets = false)
      simple_pairs, nested_pairs, table_array_pairs = sort_pairs hash

      if prefix.any? && (simple_pairs.any? || hash.empty?)
        print_prefix prefix, extra_brackets
      end

      dump_pairs simple_pairs, nested_pairs, table_array_pairs, prefix
    end

    def sort_pairs(hash)
      nested_pairs = []
      simple_pairs = []
      table_array_pairs = []

      hash.keys.sort.each do |key|
        val = hash[key]
        element = [key, val]

        if val.is_a? Hash
          nested_pairs << element
        elsif val.is_a?(Array) && val.first.is_a?(Hash)
          table_array_pairs << element
        else
          simple_pairs << element
        end
      end

      [simple_pairs, nested_pairs, table_array_pairs]
    end

    def dump_pairs(simple, nested, table_array, prefix = [])
      # First add simple pairs, under the prefix
      dump_simple_pairs simple
      dump_nested_pairs nested, prefix
      dump_table_array_pairs table_array, prefix
    end

    def dump_simple_pairs(simple_pairs)
      simple_pairs.each do |key, val|
        key = quote_key(key) unless bare_key? key
        @toml_str << "#{key} = #{to_toml(val)}\n"
      end
    end

    def dump_nested_pairs(nested_pairs, prefix)
      nested_pairs.each do |key, val|
        key = quote_key(key) unless bare_key? key

        visit val, prefix + [key], false
      end
    end

    def dump_table_array_pairs(table_array_pairs, prefix)
      table_array_pairs.each do |key, val|
        key = quote_key(key) unless bare_key? key
        aux_prefix = prefix + [key]

        val.each do |child|
          print_prefix aux_prefix, true
          args = sort_pairs(child) << aux_prefix

          dump_pairs(*args)
        end
      end
    end

    def print_prefix(prefix, extra_brackets = false)
      new_prefix = prefix.join('.')
      new_prefix = '[' + new_prefix + ']' if extra_brackets

      @toml_str += "[" + new_prefix + "]\n"
    end

    def to_toml(obj)
      if obj.is_a? Time
        obj.strftime('%Y-%m-%dT%H:%M:%SZ')
      else
        obj.inspect
      end
    end

    def bare_key?(key)
      !!key.to_s.match(/^[a-zA-Z0-9_-]*$/)
    end

    def quote_key(key)
      '"' + key.gsub('"', '\\"') + '"'
    end
  end
end
