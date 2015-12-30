#encoding: utf-8
#=======================================================================
#**ETS 2 Easy Translate
#**Copyright (C) Narzew
#**23.12.2015
#=======================================================================

require 'find'
require "unicode_utils/upcase"

$translate_data = []
tmpdata = []

module EasyTranslate
	def self.extract_all(filename)
		Find.find("def/city"){|x|
			next if x == "." || x == ".." || File.directory?(x) || x.split(".")[-1] != "sii"
			extract_data_from_file(x)
			write_to_text(filename)
		}
	end
	def self.extract_data_from_file(x)
		data = File.binread(x)
		tmpdata = []
		tmpdata[0] = x.split("/")[-1].gsub(".sii","")
		data.each_line{|line|
			if line.include?("short_city_name:")
				tmpdata[2] = line.split("\"")[1].split("\"")[0]
			elsif line.include?("city_name:")
				tmpdata[1] = line.split("\"")[1].split("\"")[0]
			elsif line.include?("city_name_uppercase")
				tmpdata[3] = line.split("\"")[1].split("\"")[0]
			end
		}
		$translate_data << tmpdata
	end
	def self.write_to_text(filename)
		str = ""
		$translate_data.each{|x|
			#str << "#{x[0]}^#{x[1]}^#{x[2]}^#{x[3]}\n"
			str << "#{x[0]}^#{x[1]}\n"
		}
		File.open(filename,"wb"){|w|w.write(str)}
	end
	def self.apply_translation(file)
		# Create $translate_data table
		data = File.binread(file)
		$translate_data = []
		data.each_line{|line|
			next if line.include?("#")
			next unless line.include?("^")
			a = line.split("^")
			next if a.size != 2
			a[1] = a[1].tr("\n\r\t","")
			a[2] = a[1]
			a[3] = UnicodeUtils.upcase(a[1])
			# Special for Polish Chars
			a[3] = a[3].force_encoding(Encoding::UTF_8).tr("ą","Ą").tr("ć","Ć").tr("ę","Ę").tr("ł","Ł").tr("ń","Ń").tr("ó","Ó").tr("ś","Ś").tr("ż","Ż").tr("ź","Ź")
			$translate_data << a
		}
		# Apply patch to files
		$translate_data.each{|x|
			fname = "def/city/#{x[0]}.sii"
			datab = File.binread(fname)
			# datab -> contents of translated file (ex. sanok.sii)
			tmpdata = []
			str = datab.to_s.force_encoding(Encoding::UTF_8)
			oldstr = ""
			toreplace = ""
			datab.each_line{|line|
				x[3] = x[3].tr("\n\r\t","")
				line = line.tr("\n\r\t","").force_encoding(Encoding::UTF_8)
				if line.include?("city_name:")
					if line.include?("short_city_name:")
						oldstr = line.split("\"")[1].split("\"")[0]
						toreplace = line.gsub(oldstr,x[2]).force_encoding(Encoding::UTF_8)
						str.gsub!(line,toreplace)
					else
						oldstr = line.split("\"")[1].split("\"")[0]
						toreplace = line.gsub(oldstr,x[1]).force_encoding(Encoding::UTF_8)
						str.gsub!(line,toreplace)
					end
				elsif line.include?("city_name_uppercase:")
					oldstr = line.split("\"")[1].split("\"")[0]
					toreplace = line.gsub(oldstr,x[3]).force_encoding(Encoding::UTF_8)
					str.gsub!(line,toreplace)
				end
			}
			File.open(fname,"wb"){|w|w.write(str)}
		}
	end
	def self.show_help
		print "*"*60+"\n"
		print "**Easy Translate\n"
		print "**(C) Narzew\n"
		print "**v 1.0\n"
		print "**23.12.2015\n"
		print "*"*60+"\n"
		print "**ruby EasyTranslate.rb e file.cfg to extract translation\n"
		print "**ruby EasyTranslate.rb a file.cfg to apply translation\n"
		print "*"*60+"\n"
		print "\n"
	end
end

begin
	if ARGV.size != 2
		EasyTranslate.show_help
	else
		if ARGV[0] == "e"
			EasyTranslate.extract_all(ARGV[1])
		elsif ARGV[0] == "a"
			EasyTranslate.apply_translation(ARGV[1])
		else
			EasyTranslate.show_help
		end
	end
end
