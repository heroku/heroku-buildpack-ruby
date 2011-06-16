require 'tsort'

module Bundler
  class SpecSet
    include TSort, Enumerable

    def initialize(specs)
      @specs = specs.sort_by { |s| s.name }
    end

    def each
      sorted.each { |s| yield s }
    end

    def length
      @specs.length
    end

    def for(dependencies, skip = [], check = false, match_current_platform = false)
      handled, deps, specs = {}, dependencies.dup, []
      skip << 'bundler'

      until deps.empty?
        dep = deps.shift
        next if handled[dep] || skip.include?(dep.name)

        spec = lookup[dep.name].find do |s|
          match_current_platform ?
            Gem::Platform.match(s.platform) :
            s.match_platform(dep.__platform)
        end

        handled[dep] = true

        if spec
          specs << spec

          spec.dependencies.each do |d|
            next if d.type == :development
            d = DepProxy.new(d, dep.__platform) unless match_current_platform
            deps << d
          end
        elsif check
          return false
        end
      end

      if spec = lookup['bundler'].first
        specs << spec
      end

      check ? true : SpecSet.new(specs)
    end

    def valid_for?(deps)
      self.for(deps, [], true)
    end

    def [](key)
      key = key.name if key.respond_to?(:name)
      lookup[key].reverse
    end

    def []=(key, value)
      @specs << value
      @lookup = nil
      @sorted = nil
      value
    end

    def to_a
      sorted.dup
    end

    def to_hash
      lookup.dup
    end

    def materialize(deps, missing_specs = nil)
      materialized = self.for(deps, [], false, true).to_a
      materialized.map! do |s|
        next s unless s.is_a?(LazySpecification)
        s.source.dependencies = deps if s.source.respond_to?(:dependencies=)
        spec = s.__materialize__
        if missing_specs
          missing_specs << s unless spec
        else
          raise GemNotFound, "Could not find #{s.full_name} in any of the sources" unless spec
        end
        spec if spec
      end
      SpecSet.new(materialized.compact)
    end

    def merge(set)
      arr = sorted.dup
      set.each do |s|
        next if arr.any? { |s2| s2.name == s.name && s2.version == s.version && s2.platform == s.platform }
        arr << s
      end
      SpecSet.new(arr)
    end

  private

    def sorted
      rake = @specs.find { |s| s.name == 'rake' }
      @sorted ||= ([rake] + tsort).compact.uniq
    end

    def lookup
      @lookup ||= begin
        lookup = Hash.new { |h,k| h[k] = [] }
        specs = @specs.sort_by do |s|
          s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s
        end
        specs.reverse_each do |s|
          lookup[s.name] << s
        end
        lookup
      end
    end

    def tsort_each_node
      @specs.each { |s| yield s }
    end

    def tsort_each_child(s)
      s.dependencies.sort_by { |d| d.name }.each do |d|
        next if d.type == :development
        lookup[d.name].each { |s2| yield s2 }
      end
    end
  end
end
