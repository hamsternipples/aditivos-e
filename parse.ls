# pdf parser

Fs = require 'fs'
unesc = require 'querystring' .unescape
q_ = (str) -> unesc(str).trim!
within = (x, xx, v = 0.1) -> Math.abs(x - xx) <= v

aditivos = {}
aditivo_footnotes = []
groups = {}
max_quantity = {}

parse = (data) ->
	#state = 'partb'
	state = 'partb'
	var cur_section, cur_num, t, p, has_max
	even = false
	show_t = false
	num_groups = 0
	console.log "parsing!", data.Pages.length
	for page, i in data.Pages
		even = !even
		if i >= 7 and i <= 34
			console.log "page:", i, even
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
							#console.log "E NUMBER:", cur_num
							state = \name
							continue
					state = \section
					continue
				| \section =>
					if (even and within(t.x, 16.86, 0.1)) or (!even and within(t.x, 17.84, 0.1))
						cur_section = q_ T
						aditivos[cur_section] = {}
						#console.log "section!", cur_section
						state = \section_number
					else if T is "PART%20C"
						console.log aditivos, aditivo_footnotes
						console.log "GOING TO PART C"
						state = \group
					#else
						# XXX fuck the footnotes for now... me la sudan
						#console.log "FOOTNOTE!!", t
						#if within t.y, p.y, 0.2 then aditivo_footnotes[*-1] += unesc(T).trimRight!
						#else aditivo_footnotes.push q_ T
				| \name =>
					if (even and t.x is 26.88) or (!even and t.x is 27.85)
						name = q_ T
						aditivos[cur_section][cur_num] = name
						#console.log "E NAME:", q_ name
						state = \section_number
				# ------ PART C ------
				| \group =>
					if within t.x, 17.32, 2
						cur_group = q_ T
						state = \group_continue
						#console.log "GROUP!!", cur_group
				| \group_continue =>
					if within t.y, p.y, 0.1
						cur_group += ' '+unesc(T).trimRight!
					else
						has_max = true
						groups[cur_group] = {}
						state = \group_header_number
						num_groups++
						#console.log "num_groups", num_groups
						if num_groups > 4
							state = \parte
							console.log groups
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
						#console.log "PAGE!!", t
						state = \group_header_number
					else if T.indexOf('E%20') is 0
						cur_num = q_ T
						#console.log "GROUP NUMBER!!", t
						state = \group_name
					else
						state = \group
					#	cur_name += '\n'+unescape(T).trimRight!
				| \group_name =>
					cur_name = q_ T
					console.log "GROUP NAME!!", cur_name
					state = \group_name_continue
				| \group_name_continue =>
					if within(t.y, p.y, 0.1) and within(t.x, p.x, 10)
						cur_name += ' '+unesc(T).trimRight!
					else if within(t.x, p.x, 2)
						cur_name += '\n'+unesc(T).trimRight!
					else
						state = \group_max
						continue
				| \group_max =>
					console.log "has_max", has_max
					state = \group_max_continue
					if has_max
						cur_max = q_ T
						if t.x < 50 then continue
					else continue
				| \group_max_continue =>
					if not within(t.y, p.y, 3)
						console.log "next page!"
						state = \group_header_number
					else if t.x > 50
						cur_max += ' '+unesc(T).trimRight!
						console.log 1
					else if not has_max
						groups[cur_group][cur_num] = cur_name
						state = \group_number
						console.log 1
						continue
					else if t.x < 30
						#console.log "GROUP MAX!!", cur_max
						groups[cur_group][cur_num] = [cur_name, cur_max]
						#state = if cur_name is 'Sodium hydroxide' then \debug else \group_number
						state = \group_number
						continue
					else
						/*
						# XXX save t.x to see if I should add a newline
						cur_name += unesc(T).trimRight!
						if cur_num is 'E 968'
							#console.log "GROUP NAME!!", t
							state = \debug
							*/
				# ------ PART E ------
				| \parte =>
					if T is \PART%20E
						show_t = true
						state = \cat_header
				| \cat_header =>
					if within t.x, 16.03
						state = \cat_header_continue
				| \cat_header_continue =>
					console.log "cat_header", t.y, p.y, t.x, p.x
					if not within(t.x, p.x, 2)
						state = \cat_desc
						cur_cat = T
				| \cat_desc =>
					cur_cat_desc = T
					state = \cat_num
				| \cat_num =>
					cur_num = T
					state = \cat_name
				| \cat_name =>
					cur_name = T
					state = \cat_max
				| \cat_max =>
					cur_max = T
					state = \cat_footnote
				| \cat_footnote =>
					if within t.x, p.x
						cur_footnote = T
						return
					else
						return
						state = \cat_num
						continue
				| \debug => #console.log ":::", t
				idx++

	console.log groups



Fs.readFile 'pdf/l_29520111112en.json', 'utf8', (err, data) ->
	if err
		PDFParser = require 'pdf2json'
		parser = new PDFParser
		parser.on \pdfParser_dataReady (pdf) ->
			Fs.writeFile 'pdf/l_29520111112en.json', JSON.stringify pdf.data
			parse pdf.data

		parser.loadPDF 'pdf/l_29520111112en.pdf'
	else parse JSON.parse data

