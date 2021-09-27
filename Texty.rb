def smart_input
  if @platform.eql?(:win)
    file_to_open = TEMP_DIR
    system %{cmd /c "start #{file_to_open}"}
    cmd_input = $stdin.gets.chomp
    word = File.open(TEMP_DIR).read.force_encoding('utf-8').strip
    File.open(TEMP_DIR, 'w') { |file| file.truncate(0) }
    word.empty? ? cmd_input : word
  else
    $stdin.gets.chomp
  end
end

def prep_words(chosen)
  s = ''
  chosen.each { |word| s << word.gsub(',', ', ').strip + ', ' }
  s.delete_suffix! ', '
end

def normalize_ranged(int, size)
  int = size if int > size
  int = 1 if int < 1
  int
end

def str_to_lines(string)
  lines = []
  string.split("\n").each do |line|
    parts = line.strip.gsub('|', ',').split(';').map(&:strip)
    raise "CorruptedFileIndexException in #{parts}" if parts[0].nil? || parts[2].nil? || parts.size < 3
    line = Line.new(parts[0], parts[1], parts[2])
    examples = parts[3..-1]
    throw new "Wrong examples format!" if examples.size % 2 == 1
    line.examples = examples unless examples.empty?
    lines << line
  end
  lines
end

def parse_lookup(string)
  lines = []
  string.split("\n").each do |line|
    parts = line.strip.gsub('|', ',').split(';').map(&:strip)
    timestamps = parts[1].split(',').map(&:strip)
    lines << Stampline.new(parts[0], timestamps)
  end
  lines
end

def select_indices(variants)
  user_ids = $stdin.gets.chomp
  return [] if user_ids.empty?
  chosen_vars = []
  user_ids.gsub(' ', '').each_char.map(&:to_i)
      .map { |d| normalize_ranged d, variants.size }.uniq
      .each { |p| chosen_vars << variants[p - 1] } unless user_ids.empty?
  chosen_vars
end

=begin
30 min
3 hrs
24 hrs
8 hrs
14 days
60 days
=end
