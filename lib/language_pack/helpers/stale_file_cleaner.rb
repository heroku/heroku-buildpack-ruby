class LanguagePack::Helpers::StaleFileCleaner
  FILE_STAT_CACHE = Hash.new {|h, k| h[k] = File.stat(k) }

  def initialize(dir)
    @dir  = dir
    raise "need or dir" if @dir.nil?
  end

  def clean_over(limit) # limit in bytes
    old_files_over(limit).each {|asset| FileUtils.rm(asset) }
  end

  def glob
    "#{@dir}/**/*"
  end

  def files
    @files ||= Dir[glob].reject {|file| File.directory?(file) }
  end

  def sorted_files
    @sorted ||= files.sort_by {|a| FILE_STAT_CACHE[a].mtime }
  end

  def total_size
    @size   ||= sorted_files.inject(0) {|sum, asset| sum += FILE_STAT_CACHE[asset].size }
  end


  def old_files_over(limit)
    diff = total_size - limit
    sorted_files.take_while {|asset| diff -= FILE_STAT_CACHE[asset].size if diff > 0 } || []
  end
end
