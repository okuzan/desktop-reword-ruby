def integrity_check
  find_duplicates(@voc_lines)
  find_duplicates(@phr_lines)
  find_duplicates(@lookup_lines)
end

def find_duplicates(base)
  map = base.group_by { |e| e.word }
  indices = []
  map.each do |key, value|
    if value.size > 1
      puts key
      puts value
      indices << base.each_index.select { |i| base[i].word == key }
    end
  end
  indices.each { |i| puts i.to_s }
  raise "CorruptedIndexException" unless indices.empty?
end

def load_file
  phrases = File.open(DATA_DIR + "_load/" + "phrases.txt").read.force_encoding 'utf-8'.strip
  words = File.open(DATA_DIR + "_load/" + "words.txt").read.force_encoding 'utf-8'.strip
  loaded_phr_lines = str_to_lines(phrases)
  loaded_voc_lines = str_to_lines(words)
  voc_edited, new_voc_lines = dupe_manager(@voc_lines, loaded_voc_lines)
  phr_edited, new_phr_lines = dupe_manager(@phr_lines, loaded_phr_lines)
  @voc_lines = voc_edited
  @phr_lines = phr_edited # mb not needed, можна там напряму підставити
  stamp_words_today(new_voc_lines)
  stamp_words_today(new_phr_lines)
  update_dbs([:voc, :phr, :lookup])
end

def dupe_manager(base, append)
  append_dupes = []
  base.map do |base_word|
    one_dupe_list = append.partition { |e| dupes?(e.word, i.word) }[0]
    unless one_dupe_list.empty? # it's new word
      one_dupe_list.map do |dupe| # here should be list of ONE dupe
        raise "Duplicates in base array! [#{dupe.to_d}]" unless append_dupes.size == 1
        append_dupes << one_dupe_list
        puts "Case #" + append_dupes.size.to_s
        manage_conflict(base_word, append_dupes[-1])
      end
    end
  end
  puts "How many duplicates processed? " + append_dupes.size.to_s
  append -= append_dupes
  [base, append]
end

def valid_line(dupe)
  !dupe.word.nil? && !dupe.translation.nil?
end

def manage_conflict(i, dupe, action = nil)
  if !i.s? && dupe.s?
    puts "Added new transcription!"
    i.sound = dupe.sound
  end
  # no need to review same stuff. Sound'd already be added
  if i.translation == dupe.translation
    puts "Same translations, new entry is skipped"
    return ''
  end
  unless valid_line dupe
    puts 'Corrupted entry'
    return ''
  end
  puts 'old: ' + i.to_d
  puts 'new: ' + dupe.to_d
  puts " n - leave new \n c - constructor \n d - merge unique \n (other = discard)"

  answer = action.nil? ? $stdin.gets.chomp.downcase : action
  decide i, dupe, answer
end

def line_to_vars(line)
  line.translation.split(/[,\s]/).map(&:strip)
end

def decide (base_word, dupe, answer)
  puts "Chosen: " + answer
  puts "voc before: "
  puts base_word.translation
  case answer
  when 'n'
    base_word.translation = dupe.translation
  when 'd'
    arr = line_to_vars(base_word) + line_to_vars(dupe)
    base_word.translation = prep_words arr.uniq
  when 'c'
    arr = line_to_vars(base_word) + line_to_vars(dupe)
    arr.uniq!
    chosen = select_indices(arr)
    base_word.translation = prep_words chosen.flatten
  else
    puts 'new value discarded'
    answer = ' '
  end
  puts "voc after: "
  puts base_word.translation
  answer
end
