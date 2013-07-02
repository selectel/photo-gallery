gRouter = new (Backbone.Router.extend(
  routes:
    ':name': (route) ->
      Backbone.trigger('route:change', route)
))

gModel = Backbone.Model.extend
  initialize: ->
    if @attributes.name
      @set(img: new Image, loaded: false, loading: false)
      @load = =>
        if @attributes.loading || @attributes.loaded
          return
        @set(loading: true)
        @attributes.img.src = @attributes.name
        @attributes.img.onload = =>
          @set(loaded: true, loading: false)

FldView = Backbone.View.extend
  el: '<div class="folder"/>'
  template: _.template('<a href="<%= subdir %>" class="title" title="<%= subdir%>"><%= subdir.slice(0,-1) %></a>')
  render: ->
    @$el.html(@template(@model.toJSON()))

ImgView = Backbone.View.extend
  el: '<div class="photo loading"/>'
  events:
    'click': ->
      lightBox.show(@model)
  template: _.template('<div class="title" title="<%= name%>"><%= name%></div>')
  initialize: ->
    img = new Image
    src = @model.get('name')
    img.src = '.thumbs/' + src
    img.onerror = ->
      img.src = src
    img.onload = =>
      @$el.css('background-image', 'url("' + img.src + '")') \
        .removeClass("loading")
        .addClass("loaded")
    this
  render: ->
    @$el.html(@template(@model.toJSON()))

gCollection = Backbone.Collection.extend
  model: gModel
  elsPerPage: (->
    ratio = Math.floor($(window).width() / 312)
    if ratio > 2 then ratio else 3 )() * 2
  page: 0
  nextPage: ->
    firstIndex = @page * @elsPerPage
    @page++
    @slice(firstIndex, firstIndex + @elsPerPage)

gCollectionView = Backbone.View.extend
  initialize: (images) ->
    $('#lazy').appear()
    $(document.body).on 'appear click', '#lazy', -> 
      galleryApp.needMore()
    $(window).on 'resize orientationchange', -> 
      lightBox.calcContMetric()
    $(window).on 'hashchange', (e) ->
      Backbone.trigger 'route:change', e.originalEvent.newURL.split('#').slice(1)

    @collection = new gCollection
    @collection.on 'reset', =>
      $('#lazy').show()
      for i in [0..(Math.floor($(window).height()/312))]
        @needMore()
      lastDigit = @collection.length%10;
      twoLastDigits = @collection.length%100;
      $('.count').html(@collection.length + ' элемент' + (
          if twoLastDigits isnt 11 and lastDigit is 1 then '' else
            if twoLastDigits not in [12,13,14] and lastDigit in [2,3,4] then 'а' else 'ов'
        ))
      Backbone.history.start()
  find: (query) ->
    @collection.findWhere(query)

  getNext: (model) ->
    model = @collection.at(@collection.indexOf(model) + 1) || @collection.find((model) -> model.attributes.name)
    return model

  getPrev: (model) ->
    prevModel = @collection.at(@collection.indexOf(model) - 1)
    return if (!prevModel or !prevModel.get('name')) then @collection.at(@collection.length - 1) else prevModel

  renderOne: (model) ->
    view = if model.attributes.subdir then new FldView(model: model) else new ImgView(model: model)
    $('.photo-list').append(view.render())

  needMore: ->
    arr = @collection.nextPage()
    if arr.length
      _.each arr, (model) =>
        @renderOne(model)
      @needMore
    else
      $('#lazy').remove()

lightBox = new (Backbone.View.extend(
  el: '.light-box'
  timeout: 4000
  visible: false
  playing: false
  sharing: false
  bodyScroll: 0
  events:
    'click .btn-close': 'hide'
    'click .btn-next': 'showNext'
    'click .btn-prev': 'showPrev'
    'click .btn-play': 'play'
    'click .btn-share': 'shareToggle'

  shareToggle: (forceVisible = true) ->
    $btnShare = $('.btn-share');
    $el = $('.share')
    if !forceVisible
      $btnShare.removeClass('active')
      $el.hide()
      return !@sharing = false
      
    $btnShare.toggleClass('active')
    $el.toggle();
    if !@sharing != @sharing
      url = encodeURI(document.location.origin + document.location.pathname.split('/').slice(0,-1).join('/') + '/' + @model.attributes.name)
      $('.dl').attr(href: @model.attributes.name)
      $('.fb').attr(href: 'http://share.yandex.ru/go.xml?service=facebook&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attributes.name)
      $('.tw').attr(href: 'http://share.yandex.ru/go.xml?service=twitter&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attributes.name)
      $('.gp').attr(href: 'http://share.yandex.ru/go.xml?service=gplus&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attributes.name)
      $('.mail').attr(href: 'mailto:?subject=' + @model.attributes.name + '&body=' + url + '&title=Selectel Photo Gallery / ' + @model.attributes.name)
      $('.vk').attr(href: 'http://share.yandex.ru/go.xml?service=vkontakte&url=' + url + '&title=Selectel Photo Gallery / ' + @model.attributes.name)
    return false

  showNext: ->
    return false if @wait
    @shareToggle(false)
    @show(galleryApp.getNext(@model), false)
    galleryApp.getNext(@model).load()
    return false

  showPrev: ->
    return false if @wait
    @shareToggle(false)
    @show(galleryApp.getPrev(@model), false)
    galleryApp.getPrev(@model).load()
    return false

  wait: false

  show: (model, preload = true) ->

    if @wait or !model or !model.attributes.name then return false
    @model = model
    if preload
      galleryApp.getNext(@model).load()
    
    if !@model.attributes.loaded
      @wait = true
      @model.on 'change:loaded', ->
        _this.wait = false
        _this.show(this)
      @model.load()
      return false

    @$imgCont.find('.current').removeClass('current')

    @$img = $(@model.attributes.img.cloneNode())
    @$img.bind('dragstart', -> false).on('swipeleft', => @showNext()).on('swiperight', => @showPrev()).on('swiperight swipeleft', => @$footer.addClass('hidden')).click(=> @$footer.toggleClass('hidden'))
    @$img.load ->
      $(this).addClass('loaded slide')
    @$imgCont.append(@$img)

    setTimeout =>
      @$img.addClass('current')
    , 10

    @$btnLoad.attr('href', model.get('name'))
    @$el.show().addClass('show')
    @calcContMetric()

    if @visible
      return false
    @visible = true
    @bodyScroll = $('body').scrollTop() || $('html').scrollTop()
    console.log 'wow: ', @bodyScroll
    $('.wrapper').hide()
    return false

  hide: ->
    if !@visible then return this
    $('.wrapper').show()
    @$el.hide().removeClass('show')
    @visible = false
    @stop() if @playing
    @shareToggle(false);
    (=>
      setTimeout => 
        $('body,html').scrollTop(@bodyScroll)
      , 0
    )()
    return false

  initialize: ->
    @$imgCont = @$el.find('.light-box-image')
    @$btnLoad = @$el.find('.btn-download')
    @$footer = @$el.find('.light-box-footer').on 'mouseenter', -> $(this).removeClass('hidden')

    $('.share a').popupWindow();
    
    @$imgCont.on 'transitionend', 'img.slide', (event) ->
        if !$(event.target).hasClass('current')
          $(this).remove()

    $('.light-box-image').on 'click', (event) -> 
      if event.target == this
        _this.hide()

    $('.btn-fullscreen').click @fullscreen

    Backbone.on 'route:change', (route) ->
      @show(galleryApp.find(name: route))
    , this

    $('body').on 'keydown', (event) =>
      if event.keyCode in [39,37,32]
        @$footer.addClass('hidden')
      switch event.keyCode
        when 39
          @showNext()
        when 37
          @showPrev()
        when 32
          @showNext()
        when 27
          @hide()
        when 13
          @fullscreen(event) if event.altKey

  fullscreened: false

  fullscreen: ->
    if @fullscreened = !@fullscreened
      el = document.body
      fullscreenMethod = el.requestFullScreen || el.webkitRequestFullScreen || el.mozRequestFullScreen || el.msRequestFullScreen
    else 
      el = document
      fullscreenMethod = el.exitFullScreen || el.webkitCancelFullScreen || el.mozCancelFullScreen || el.msCancelFullScreen
    fullscreenMethod.call(el)

  setInterval: ->
    setTimeout =>
      if @playing
        @showNext()
        @setInterval()
    , @timeout

  stop: ->
    @playing = false
    @$el.find('.btn-play span').attr(class: 'icon-play')
    return false

  play: ->
    if @playing then return @stop() else @playing = true
    @$el.find('.btn-play span').attr(class: 'icon-pause')
    @setInterval()
    return false

  calcContMetric: ->
    @contHeight = @$el.find('.light-box-image').innerHeight()
    @contWidth = @$el.find('.light-box-image').innerWidth()
    @align()

  align: ->
    if @$img.innerWidth() is 0 || @$img.innerWidth() is 0
      setTimeout (=> @align()), 10
    if @contWidth > @$img.innerWidth()
      @$img.css('marginLeft', @contWidth/2 - @$img.innerWidth()/2)
    else
      @$img.css('marginLeft', 0)
    if @contHeight > @$img.innerHeight()
      @$img.css('marginTop', @contHeight/2 - @$img.innerHeight()/2)
    else
      @$img.css('marginTop', 0)
))

log = (str) ->
  $('#log').html(str)

reqAPI = (fld) ->
  return $.ajax(
    url: (fld or './') + "?format=json"
    beforeSend: (xhr) ->
      xhr.setRequestHeader('X-Web-Mode', 'listing')
  ).done (files, err) ->
    models = _.filter files, (file) ->
      if (/^\./).test file.subdir
        return false
      if file.subdir
        return true
      if file.content_type
        return file.content_type.split('/')[0] is 'image'
      return false

    pathArr = _(document.location.pathname.split('/')).filter (el) -> el
    if pathArr.length > 1
      models.unshift({subdir: '../'})
    galleryApp.collection.reset(models)

galleryApp = new gCollectionView
reqAPI()


