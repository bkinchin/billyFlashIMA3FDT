// Copyright 2013 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.

package com.google.ads.ima.examples.sdk_integration.web {

  import flash.display.DisplayObjectContainer;
  import flash.display.Stage;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.MouseEvent;
  import flash.events.NetStatusEvent;
  import flash.events.TimerEvent;
  import flash.media.Video;
  import flash.net.NetConnection;
  import flash.net.NetStream;
  import flash.utils.Timer;

  import mx.containers.Box;
  import mx.controls.Button;

  /**
   * Simple video player with bare minimum UI.
   */
  public class VideoPlayerFlex3 extends EventDispatcher {

    public static const CONTENT_COMPLETED_EVENT:String = "contentCompleted";
    public static const PLAYHEAD_CHANGED_EVENT:String = "playheadChanged";
    public static const PLAY_PAUSE_EVENT:String = "playPause";
    public static const LINEAR_ADS_REQUESTED_EVENT:String =
        "linearAdsRequested";
    public static const NONLINEAR_ADS_REQUESTED_EVENT:String =
        "nonLinearAdsRequested";

    // Playback state constants.
    public static const STOPPED:String = 'stopped';
    public static const PLAYING:String = 'playing';
    public static const PAUSED:String = 'paused';

    private var contentUrlValue:String;
    // Current media duration.
    private var currentVideoDuration:Number = 0;
    // Content netstream used to play video content.
    private var contentNetStream:NetStream;

    // Current playback state of the player.
    private var playerState:String = STOPPED;
    private var linearAdModeValue:Boolean;

    // Video element which plays the content.
    private var videoValue:Video;
    private var contentPlayheadValue:Number;
    private var contentPlayheadTimer:Timer;

    private var contentVideoDuration:Number;
    private var videoPlaceholder:DisplayObjectContainer;
    private var progressBar:Box;
    private var playhead:Box;
    private var playPauseButton:Button;
    private var requestLinearAdsButton:Button;
    private var requestNonLinearAdsButton:Button;

    public function VideoPlayerFlex3(video:Video,
        videoPlaceholder:DisplayObjectContainer,
        progressBar:Box,
        playhead:Box,
        playPauseButton:Button,
        requestLinearAdsButton:Button,
        requestNonLinearAdsButton:Button) {
      videoValue = video;
      this.videoPlaceholder = videoPlaceholder;
      videoPlaceholder.addChild(video);
      this.progressBar = progressBar;
      this.playhead = playhead;
      this.playPauseButton = playPauseButton;
      this.requestLinearAdsButton = requestLinearAdsButton;
      this.requestNonLinearAdsButton = requestNonLinearAdsButton;
      initialize();
    }

    public function get linearAdMode():Boolean {
      return linearAdModeValue;
    }

    public function set linearAdMode(value:Boolean):void {
      linearAdModeValue = value;
    }

    public function set contentUrl(url:String):void {
      contentUrlValue = url;
    }

    public function get stage():Stage {
      return videoPlaceholder.stage;
    }

    public function get videoDisplay():Video {
      return video;
    }

    public function play():void {
      if (playerState == PLAYING) {
        return;
      }
      if (playerState == STOPPED) {
        startContent();
      } else {
        contentNetStream.resume();
      }
      changePlayerState(PLAYING);
    }

    public function resume():void {
      contentNetStream.resume();
      changePlayerState(PLAYING);
    }

    public function pause():void {
      if (playerState == STOPPED || playerState == PAUSED) {
        return;
      } else {
        contentNetStream.pause();
        changePlayerState(PAUSED);
      }
    }

    public function get playing():Boolean {
      return playerState == VideoPlayerFlex3.PLAYING;
    }

    public function get contentPlayhead():Number {
      return contentPlayheadValue;
    }

    public function get width():Number {
      return videoPlaceholder.width;
    }

    public function get height():Number {
      return videoPlaceholder.height;
    }

    public function changePlayerState(newState:String):void {
      playerState = newState;
      switch (playerState) {
        case PAUSED:
        case STOPPED:
          setPlayPauseButtonText("Play");
          break;
        case PLAYING:
          setPlayPauseButtonText("Pause");
          break;
      }
    }

    private function initialize():void {
      playPauseButton.addEventListener(MouseEvent.CLICK,
                                       playPauseButtonClickHandler);
      requestLinearAdsButton.addEventListener(
          MouseEvent.CLICK,
          requestLinearAdsButtonClickHandler);
      requestNonLinearAdsButton.addEventListener(
          MouseEvent.CLICK,
          requestNonLinearAdsButtonClickHandler);
      contentPlayheadTimer = new Timer(500);
      contentPlayheadTimer.addEventListener(TimerEvent.TIMER, playheadHandler);
      contentPlayheadTimer.start();
    }

    private function get video():Video {
      return videoValue;
    }

    private function startContent():void {
      initContentNetStream();
      playContent(contentUrlValue);
    }

    private function playContent(videoSrcUrl:String):void {
      video.width = width;
      video.height = height;
      video.attachNetStream(contentNetStream);
      contentNetStream.play(videoSrcUrl);
      changePlayerState(PLAYING);
    }

    private function initContentNetStream():void {
      if (!contentNetStream) {
        var nc:NetConnection = new NetConnection();
        nc.connect(null);
        var customClient:Object = new Object();
        customClient.onMetaData = metaDataHandler;
        contentNetStream = new NetStream(nc);
        contentNetStream.client = customClient;
        contentNetStream.addEventListener(NetStatusEvent.NET_STATUS,
                                          netStatusHandler);
      }
    }

    private function playheadHandler(event:Event):void {
      if (linearAdMode) {
        return;
      }
      contentPlayheadValue = contentNetStream.time;
      if (playerState == PLAYING) {
        updateProgressBar(contentPlayhead, currentVideoDuration);
      }
    }

    private function netStatusHandler(event:NetStatusEvent):void {
      switch (event.info.level) {
        case "error":
          stop();
          break;
        case "status":
          switch (event.info.code) {
            case "NetStream.Play.Stop":
              dispatchEvent(new Event(CONTENT_COMPLETED_EVENT));
              stop();
              break;
          }
      }
    }

    private function metaDataHandler(infoObject:Object):void {
      contentVideoDuration = infoObject.duration;
      currentVideoDuration = contentVideoDuration;
      updateProgressBar(0, currentVideoDuration);
    }

    private function stop():void {
      contentNetStream.close();
      changePlayerState(STOPPED);
    }

    private function playPauseButtonClickHandler(event:Event):void {
      dispatchEvent(new Event(PLAY_PAUSE_EVENT));
      if (linearAdModeValue) {
        return;
      }
      if (playerState == STOPPED || playerState == PAUSED) {
        play();
      } else {
        pause();
      }
    }

    private function updateProgressBar(currentPlayheadTime:Number,
                                       currentVideoDuration:Number):void {
      var playheadWidth:Number = 0;
      if (currentPlayheadTime > 0 && currentVideoDuration > 0) {
        playheadWidth = (currentPlayheadTime / currentVideoDuration) *
           progressBar.width;
      }
      playhead.width = playheadWidth;
    }

    private function requestLinearAdsButtonClickHandler(event:MouseEvent):void {
      dispatchEvent(new Event(LINEAR_ADS_REQUESTED_EVENT));
    }

    private function requestNonLinearAdsButtonClickHandler(
        event:MouseEvent):void {
      dispatchEvent(new Event(NONLINEAR_ADS_REQUESTED_EVENT));
    }

    private function setPlayPauseButtonText(text:String):void {
      playPauseButton.label = text;
    }
  }
}
