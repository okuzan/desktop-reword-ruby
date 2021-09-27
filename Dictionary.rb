$:.unshift File.dirname(__FILE__)
require 'Editor'
require 'Texty'
require 'Line'
require 'Stampline'
require 'Dupes'
require 'Translator'
require 'fileutils'
require 'csv'
require 'net/http'
require 'rubygems'
require 'uri'
require 'json'

class Dictionary
  THRESHOLD = 100

  def open_folder(path)
    if @platform.eql? :win
      system %{cd /d #{path}"}
      system %{start ."}
    elsif @platform.eql? :mac
      exec "open #{path}"
    elsif @platform.eql? :linux
      exec "xdg-open #{path}"
    end
  end

  def open_file(path)
    if @platform.eql? :mac
      exec "open #{path}"
    elsif @platform.eql? :win
      system %{cmd /c "start #{path}"}
    elsif @platform.eql? :linux
      exec "xdg-open #{path}"
    end
  end

  def generate_append(base_date = nil)
    base_date = Date.strptime(File.open(@lang_dir + "exports.txt").read.split("\n")[-1], '%Y-%m-%d') if base_date.nil?

    new_lines = @lookup_lines.select { |line| !line.stamps[0].eql?('*') }
    new_lines.select! { |line| Date.strptime(line.stamps[0], '%Y-%m-%d') > base_date }
    new_lines.sort_by! { |line| line.stamps[-1] }

    append_words, append_phrases = [], []

    new_lines.each do |look_line|
      @phr_lines.each { |line| append_phrases << line if line.word.eql? look_line.word }
      @voc_lines.each { |line| append_words << line if line.word.eql? look_line.word }
    end

    File.open(@lang_dir + "append_phrases.txt", 'w') do |f|
      append_phrases.each { |line| f << line.to_v }
      f.close
    end
    File.open(@lang_dir + "append_words.txt", 'w') do |f|
      append_words.each { |line| f << line.to_v }
      f.close
    end
  end

  def stamp_export_date
    File.open(@lang_dir + "exports.txt", 'a') do |f|
      f << Date.today.to_s + "\n"
      f.close
    end
  end

  def show_lookup
    @lookup_lines.sort_by! { |b| b.stamps[-1] }

    # writing to a file last stamps of time-recorded words
    File.open(@lang_dir + "timeline.txt", 'w') do |f|
      @lookup_lines.each { |line| f << line.to_l }
      f.close
    end

    # displaying last week's words
    count = 0
    @lookup_lines.map do |line|
      days = (Date.today - Date.strptime(line.stamps[-1], '%Y-%m-%d')).to_i
      if days < 7
        puts line.word + " #{days} days ago"
        count += 1
      end
    end
    puts "#{count} words in last week"
    puts "<=============================>"
  end

  def load_old_data
    vocab = File.open(@lang_dir + "base_words.txt").read.force_encoding 'utf-8'
    phrase_book = File.open(@lang_dir + "base_phrases.txt").read.force_encoding 'utf-8'
    lookup = File.open(@lang_dir + "lookup.txt").read.force_encoding 'utf-8'

    @voc_lines = str_to_lines(vocab)
    @phr_lines = str_to_lines(phrase_book)
    @lookup_lines = parse_lookup(lookup)

    # generate items added since last export
    generate_append

    a_words_count = File.open(@lang_dir + "append_words.txt").read.force_encoding('utf-8').split("\n").length
    a_phrases_count = File.open(@lang_dir + "append_phrases.txt").read.force_encoding('utf-8').split("\n").length

    date = File.open(@lang_dir + "exports.txt").read.split("\n")[-1]

    puts "You've added more than #{THRESHOLD} words since your last export! Consider updating reword app!" if (a_phrases_count + a_phrases_count) > THRESHOLD
    puts "AW " + a_words_count.to_s + " | AP " + a_phrases_count.to_s + " since " + date
  end

  def initialize(platform, lang)
    @voc_lines = []
    @phr_lines = []
    @lookup_lines = []
    @platform = platform
    @lang = lang
    @lang_dir = File.dirname(__FILE__) + "/data/#{@lang}/"

    load_old_data
    integrity_check
    wizard
  end

  def faq
    puts File.open(DATA_DIR + "faq.txt").read
  end

  def wizard
    loop do
      puts "W " + @voc_lines.length.to_s + " | P " + @phr_lines.length.to_s
      puts @lang.upcase
      puts "Hello!
 a - add n edit [phr]
 g - generate append [YYYY-MM-DD]
 s - switch langs [pl]
 f - open root folder
 l - load from file
 v - vague search
 t - time stamps
 o - open files
 r - reload app
 e - export
 q - FAQ
"
      a = $stdin.gets.chomp
      next if a.nil?

      case a
      when /\A[a]/
        editor(a.include?('p') ? @phr_lines : @voc_lines)
      when 'v'
        vague_searcher
      when 's'
        new_lang = (@lang.eql? 'en') ? 'de' : 'en'
        set_availability true
        starter new_lang, RUBY_PLATFORM
        return
      when 's pl'
        set_availability true
        starter "pl", RUBY_PLATFORM
        return
      when 'l'
        load_file
      when /\Ag/
        begin
          if a.split(' ').size > 1
            date = a.split(' ')[1]
            generate_append(Date.strptime(date, '%Y-%m-%d'))
          else # if no args provided take date of last export
            generate_append
          end
          puts "Generated!"
        rescue
          puts "Invalid date!"
        end
      when 'e' #export
        puts "Are you sure? (Y)"
        if(gets.chomp.upcase == 'Y')
          generate_append
          stamp_export_date
          open_folder(@lang_dir)
          a_words_count = File.open(@lang_dir + "append_words.txt").read.force_encoding('utf-8').split("\n").length
          a_phrases_count = File.open(@lang_dir + "append_phrases.txt").read.force_encoding('utf-8').split("\n").length
          puts "Successfully exported! #{a_words_count} words and #{a_phrases_count} phrases"
        end
      when 't'
        show_lookup
      when 'q'
        faq
      when 'r'
        set_availability true
        starter @lang, RUBY_PLATFORM
        return
      when 'f'
        open_folder(File.dirname(__FILE__))
      when 'o'
        puts "[w] / [p] / [aw] / [ap] / [t] / [o] / [l]"
        a = $stdin.gets.chomp.strip.downcase
        file_to_open = @lang_dir + ""
        case a
        when 'w'
          file_to_open += "base_words.txt"
        when 'p'
          file_to_open += "base_phrases.txt"
        when 'aw'
          file_to_open += "append_words.txt"
        when 'ap'
          file_to_open += "append_phrases.txt"
        when 'e'
          file_to_open += "exports.txt"
        when 't'
          file_to_open += "timeline.txt"
        when 'l'
          file_to_open += "lookup.txt"
        else
          puts "Action dismissed"
          next
        end
        open_file(file_to_open)
      else
        puts "No code assigned to this command\n\n"
        return
      end
    end
  end
end
