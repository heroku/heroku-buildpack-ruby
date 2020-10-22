# This class is used to check whether a binary exists on one or more stacks.
# The main motivation for adding this logic is to help people who are upgrading
# to a new stack if it does not have a given Ruby version. For example if someone
# is using Ruby 1.9.3 on the cedar-14 stack then they should be informed that it
# does not exist if they try to use it on the Heroku-18 stack.
#
# Example
#
#    download = LanguagePack::Helpers::DownloadPresence.new(
#      'ruby-1.9.3.tgz',
#      stacks: ['cedar-14', 'heroku-16', 'heroku-18', 'heroku-20']
#    )
#
#    download.call
#
#    puts download.exists? #=> true
#    puts download.valid_stack_list #=> ['cedar-14']
class LanguagePack::Helpers::DownloadPresence
  STACKS = ['cedar-14', 'heroku-16', 'heroku-18', 'heroku-20']

  def initialize(path, stacks: STACKS)
    @path = path
    @stacks = stacks
    @fetchers = []
    @threads = []
    @stacks.each do |stack|
      @fetchers << LanguagePack::Fetcher.new(LanguagePack::Base::VENDOR_URL, stack)
    end
  end

  def supported_stack?(current_stack: )
    @stacks.include?(current_stack)
  end

  def next_stack(current_stack: )
    return unless supported_stack?(current_stack: current_stack)

    next_index = @stacks.index(current_stack) + 1
    @stacks[next_index]
  end

  def exists_on_next_stack?(current_stack: )
    return false unless supported_stack?(current_stack: current_stack)

    next_index = @stacks.index(current_stack) + 1
    @threads[next_index]
  end

  def valid_stack_list
    raise "not invoked yet, use the `call` method first" if @threads.empty?

    @threads.map.with_index do |thread, i|
      @stacks[i] if thread.value
    end.compact
  end

  def exists?
    raise "not invoked yet, use the `call` method first" if @threads.empty?

    @threads.any? {|t| t.value }
  end

  def does_not_exist?
    !exists?
  end

  def call
    @fetchers.map do |fetcher|
      @threads << Thread.new do
        fetcher.exists?(@path, 3)
      end
    end
  end
end
