require 'fileutils'
require 'rio'
require_relative 'vocab'


class Main
	def initialize(dirPath, topicFolderPath)
		@parentDir = dirPath
		@topicFolder = topicFolderPath
		@unitNum = ''
		@currUnit = nil
		@vocab = Vocab.new(@parentDir)
		@classStr = ''
		@subClassStr = ''
		@labFileName = ''
	end

	#Extracts the folder class name and subfolder. For example with Sparks, 
	#classStr = 'sparks' and subclassStr = 'student-pages'
	def parse_class()
		path = @parentDir
		pattern = /bjc-r\\(\w+.?)+(\\summaries)$/
		pathMatch = path.match(pattern).to_s
		pathList = pathMatch.split("\\")
		classStr(pathList[1])
		subClassStr(pathList[2])
	end

	#Main/primary function to be called, will call and create all other functions and classes. 
	#This function will parse the topic pages, parse all labs and units, and create summary pages
	def Main()
		parse_class()
		parse_allTopicPages(@topicFolder)
		parse_topicsFile("#{@parentDir}/summaries/topics.txt")
	end


	#Returns list of all FOLDERS (directories) in current working directory (cwd)
	def list_folders(folder)
		Dir.glob('*').select {|f| File.directory? f}
	end

	#Returns list of all FILES in current working directory (cwd)
	#Input is the file type or ext you want -- Enter '*' for all file types
	def list_files(fileType)
		Dir.glob("*#{fileType}").select {|f| File.file? f}
	end

	#Returns true if input (fileName) is a file and not a folder 
	#and is the correct extension type (fileType)
	def isCorrectFileType(fileType, fileName)
		File.exists?("#{fileName}#{fileType}") & File.file?(fileName)
	end

	#Input is the folder path of the topic folder you want to parse
	#Based on all the parsed topic pages, summaries will be generated
	def parse_allTopicPages(folder)
		Dir.chdir(@topicFolder)
		filesList = list_files('.topic')
		filesList.each do |file|
			if isTopicPageFile(file)
				parse_rawTopicPage(file)
				
			end
		end
	end
	
	#Returns true if the file is a valid topic page
	def isTopicPageFile(file)
		unwantedFilesPattern = /teaching-guide/
		filename = File.basename(file)
		if (filename.match(unwantedFilesPattern))
			false
		else
			true
		end
	end

	#Adds the summary content and links to the topic.topic file
	def addSummariesToTopic(topicFile)
		linkMatch = @parentDir.match(/\/bjc-r.+/).to_s
		linkMatchWithoutBracket = linkMatch.split(/]/)
		link = "[#{linkMatchWithoutBracket}]"
		dataList = ["heading: Unit #{@unitNum} Review",
			"resource: Vocabulary #{link}/vocab#{@unitNum}.html]",
			"resource: On the AP Exam #{link}/exam#{@unitNum}.html]",
			"resource: Self-Check Questions #{link}/assessment-data#{@unitNum}.html]"]
		data = dataList.join("\n")
		add_content_to_file("#{@topicFolder}/#{topicFile}", data)
	end

	#Parses through the data of the topic page and generates and adds content to a topics.txt
	#file that will be parsed later on to generate summaries 
	def parse_rawTopicPage(file)
		allLines = File.readlines(file)
		topicURLPattern = /\/bjc-r.+\.\w+/
		headerPattern = /((heading:.+)|(title:.+))/
		labNum = 1
		allLines.each do |line|
			if isComment(line)
				line = removeComment(line)
			end
			if isTopic(line)
				if (line.match(headerPattern))
					header = removeHTML(line.match(headerPattern).to_s)
					add_content_to_file("#{@parentDir}/summaries/topics.txt", "#{header}\n")
					labNum = 1
				elsif line.match(/}/)
					#end of topic.topic file
					addSummariesToTopic(file)
					break
				else
					wholeLine = removeHTML(line.to_s.split(/.+:/).join)
					labName = wholeLine.match(/(\w+\s?((\!|\?|\.|-)\s?)?)+/).to_s
					topicURL = line.match(topicURLPattern).to_s
					add_content_to_file("#{@parentDir}/summaries/topics.txt", "#{labNum} #{labName} ----- #{topicURL}\n")
					labNum += 1
				end
			end
		end
		add_content_to_file("#{@parentDir}/summaries/topics.txt", "END OF UNIT\n")
	end

	#Returns true if there is a comment in the topics.topic page
	def isComment(arg)
		str = arg.force_encoding("BINARY")
		if str.match(/\/\//)
			true
		else
			false
		end
	end

	#Removes the part of the string that is commented out in topics.topic which will then be added
	#to the new topics.txt file
	def removeComment(arg)
		str = arg.force_encoding("BINARY")
		strList = arg.split(/\/\/.+/)
		strList.join
	end

	#Returns true if the string/line is a valid topic. Ignores the lines that start with the kludges.
	def isTopic(arg)
		str = arg.force_encoding("BINARY")
		kludges = ['raw-html',
			'heading: Unit',
			'Summary',
			'resource: Vocabulary',
			'resource: On the AP Exam',
			'resource: Self-Check Questions'
			]
		topicLine = /(\s+)?(\w+)+(\s+)?/
		bool = true
		kludges.each do |item|
			i = item.force_encoding("BINARY")
			if (str.match(i) or not(str.match(topicLine)))
				bool = false
			end
		end
		bool
	end

	def add_content_to_file(filename, data)
		if File.exist?(filename)
			File.write(filename, data, mode: "a")
		else
			File.new(filename, "w")
			File.write(filename, data)
		end	
	end	

	def removeHTML(str)
		htmlTagPattern = /<\/?\w+>/
		if str.match(htmlTagPattern)
			newStr = str.split(htmlTagPattern)
			newStr.join
		else
			str
		end
	end

	def isFileALab(file, labName)
		fileAsString = rio(file)
		file.include?(labName)
	end

	#not using
	def parse_labNameFromFile(labFile)
		fileName = File.basename(labFile)
		nameMatch = fileName.match(/([a-zA-Z]-?)+/)
		labName = nameMatch.to_s.join(' ')
	end


	def findLabFile(lab, folder)
		listLabs = list_files('.html')
		i = 0
		labNum = lab.match(/\d+/).to_s
		while i < listLabs.size
			if (listLabs[i].match(labNum))
				labFileName(listLabs[i])
				return listLabs[i]
				break
			end
			i += 1
		end
	end

	def parse_topicsFile(topicsFile)
		#make sure i am in summaries directory first
		Dir.chdir(@parentDir)
		f = File.open(topicsFile, 'r')
		labNamePattern = /-----/
		unitNamePattern = /title: /
		labTopicPattern = /heading: /
		unitFolder = ''
		labFolder = ''
		labName = ''
		labNum = ''
		f.each do |line|
			if line.match(labNamePattern)
				#labNameMatch = line.match(/(\w+\s?((\!|\?|\.|-)\s?)?)+/).to_s
				#labNameList = labNameMatch.split(/[\!\?\.\-\s]+/)
				#labName = labNameList.join("-")
				labNum = line.match(/\d+\s+/).to_s
				labFile = findLabFile(labNum, Dir.getwd())
				puts line
				@vocab.read_file(labFile)
				#pass to function that will open correct file
			elsif line.match(labTopicPattern)
				labNum = line.match(/\d+/).to_s
				labFolder = getFolder(labNum, unitFolder)
				Dir.chdir(labFolder)
					
				#change lab folder
			elsif line.match(unitNamePattern)
				unitNum(line.match(/\d+/).to_s)
				puts @unitNum
				unitFolder = getFolder(@unitNum, @parentDir)
				Dir.chdir(unitFolder)
				#change unit folder
			elsif(isEndofTopicPage(line))
				puts line
				@vocab.add_HTML_end()
			end
		end
	end

	def isEndofTopicPage(line)
		if line.match(/END OF UNIT/)
			return true
		else
			return false
		end
	end

	def getFolder(strPattern, parentFolder)
		Dir.chdir(parentFolder)
		foldersList = list_folders(parentFolder)
		foldersList.each do |folder|
			if File.basename(folder).match(strPattern)
				return "#{parentFolder}/#{folder}"
			end
		end
	end

	def fileLanguage(file)
		file_name = File.basename(file)
		if /\w+\.html/.match?(file)
			lang = /\w+\.html/.match(file).to_s
			return lang.split[0]
		else
			return "en"
		end
	end

#p array.map { |x| x == 4 ? 'Z' : x }

# => [1, 2, 3, 'Z']

	def parse_topic_links(fileName, line)
		Dir.chdir(@topicFolderPath)
		fileContents = []
		rio(fileName) > fileContents
		lineLink = line.match(/[.+]/).to_s
		contentIndex = fileContents.index(lineLink)
		fileContents.each do |item|
			if item.match(lineMatch)
				addStr = "#{lineLink}?topic=#{@classStr}%2F#{@unitNum}-#{fileName}.topic&course=#{@classStr}.html]"
				newLink = fileContents.gsub("lineLink", addStr)
			#elsif lineMatch and isSummary
			end	
		end
	end


	#Setters and Getters

	def classStr(str)
		@classStr = str
	end

	def subClassStr(str)
		@subClassStr = str
	end

	def unitNum(str)
		@unitNum = str
	end

	def labFileName(str)
		@labFileName = str
	end

end