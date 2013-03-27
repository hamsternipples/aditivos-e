# pdf parser

Fs = require 'fs'
unesc = require 'querystring' .unescape
q_ = (str) -> unesc(str).trim!
within = (x, xx, v = 0.1) -> Math.abs(x - xx) <= v

aditivos = {}
aditivo_footnotes = []
groups = {}
permitted_groups = {}
max_quantity = {}

parse = (data) ->
	var t, p, has_max
	var cur_section, cur_num, cur_footnote, cur_exception
	state = 'partb'
	even = false
	show_t = false
	num_groups = 0
	console.log "parsing!", data.Pages.length
	for page, i in data.Pages
		even = !even
		if i >= 7 and i <= 180
			#show_t = if i is 103 then true else false
			idx = 0; len = page.Texts.length
			while idx < len
				t = page.Texts[idx]
				if idx > 0 then p = page.Texts[idx - 1]
				if show_t then console.log state, "t:", t
				if state is \group and T.indexOf('E%20') is 0
					return
				T = t.R.0.T
				switch state
				# ------ PART B ------
				| \partb =>
					if T is "PART%20B"
						state = \section
				| \section_number =>
					if (even and t.x is 17.2) or (!even and t.x is 18.18)
						if (T).indexOf('E%20') is 0
							cur_num = q_ T
							state = \name
							continue
					state = \section
					continue
				| \section =>
					if (even and within(t.x, 16.86, 0.1)) or (!even and within(t.x, 17.84, 0.1))
						cur_section = q_ T
						aditivos[cur_section] = {}
						state = \section_number
					else if T is "PART%20C"
						state = \group
					#else
						# XXX fuck the footnotes for now... me la sudan
						#console.log "FOOTNOTE!!", t
						#if within t.y, p.y, 0.2 then aditivo_footnotes[*-1] +=  q_ T
						#else aditivo_footnotes.push q_ T
				| \name =>
					if (even and t.x is 26.88) or (!even and t.x is 27.85)
						name = q_ T
						aditivos[cur_section][cur_num] = name
						state = \section_number
				# ------ PART C ------
				| \group =>
					if within t.x, 17.32, 2
						cur_group = q_ T
						state = \group_continue
				| \group_continue =>
					if within t.y, p.y, 0.1
						cur_group += ' '+ q_ T
					else
						has_max = true
						groups[cur_group] = {}
						state = \group_header_number
						num_groups++
						if num_groups > 4
							state = \parte
						continue
				| \group_header_number =>
					if t.x > 19.5 and t.x < 21
						state = \group_header_name
				| \group_header_name =>
					if t.x > 30 and t.x < 57
						state = \group_header_max
				| \group_header_max =>
					state = \group_number
					if t.x < 60
						has_max = false
						continue
				| \group_number =>
					if (T).indexOf('EN') is 0
						# XXX FIXME!! I should not rely on "EN" - this isn't language independent
						state = \group_header_number
					else if T.indexOf('E%20') is 0
						cur_num = q_ T
						state = \group_name
					else
						state = \group
				| \group_name =>
					cur_name = q_ T
					state = \group_name_continue
				| \group_name_continue =>
					if within(t.y, p.y, 0.1) and within(t.x, p.x, 10)
						cur_name += ' '+ q_ T
					else if within(t.x, p.x, 2)
						cur_name += '\n'+ q_ T
					else
						state = \group_max
						continue
				| \group_max =>
					state = \group_max_continue
					if has_max
						cur_max = q_ T
						if t.x < 50 then continue
					else continue
				| \group_max_continue =>
					if not within(t.y, p.y, 3)
						state = \group_header_number
					else if t.x > 50
						cur_max += ' '+ q_ T
					else if not has_max
						groups[cur_group][cur_num] = cur_name
						state = \group_number
						continue
					else if t.x < 30
						groups[cur_group][cur_num] = [cur_name, cur_max]
						state = \group_number
						continue
					else
						/*
						# XXX save t.x to see if I should add a newline
						cur_name +=  q_ T
						if cur_num is 'E 968'
							#console.log "GROUP NAME!!", t
							state = \debug
							*/
				# ------ PART E ------
				| \parte =>
					if T is \PART%20E
						cur_num = void
						state = \cat_header
				| \cat_header =>
					if within(t.x, 16.03, 2)
						state = \cat_header_continue
				| \cat_header_continue =>
					if not within(t.x, p.x, 2)
						state = \cat_desc
						continue
				| \cat_desc =>
					cur_cat = q_ T
					if cur_cat is '18' then return
					state = \cat_desc_continue
				| \cat_desc_continue =>
					if within(t.x, p.x, 2)
						cur_cat += ' ' + q_ T
					else
						permitted_groups[cur_cat] = {}
						if within t.y, 48.15
							state = \cat_desc
							continue
						else
							state = \cat_num
							continue
				| \cat_num =>
					if cur_num
						v = [cur_name, cur_max]
						if cur_footnote
							v.push cur_footnote
							cur_footnote = void
						if cur_exception
							v.push cur_exception
							cur_exception = void
						if permitted_groups[cur_cat][cur_num] then cur_num += '*'
						permitted_groups[cur_cat][cur_num] = v
						cur_num = void
					if within t.y, 44.52
						cur_num = q_ T
						state = \cat_num_continue
					else if within t.y, 39.86
						if footnote_idx = T.match /(\d+)/ .0
							permitted_groups[cur_cat]['footnote'+footnote_idx] = q_ T
						else
							console.log "UHOH"
							return
					else if within t.y, 48.15
						state = \cat_desc
						continue
				| \cat_num_continue =>
					if within t.y, 44.52
						cur_num += ' ' + q_ T
					else
						state = \cat_name
						continue
				| \cat_name =>
					cur_name = q_ T
					state = \cat_name_continue
				| \cat_name_continue =>
					if within(t.y, p.y, 4)
						cur_name += ' ' + q_ T
					else
						state = \cat_max
						continue
				| \cat_max =>
					cur_max = q_ T
					state = \cat_footnote
				| \cat_footnote =>
					if within t.x, p.x
						cur_footnote = q_ T
						state = \cat_exceptions
					else
						state = \cat_num
						continue
				| \cat_exceptions =>
					if within t.x, p.x
						cur_exception = q_ T
						state = \cat_exceptions_continue
					else
						state = \cat_num
						continue
				| \cat_exceptions_continue =>
					if within(t.x, p.x, 0.1) and within(t.y, p.y, 10)
						cur_exception += ' '+ q_ T
					else if within(t.y, p.y, 2)
						cur_exception += ' '+ q_ T
					else
						state = \cat_num
						continue
				| \debug => #console.log ":::", t
				idx++



Fs.readFile 'pdf/l_29520111112en.json', 'utf8', (err, data) ->
	if err
		PDFParser = require 'pdf2json'
		parser = new PDFParser
		parser.on \pdfParser_dataReady (pdf) ->
			Fs.writeFile 'pdf/l_29520111112en.json', JSON.stringify pdf.data
			parse pdf.data

		parser.loadPDF 'pdf/l_29520111112en.pdf'
	else parse JSON.parse data
	console.log permitted_groups

