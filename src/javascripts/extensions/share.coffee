$ = require('jquery')
_ = require('lodash')
sightglass = require('sightglass')
rivets = require('rivets')
Uri = require('urijs')

Extension = require('../extension.coffee')

class Share extends Extension
  @extension:
    name: 'Share'
    type: 'panel'

  constructor: (@app) ->
    @episode = @app.episode
    console.log("share constructor called")
    return unless @episode

    return unless @episode.url

    @options = _.extend(@defaultOptions, @app.extensionOptions.Share)
    console.log("share constructor - extensionOptions.Share")
    return if @options.disabled

    @buildContext()

    @renderPanel()
    @renderButton()
    @attachEvents()

    @app.theme.addExtension(this)

  defaultOptions:
    showOnStart: false

  shareLinks: (currentTimeInSeconds) =>
    url = encodeURI(@shareUrl())
    fileUrl = @audioFileUrl()
    title = encodeURI(@episode.title)
    coverUrl = encodeURI(@episode.coverUrl)

    shareLinks =
      email: "mailto:?subject=Podcast: #{title}&body=#{url}"
      facebook: "https://www.facebook.com/sharer/sharer.php?u=#{url}&t=#{title}"
      googleplus: "https://plus.google.com/share?url=#{url}"
      twitter: "https://twitter.com/intent/tweet?url=#{url}&text=#{title}"
      whatsapp: "whatsapp://send?text=#{title}: #{url}"

  audioFileUrl: () ->
    url = @app.episode.media.mp3 || @app.episode.media.m4a
    encodeURI(url)

  buildContext: =>
    @context ?= {}
    @context.currentTime = @app.player.currentTime
    @context.currentTimeInSeconds = @app.player.currentTimeInSeconds
    @context.shareLinks = @shareLinks(@context.currentTimeInSeconds)
    @context.url = @shareUrl()
    @context.playerUrl = @playerUrl
    @context.showUrlWithTime ?= false
    @context.updateContext = @updateContext
    @context.embedCode = @app.episode.embedCode
    @context.showEmbedUrl = @app.options.configViaJSON

  updateContext: =>
    @buildContext()

  shareUrl: =>
    parsed = Uri(@episode.url)
    if @context?.showUrlWithTime
      time = Math.round(@context.currentTimeInSeconds)
      parsed.fragment("t=#{time}")
    else
      @episode.url
  
  playerUrl: =>
    playerUrl = window.top.location.toString()
    title = encodeURI(@episode.title)
    titleIndex = playerUrl.indexOf("&title=")
    if titleIndex > 0
      playerUrl = playerUrl.substring(0,titleIndex)
    playerUrl = playerUrl + "&title=#{title}"

  renderPanel: =>
    @panel = $(@panelHtml)
    rivets.bind(@panel, @context)
    @panel.hide()

    @bindEvents()

  attachEvents: =>
    $(@app.player.media).on('timeupdate', @buildContext)

  bindEvents: () =>
    @panel.find('.share-copy-url').on 'focus', @copyUrlAction
    @panel.find('.share-embed-code').on 'focus', @copyUrlAction
    @panel.find("[name='enable-start-at']").on 'change', @toggleStartAt

  copyUrlAction: (event) =>
    event.target.select()

  buttonHtml:
    """
    <button class="share-button" title="Share episode URL"></button>
    """

  panelHtml:
    """
    <div class="share">
      <h1 class="share-title">Share episode</h1>
      <ul class="share-social-links">
        <li><a pp-href="shareLinks.facebook" class="share-link-facebook" target="_blank">Facebook</a></li>
        <li><a pp-href="shareLinks.googleplus" class="share-link-googleplus" target="_blank">Google+</a></li>
        <li><a pp-href="shareLinks.twitter" class="share-link-twitter" target="_blank">Twitter</a></li>
        <li><a pp-href="shareLinks.whatsapp" class="share-link-whatsapp" target="_blank">Whatsapp</a></li>
        <li><a pp-href="shareLinks.email" class="share-link-email" target="_blank">Email</a></li>
      </ul>
      <div class="share-episode-link">
        <h3>Copy episode link</h3>
        <p>
          <input class="share-copy-url" pp-value="url">
        </p>
        <h3>Copy player link</h3>
        <p>
          <input class="share-copy-url" pp-value="playerUrl">
        </p>
      </div>
      <div class="share-deeplink">
        <!--<input type="checkbox" pp-checked="showUrlWithTime" pp-on-change="updateContext">
        Start at
        <input type="text" pp-value="currentTime" disabled="disabled">-->
      </div>
      <div class="share-embed" pp-show="showEmbedUrl">
        <!--<h3>Embed player</h3>
        <input class="share-embed-code" pp-value="embedCode"/>-->
      </div>
    </div>
    """

module.exports = Share
