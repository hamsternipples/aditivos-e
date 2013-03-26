#!/usr/bin/env lsc -cj

name: \aditivios-e
version: '0.0.1'
main: 'index.js'
description: 'open sourcing the EU regulations on food additives'
keywords: [ 'EU' 'additives' 'aditivos' 'alimentacion' 'food' ]
author:
	name: 'Kenneth Bentley'
	email: 'kenny@gatunes.com'
	twitter: 'hamsternipples'
homepage: 'https://github.com/hamsternipples/aditivios-e'
bugs:
	url: 'https://github.com/hamsternipples/aditivios-e/issues'
	email: 'kenny@gatunes.com'
licenses: [
		{ type: "WTFPL", url: "http://www.wtfpl.org" }
		{ type: 'MIT', url: "file:LICENSE" }
]
repository:
	type: 'git'
	url: 'https://github.com/hamsternipples/aditivios-e.git'
dependencies:
	LiveScript: \1.1.1
	pdf2json: \0.1.19
	lodash: \1.0.0
	debug: \0.7.0
