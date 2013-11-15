ge = (q) ->
	document.querySelector q

AUTH = true
unless AUTH 
	ge('.page_footer.error').innerHTML = 'Пароль неверный.'
ge('.access').addEventListener 'submit', (e) ->
	form = e.target
	e.preventDefault()
	val = form[0].value.toString()
	if val and /^[\d\w\s]{5,}$/.test(val)
		document.cookie = 'gallery-secret="' + form[0].value.toString() + '";'
		form.submit()
	else 
		ge('.page_footer.error').innerHTML = 'Пароль должен содержать хотя бы 5 букв и цифр.'
