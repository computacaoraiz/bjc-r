require 'fileutils'
require 'nokogiri'
require 'i18n'

require_relative 'index'
require_relative 'selfcheck'

I18n.load_path = Dir['**/*.yml']
I18n.backend.load_translations
TEMP_FOLDER = 'summaries~'

# TODO: It's unclear where the HTML for new files comes from.
# We should probably have a 'template' file which gets used.
# I think we can just replace content in the file, but we could use a library.
class Vocab
  def initialize(path, language = 'en')
    @parentDir = path
    @language = language
    I18n.locale = @language.to_sym
    @currUnit = nil
    @currFile = nil
    @isNewUnit = true
    @currUnitNum = 0
    @currLab = ''
    @vocabList = []
    @vocabDict = {}
    @labPath = ''
    @currUnitName = nil
    @index = Index.new(@parentDir, @language)
    @boxNum = 0
  end

  def language_ext
    @language_ext ||= @language == 'en' ? '' : ".#{@language}"
  end

  def review_folder
    @review_folder ||= "#{@parentDir}/#{TEMP_FOLDER}"
  end

  def doIndex
    @index.vocabDict(@vocabDict)
    @index.vocabList(@vocabList)
    @index.main
  end

  def currUnitName(str)
    @currUnitName = str
  end

  def labPath(arg)
    @labPath = arg
  end

  def unit
    @currUnit.match(/[A-Za-z]+/).to_s
  end

  def currUnit(str)
    @currUnit = str
  end

  def currFile(file)
    @currFile = file
  end

  def currFile(file)
    @currFile = file
  end

  def isNewUnit(boolean)
    @isNewUnit = boolean
  end

  def currUnitNum(num)
    @currUnitNum = num
  end

  def boxNum(num)
    @boxNum = num
  end

  def currLab
    return if @currUnit.nil?
  end

  def vocab_file_name
    "unit-#{@currUnitNum}-vocab#{@language_ext}.html"
  end

  def currLab
    return if @currUnit.nil?

    labMatch = @currUnit.match(/Lab.+,/)
    labList = labMatch.to_s.split(/,/)
    @currLab = labList.join
  end

  def read_file(file)
    return unless File.exist?(file)

    currFile(file)
    isNewUnit(true)
    parse_unit(file)
    parse_vocab(file)
    puts "Completed: #{@currUnit}"
  end

  def parse_unit(file)
    doc = File.open(file) { |f| Nokogiri::HTML(f) }
    title = doc.xpath('//title')
    str = title.to_s
    pattern = %r{</?\w+>}
    if str.nil? || !@isNewUnit
      nil
    else
      newStr = str.split(pattern)
      currUnit(newStr.join)
      currUnitNum(@currUnit.match(/\d+/).to_s)
      boxNum(0)
      isNewUnit(false)
    end
  end

  def createNewVocabFile(fileName)
    i = 0
    filePath = Dir.getwd
    unless File.exist?(fileName)
      Dir.chdir(review_folder)
      File.new(fileName, 'w')
    end
    linesList = File.readlines("#{filePath}/#{@currFile}")[0..30]
    while !linesList[i].match(/<body>/) && (i < 30)
      if linesList[i].match(/<title>/)
        File.write(fileName, "\t<title>#{unit} #{@currUnitNum} #{I18n.t('vocab')}</title>\n", mode: 'a')
      else
        File.write(fileName, "\t#{linesList[i]}\n", mode: 'a')
      end
      i += 1
    end
    File.write(fileName, "\t<h2>#{@currUnit}</h2>\n", mode: 'a')
    File.write(fileName, "\t<h3>#{currLab}</h3>\n", mode: 'a')
    Dir.chdir(@labPath)
  end

  def add_HTML_end
    Dir.chdir(review_folder)
    ending = "</body>\n</html>"
    return unless File.exist?(vocab_file_name)

    File.write(vocab_file_name, ending, mode: 'a')
  end

  def add_content_to_file(filename, data)
    lab = @currLab
    data = data.gsub(/&amp;/, '&')
    data.delete!("\n\n\\")
    if File.exist?(filename)
      File.write(filename, "\t<h3>#{currLab}</h3>", mode: 'a') if lab != currLab
    else
      createNewVocabFile(filename)
    end
    File.write(filename, data, mode: 'a')
  end

  # might need to save index of line when i find the /div/ attribute
  # might be better to have other function to handle that bigger parsing of the whole file #with io.foreach
  def parse_vocab(file)
    doc = File.open(file) { |f| Nokogiri::HTML(f) }
    vocabSet1 = doc.xpath("//div[@class = 'vocabFullWidth']")
    # header = parse_vocab_header(doc.xpath(""))
    vocabSet1.each do |node|
      child = node.children
      child.before(add_vocab_unit_to_header)
      get_vocab_word(node)
    end
    add_vocab_to_file(vocabSet1.to_s)
    vocabSet2 = doc.xpath("//div[@class = 'vocabBig']")
    vocabSet2.each do |node|
      child = node.children
      changeToVocabFullWidth(vocabSet2, node['class'])
      child.before(add_vocab_unit_to_header)
      get_vocab_word(node)
    end
    add_vocab_to_file(vocabSet2.to_s)
    vocabSet3 = doc.xpath("//div[@class = 'vocab']")
    vocabSet3.each do |node|
      child = node.children
      changeToVocabFullWidth(vocabSet3, node['class'])
      child.before(add_vocab_unit_to_header)
      get_vocab_word(node)
    end
    add_vocab_to_file(vocabSet3.to_s)
    # if not(vocabSet.empty?())

    # end
  end

  def changeToVocabFullWidth(vocabSet, clas)
    return unless %w[vocabBig vocab].include?(clas)

    vocabSet.remove_class(clas)
    vocabSet.add_class('vocabFullWidth')
  end

  def get_vocab_word(nodeSet)
    # extract_vocab_word(nodeSet.xpath(".//li//strong"))
    extract_vocab_word(nodeSet.xpath('.//div//strong'))
    extract_vocab_word(nodeSet.xpath('.//li//strong'))
    extract_vocab_word(nodeSet.xpath('.//p//strong'))
  end

  def vocabExists?(list, word)
    # return ((cases.map{|item| eval(word + item)}).map{|vocab| list.include?(vocab)}).any?
    (list.include?(word) or list.include?(word.upcase) or list.include?(word.downcase) or list.include?(word.capitalize))
  end

  def findVocab(word)
    list = @vocabList
    cases = %w[downcase upcase capitalize]
    return word if list.include?(word)

    vocab = (cases.map { |item| word.method(item).call }).map { |vocab| list.include?(vocab) ? vocab : nil }
    vocab.find { |item| !item.nil? }
  end

  def separateVocab(str)
    unless str.scan(/\(\w+\)/).empty? # looking for strings in parathesis such as: (API), (AI)
      saveVocabWord(str.scan(/\(\w+\)/)[0][1..-2])
    end
    if !str.scan(/ or /).empty? # looking for strings with "or" in them: antivirus or antimalware
      iterateVocab(str.split(' or '))
    elsif !str.scan(/ o /).empty? # looking for string with "or" in them in spanish
      iterateVocab(str.split(' o '))
    end
    return unless str.split(' ').length > 1 # looking for strings with multiple words: articial intelligence

    list = str.split(' ')
    saveVocabWord("#{list[-1]}, #{list[0..-2].join(' ')}")
  end

  def iterateVocab(list)
    str = list.join(' ')
    vList = list
    if str.match(/^((?!(\(.*\))).)*/) # str has parethesis with multiple words
      vList = str.match(/^((?!(\(.*\))).)*/).to_s.split(' ')
    end
    vList.each do |vocab|
      saveVocabWord(vocab) if !vocab.match?(/^(\s+)/) && (vocab != '') && !vocab.match?(/\(/)
    end
  end

  def removeArticles(vocab)
    vList = vocab.split(' ')
    articles = %w[el la las los the]
    plurals = articles.map(&:capitalize)
    # keep = []
    # vList.map{|word| articles.include?(word) or plural.include?(word) ? keep.append(vList.index(word))}
    if articles.include?(vList[0]) || plurals.include?(vList[0])
      vList = vList[1..]
      vList.include?(',') ? vList[..vList.index(',')] : vList
      vList.join(' ')
    elsif articles.include?(vList[-1]) || plurals.include?(vList[-1])
      vList = vList[..-1]
      vList.include?(',') ? vList[..vList.index(',')] : vList
      vList.join(' ')
    else
      vocab
    end
  end

  def extract_vocab_word(nodeSet)
    nodeSet.each do |n|
      node = removeArticles(n.text.gsub(/(\s+)$/, '').to_s)
      saveVocabWord(node)
      separateVocab(node)
    end
  end

  def saveVocabWord(vocab)
    kludges = %w[T BI PI T]
    return if kludges.include?(vocab.upcase)

    if !vocabExists?(@vocabList, vocab)
      @vocabList.push(vocab)
      @vocabDict[vocab] = [add_vocab_unit_to_index]
    elsif @vocabDict[findVocab(vocab)].last != add_vocab_unit_to_index
      @vocabDict[findVocab(vocab)].append(add_vocab_unit_to_index)
    end
  end

  def parse_vocab_header(str)
    newStr1 = str
    if str.match(/vocabFullWidth/)
      newStr1 = str.gsub(/<!--.+-->/, '') if str.match(/<!--.+-->/)
      newStr2 = newStr1.to_s
      if newStr2.match(/<div class="vocabFullWidth">.+/)
        headerList = newStr2.split(/:/)
      else
        headerList = []
        headerList.push(str)
      end
      headerList
    else
      []
    end
  end

  def add_vocab_unit_to_index
    unitNum = return_vocab_unit(@currUnit)
    currentDir = Dir.getwd
    FileUtils.cd('..')
    link = " <a href=\"#{get_url(vocab_file_name)}\">#{unitNum}</a>"
    FileUtils.cd(currentDir)
    link
  end

  def add_vocab_unit_to_header
    unitNum = return_vocab_unit(@currUnit)
    "<a href=\"#{get_url(@currFile)}\">#{unitNum}</a>
		<a name=\"box#{@boxNum}\" class=\"anchor\">&nbsp;</a>"
    # if lst.size > 1
    #	unitSeriesNum = lst.join(" #{withlink}:")
    # else
    #	unitSeriesNum = lst
    #	unitSeriesNum.push(" #{withlink}:")
    #	unitSeriesNum.join
    # end
  end

  # need something to call this function and parse_unit
  def return_vocab_unit(str)
    list = str.scan(/(\d+)/)
    list.join('.')
  end

  def add_vocab_to_file(vocab)
    return unless vocab != ''

    file = "#{review_folder}/#{vocab_file_name}"
    add_content_to_file(file, vocab)

    # if File.exists?(file)
    #	doc = File.open(file) { |f| Nokogiri::HTML(f) }
    #	vocabSet = doc.xpath("//div[@class = 'vocabFullWidth']").to_s
    #	if vocab.match(vocabSet) == nil
    #			add_content_to_file(file, vocab)
    #	end
    # else
    # add_content_to_file(file, vocab)
    # end
  end

  def get_url(file)
    localPath = Dir.getwd
    linkPath = localPath.match(/bjc-r.+/).to_s
    result = "/#{linkPath}/#{file}"
    # add_content_to_file('urlLinks.txt', result)
  end
end