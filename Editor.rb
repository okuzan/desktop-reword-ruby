DATA_DIR = File.dirname(__FILE__) + "/data/"
TEMP_DIR = DATA_DIR + "temp.txt"


def search_word(res, word)
  res.word.downcase.split(/[()\s-]/).select { |s|
    !%w[der die das not auf aus in ins im dem des for of at on up it off]
         .include? s }.include? word.downcase
end

def vague_searcher
  loop do
    puts "What are you trying to find?"
    word = $stdin.gets.chomp.strip
    word = smart_input if word.start_with? '*'
    return if word.empty?
    base = @voc_lines + @phr_lines
    found = false
    base.map do |r|
      if search_word(r, word)
        found = true
        puts "Look what we've got:"
        puts r.to_d
        puts "\n"
      end
    end
    puts "Nothing found" unless found
  end
end

def editor(base)
  (base == @voc_lines) ? mode = :voc : mode = :phr
  puts "Working with #{mode}"
  loop do
    puts "What are you looking for?"
    word, stealth_check, disable_translations = loop_input_options(mode)
    break if word.nil?
    found, deleted = false, false
    base.map do |res|
      if res.word == word # found!
        found = true
        stealth_check, deleted = word_editing(res, base)
      end
    end
    puts @lookup_lines.size
    # working with new look_like
    unless found
      variants = translator(word, disable_translations)
      sleep 1 # time to read auto-translations
      # creating line
      line = Line.new(word, '', '')
      puts "Your variant:"
      # adding user proposed translation
      entered = smart_input # next if entered == ''
      variants << entered unless entered.empty?
      next if variants.empty?
      # displaying all translation variants
      variants.each_with_index { |variant, i| puts "#{i + 1}: " + variant }
      solutions = select_indices(variants)
      next if solutions.empty?
      line.translation = prep_words solutions
      save_options(base, line)
    end
    lookup_update(word, stealth_check, found) unless deleted
  end
  update_dbs([mode, :lookup])
end


def update_dbs(mode)
  if mode.include? :lookup
    @lookup_lines.sort_by! { |a| a.word }
    File.open(@lang_dir + "lookup.txt", 'w') do |f|
      @lookup_lines.each { |line| f << line.to_v }
      f.close
    end
  end
  if mode.include? :voc
    @voc_lines.sort_by! { |a| a.word }
    File.open(@lang_dir + "base_words.txt", 'w') do |f|
      @voc_lines.each { |line| f << line.to_v }
      f.close
    end
  end
  if mode.include? :phr
    @phr_lines.sort_by! { |a| a.word }
    File.open(@lang_dir + "base_phrases.txt", 'w') do |f|
      @phr_lines.each { |line| f << line.to_v }
      f.close
    end
  end
end

def loop_input_options(mode)
  word = $stdin.gets.chomp.strip
  word = smart_input if word.start_with? '*'
  stealth_check, disable_translations, vague_search = false, false, false
  if word.start_with? '.'
    word = word[1..-1]
    stealth_check = true
  end
  if word.end_with? '-'
    word.chomp! '-'
    disable_translations = true
  end
  return if word == '' or word.nil?

  # if the first look_like of phrase is article, phrase will be properly capitalized
  if (mode == :voc) && %w[der die das].any? { |needle| word.split(" ")[0].eql? needle }
    parts = word.split(" ")
    unless parts.size != 2
      article = parts[0]
      just_word = parts[1]
      word = article.downcase + " " + just_word.capitalize
    end
  end
  [word, stealth_check, disable_translations, vague_search]
end

def word_editing(line, base)
  stealth, deleted = true, false
  puts line.to_d
  puts "[w] / [s] / [t] / [d] / [c] / [e]"
  code = $stdin.gets.chomp.strip.downcase
  return if code == ''
  case code
  when 'w'
    old_word = line.word
    line.word = smart_input
    @lookup_lines.map do |r|
      if r.word.eql? old_word
        r.word = line.word
        puts r # showing lookup entry to the user
        break
      end
    end
    deleted = true
    stealth = false
  when 'e'
    examplify line
  when 's'
    line.sound = smart_input
  when 'd'
    base.delete(line) # deleted from base
    @lookup_lines.select! { |e| !e.word.eql? line.word }
    deleted = true
    puts "Deleted"
  when 'c'
    base.delete(line) # deleted from base
    (base == @voc_lines) ? (@phr_lines << line) : (@voc_lines << line)
    integrity_check
    puts "Moved!"
  when 't'
    parts = line.translation.split(/[,]/).map(&:strip)
    parts.each_with_index { |part, i| puts "#{i + 1}: " + part }

    puts "Pick something if you want to"
    chosen_vars = select_indices parts


    puts "Add new translations if you want to"
    proposed = smart_input.split(/[,]/)

    # puts chosen.size
    chosen_vars = (chosen_vars + proposed).uniq unless proposed.empty?
    line.translation = prep_words chosen_vars.flatten
  else
    puts "Action dismissed"
    stealth = false
  end
  puts line.to_d
  [stealth, deleted]
end

def save_options(base, line)
  puts "[c] / [s] / [f] / [e]"
  d = $stdin.gets.chomp.upcase
  if d == 'S'
    line.sound = smart_input
  elsif d == 'C'
    (base == @voc_lines) ? (base = @phr_lines) : (base = @voc_lines)
  elsif d == 'F'
    puts "Aborted!"
    return
  elsif d == 'E'
    examplify line
  end
  (base == @voc_lines) ? @voc_lines << line : @phr_lines << line
  puts line.to_d
  puts "Added!"
end

def examplify(line)
  loop do
    puts "Enter example"
    text = $stdin.gets.chomp.strip
    text = smart_input if text.start_with? '*'
    break if text.empty?
    puts "Enter translation"
    text2 = $stdin.gets.chomp.strip
    text2 = smart_input if text2.start_with? '*'
    text2 = "_" if text2.empty?
    line.examples << text
    line.examples << text2
  end
  line
end

def lookup_update(word, stealth_check, found)
  # checking lookup
  is_in_table = false
  @lookup_lines.map do |r|
    if r.word == word
      is_in_table = true
      r.add_stamp unless stealth_check # adding new stamp to previous ones
      puts r # showing lookup entry to the user
    end
  end
  # if not found - creating lookup entry
  stamp_line = Stampline.new(word, (found ? ['*'] : [])).add_stamp
  @lookup_lines << stamp_line unless is_in_table
end


def stamp_words_today(words)
  words.map do |word|
    stamp_line = Stampline.new(word, []).add_stamp
    @lookup_lines << stamp_line
  end
end


def translator(word, disable_translations)
  variants = []
  begin
    if @lang.eql? 'en'
      variants = [lc(word, 'uk-UA', 'en'), lc(word, 'ru-RU', 'en')]
    elsif @lang.eql? 'de'
      variants = [lc(word, 'uk-UA', 'de-DE'), lc(word, 'ru-RU', 'de-DE'), lc(word, 'en', 'de-DE')]
    elsif @lang.eql? 'pl'
      variants = [lc(word, 'uk-UA', 'pl-PL'), lc(word, 'ru-RU', 'pl-PL'), lc(word, 'en', 'pl-PL')]
    end unless disable_translations
    # rescue
    #   puts "No translations currently available"
  end

  if variants.any? { |e| e.nil? } || variants.empty?
    variants = []
  else
    variants.map!(&:downcase)
    variants.each { |variant| puts variant + "\n" }
  end
  variants
end