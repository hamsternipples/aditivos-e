# pdf parser

Fs = require 'fs'
unesc = require 'querystring' .unescape
q_ = (str) -> unesc(str).trim!
within = (x, xx, v = 0.5) -> Math.abs(x - xx) <= v

aditivos = {}
aditivo_footnotes = []
groups = {}
max_quantity = {}

parse = (data) ->
	#state = 'partb'
	state = 'partb'
	var cur_section, cur_num, t, p
	even = false
	console.log "parsing!", data.Pages.length
	for page, i in data.Pages
		even = !even
		if i >= 7 and i <= 23
			console.log "page:", i, even
			for t, idx in page.Texts
				if idx > 0 then p = page.Texts[idx - 1]
				T = t.R.0.T
				#console.log "t", t, p, idx
				#if t.R.0.T is "LIST%20OF%20ALL%20ADDITIVES"
				#if !even and t.x is 17.84 then console.log "state:", state
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
					fallthrough
				| \section =>
					if (even and within(t.x, 16.86, 0.1)) or (!even and within(t.x, 17.84, 0.1))
						cur_section = q_ T
						aditivos[cur_section] = {}
						#console.log "section!", cur_section
						state = \section_number
					else if T is "PART%20C"
						console.log aditivos, aditivo_footnotes
						state = \partc
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
				| \partc =>
					if T is "PART%20C"
						state = \group
				| \group
					if t.x is 17.32 or (T).indexOf('Group') is 0
						#console.log "GROUP!!", t
						cur_group = q_ T
						groups[cur_group] = {}
						state = \group_header_number
						# number, name, max
				| \group_header_number =>
					if t.x > 19.5 and t.x < 20 then state = \group_header_name
				| \group_header_name => state = \group_header_max
				| \group_header_max => state = \group_number
				| \group_number =>
					if (T).indexOf('EN') is 0
						#console.log "PAGE!!", t
						state = \group_header_number
					else if T.indexOf('E%20') is 0
						cur_num = q_ T
						#console.log "GROUP NUMBER!!", t
						state = \group_name
					#else
					#	cur_name += '\n'+ue(T).trimRight!
				| \group_name =>
					cur_name = q_ T
					#console.log "GROUP NAME!!", cur_name
					state = \group_max
				| \group_max =>
					if t.x > 50
						cur_max = q_ T
						#console.log "GROUP MAX!!", cur_max
						groups[cur_group][cur_num] = [cur_name, cur_max]
						#state = if cur_name is 'Sodium hydroxide' then \debug else \group_number
						state = \group_number
					else if t.x < 20
						if T.indexOf('E%20') is 0
							cur_num = q_ T
							#console.log "GROUP NUMBER!!", t
							state = \group_name
						else if (T).indexOf('EN') is 0
							#console.log "PAGE!!", t
							state = \group_header_number
						#else
							#console.log "FOOTNOTE!!", t
					else
						# XXX save t.x to see if I should add a newline
						cur_name += '\n'+unesc(T).trimRight!
						if cur_num is 'E 968' then console.log "GROUP NAME!!", t
				| \debug => console.log ":::", t

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

