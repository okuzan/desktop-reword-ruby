class Line

  def initialize(word, sound, translation)
    @word = word.force_encoding 'utf-8'
    sound.nil? ? @sound = '' : @sound = sound
    @translation = translation.force_encoding 'utf-8'
    @examples = []
  end

  def s?
    @sound != ''
  end

  attr_accessor :word, :sound, :translation, :examples

  #to view as an object
  def to_s
    'Line [' + @word + ' : ' + @sound + ' : ' + @translation + "]\n"
  end

  #to feed application
  def to_v
    str = @word + ' ; ' + @sound + ' ; ' + @translation
    @examples.each { |d| str += ' ; ' + d }
    str + " \n"
  end

  #to display in game
  def to_d
    @word + (s? ? (' [' + @sound + ']') : '') + ' : ' + @translation + "\n"
  end

  def to_g
    @word + (s? ? (' [' + @sound + ']') : '') + "\n"
  end

  def eql?(other)
    # puts 'eql called'
    word.eql? other.word && sound.eql?(other.sound) && translation.eql?(other.translation)
  end

  def hash
    [word, sound, translation].hash
  end

  # def <=>(other)
  #   puts '<> called'
  #   @word <=> other.word
  # end
end