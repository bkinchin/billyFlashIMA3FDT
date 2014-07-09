// Copyright 2013 Google Inc. All Rights Reserved.
// You may study, modify, and use this example for any purpose.
// Note that this example is provided "as is", WITHOUT WARRANTY
// of any kind either expressed or implied.

package com.google.ads.ima.examples.sdk_integration.web {
  import com.google.ads.ima.api.AdErrorEvent;
  import com.google.ads.ima.api.AdEvent;
  import com.google.ads.ima.api.AdsLoader;
  import com.google.ads.ima.api.AdsManager;
  import com.google.ads.ima.api.AdsManagerLoadedEvent;
  import com.google.ads.ima.api.AdsRenderingSettings;
  import com.google.ads.ima.api.AdsRequest;
  import com.google.ads.ima.api.ViewModes;

  import flash.display.DisplayObjectContainer;
  import flash.events.Event;

  /**
   * Simple Google IMA SDK video player integration.
   */
  public class SdkIntegrationExampleFlex3 {

    private static const CONTENT_URL:String =
        "http://rmcdn.2mdn.net/Demo/vast_inspector/android.flv";

    private static const LINEAR_AD_TAG:String =
        "http://pubads.g.doubleclick.net/gampad/ads?ad_rule=1&ciu_szs=728x90&cmsid=&cust_params=frmt%3D0%26frmt%3D1%26frmt%3D22%26plID%3D1203918425001%26ttID%3D3636696619001%26%2Fnews%2F%2F_%2F%2Fnational-news%2F%2F_%2F%2F_%2F%2F_%2F%2F_%26sz%3D640x480%26short%3Dn%26sectn%3Dnational-news%26site%3Dnews%26sourc%3DONENews%26did%3D6009792%26cue%3Dpre%26cgm%3D0&description_url=http%3A%2F%2Fstage.tvnz.co.nz%2Fnational-news%2Fclear-message-incontinence-awareness-week-video-6009792&dt=1404794266515&env=vp&flash=14.0.0.145&frm=0&gdfp_req=1&ged=ve2_ta1_pt4.1.4_td4_tt1_bs10_pd1_tv1_is0_er250.415.610.1055_sv2_sp1_vi0.0.832.1759_vp100_va100_ct1_vb1_vl1_vr1&hl=en&impl=s&iu=%2F4180%2Fstage.tvnz.co.nz%2Fnews%2F_%2Fnational-news%2F_%2F_%2F_%2F_&osd=2&output=xml_vast3&scor=2659238872612864&sdkv=3.0.148&sz=640x480&u_ah=983&u_asa=1&u_aw=1920&u_cd=24&u_h=1080&u_his=1&u_java=true&u_nmime=58&u_nplug=13&u_tz=600&u_w=1920&unviewed_position_start=1&vid=3636696619001";
	//private static const LINEAR_AD_TAG:String =	
		//"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
        //"iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&impl=s&" +
        //"gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
        //"url=[referrer_url]&correlator=[timestamp]&" +
        //"cust_params=iab_vast_samples%3Dlinear";
		

    private static const NONLINEAR_AD_TAG:String =
        "http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
        "iu=%2F6062%2Fiab_vast_samples&ciu_szs=300x250%2C728x90&" +
        "impl=s&gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&" +
        "url=[referrer_url]&correlator=[timestamp]&" +
        "cust_params=iab_vast_samples%3Dimageoverlay";

    // Custom video player using netstream.
    private var videoPlayer:VideoPlayerFlex3;
    private var contentPlayheadTime:Number;

    // SDK Objects
    private var adsLoader:AdsLoader;
    private var adsManager:AdsManager;

    /**
     * Sets up the click-to-play player for ads and content playback.
     *
     * @param videoPlayerValue The content video player.
     */
    public function SdkIntegrationExampleFlex3(
        videoPlayerValue:VideoPlayerFlex3):void {
      videoPlayer = videoPlayerValue;
      videoPlayer.contentUrl = CONTENT_URL;
      videoPlayer.play();
      videoPlayer.addEventListener(VideoPlayerFlex3.CONTENT_COMPLETED_EVENT,
          contentCompleteHandler);
      videoPlayer.addEventListener(VideoPlayerFlex3.PLAYHEAD_CHANGED_EVENT,
                                   contentPlayheadTimeChangeHandler);
      videoPlayer.addEventListener(VideoPlayerFlex3.LINEAR_ADS_REQUESTED_EVENT,
                                   linearAdsSelectionHandler);
      videoPlayer.addEventListener(
          VideoPlayerFlex3.NONLINEAR_ADS_REQUESTED_EVENT,
          nonLinearAdsSelectionHandler);
		  trace("hello billy");
    }

    private function linearAdsSelectionHandler(event:Event):void {
      destroyAdsManager();
      requestAds(LINEAR_AD_TAG);
    }

    private function nonLinearAdsSelectionHandler(event:Event):void {
      if (videoPlayer.linearAdMode) {
        contentResumeRequestedHandler();
      }
      destroyAdsManager();
      requestAds(NONLINEAR_AD_TAG);
    }

    /**
     * Request ads using the specified ad tag.
     *
     * @param adTag A URL that will return a valid VAST response.
     */
    private function requestAds(adTag:String):void {
      if (adsLoader == null) {
        // On the first request, create the AdsLoader.
        adsLoader = new AdsLoader();
        adsLoader.addEventListener(AdsManagerLoadedEvent.ADS_MANAGER_LOADED,
                                   adsManagerLoadedHandler);
        adsLoader.addEventListener(AdErrorEvent.AD_ERROR, adsLoadErrorHandler);
      }

      // The AdsRequest encapsulates all the properties required to request ads.
      var adsRequest:AdsRequest = new AdsRequest();
      adsRequest.adTagUrl = adTag;
      adsRequest.linearAdSlotWidth = videoPlayer.width;
      adsRequest.linearAdSlotHeight = videoPlayer.height;
      adsRequest.nonLinearAdSlotWidth = videoPlayer.width;
      adsRequest.nonLinearAdSlotHeight = videoPlayer.height;
	  trace("requestads");

      // Instruct the AdsLoader to request ads using the AdsRequest object.
      adsLoader.requestAds(adsRequest);
    }

    /**
     * Invoked when the AdsLoader successfully fetched ads.
     */
    private function adsManagerLoadedHandler(event:AdsManagerLoadedEvent):void {
	  trace("adsloaded");
      // Publishers can modify the default preferences through this object.
      var adsRenderingSettings:AdsRenderingSettings =
          new AdsRenderingSettings();

      // In order to support VMAP ads, ads manager requires an object that
      // provides current playhead position for the content.
      var contentPlayhead:Object = {};
      contentPlayhead.time = function():Number {
        return contentPlayheadTime * 1000; // convert to milliseconds.
      };

      // Get a reference to the AdsManager object through the event object.
      adsManager = event.getAdsManager(contentPlayhead, adsRenderingSettings);
      if (adsManager) {
		trace("adsManager");
        // Add required ads manager listeners.
        // ALL_ADS_COMPLETED event will fire once all the ads have played. There
        // might be more than one ad played in the case of ad pods and VMAP.
        adsManager.addEventListener(AdEvent.ALL_ADS_COMPLETED,
                                    allAdsCompletedHandler);
        // If ad is linear, it will fire content pause request event.
        adsManager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED,
                                    contentPauseRequestedHandler);
        // When ad finishes or if ad is non-linear, content resume event will be
        // fired. For example, if VMAP response only has post-roll, content
        // resume will be fired for pre-roll ad (which is not present) to signal
        // that content should be started or resumed.
        adsManager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED,
                                    contentResumeRequestedHandler);
        // We want to know when an ad starts.
        adsManager.addEventListener(AdEvent.STARTED, startedHandler);
        adsManager.addEventListener(AdErrorEvent.AD_ERROR,
                                    adsManagerPlayErrorHandler);

        // If your video player supports a specific version of VPAID ads, pass
        // in the version. If your video player does not support VPAID ads yet,
        // just pass in 1.0.
        adsManager.handshakeVersion("1.0");
        // Init should be called before playing the content in order for VMAP
        // ads to function correctly.
        adsManager.init(videoPlayer.videoDisplay.width,
                        videoPlayer.videoDisplay.height,
                        ViewModes.NORMAL);
        // Add the adsContainer to the display list.
        DisplayObjectContainer(videoPlayer.videoDisplay.parent).addChild(
            adsManager.adsContainer);
        // Start the ad playback.
        trace("start");
        adsManager.start();
      }
    }

    /**
     * If an error occurs during the ads load, the content can be resumed or
     * another ads request can be made. In this example, the content is resumed
     * if there's an error loading ads.
     */
    private function adsLoadErrorHandler(event:AdErrorEvent):void {
      trace("warning", "Ads load error: " + event.error.errorMessage);
      videoPlayer.play();
    }

    /**
     * Errors that occur during ads manager play should be treated as
     * informational signals. The SDK will send all ads completed event if there
     * are no more ads to display.
     */
    private function adsManagerPlayErrorHandler(event:AdErrorEvent):void {
      trace("warning", "Ad playback error: " + event.error.errorMessage);
    }

    /**
     * Clean up AdsManager references when no longer needed. Explicit cleanup
     * is necessary to prevent memory leaks.
     */
    private function destroyAdsManager():void {
      enableContentControls();
      if (adsManager) {
        if (adsManager.adsContainer.parent &&
            adsManager.adsContainer.parent.contains(adsManager.adsContainer)) {
          adsManager.adsContainer.parent.removeChild(adsManager.adsContainer);
        }
        adsManager.destroy();
      }
    }

    /**
     * The AdsManager raises this event when it requests the publisher to pause
     * the content.
     */
    private function contentPauseRequestedHandler(event:AdEvent):void {
      // The ad will cover a large portion of the content, therefore content
      // must be paused.
      if (videoPlayer.playing) {
        videoPlayer.pause();
      }
      // Rewire controls to affect ads manager instead of the content video.
      enableLinearAdControls();
    }

    /**
     * The AdsManager raises this event when it requests the publisher to resume
     * the content.
     */
    private function contentResumeRequestedHandler(event:AdEvent = null):void {
      // Rewire controls to affect content instead of the ads manager.
      enableContentControls();
      videoPlayer.linearAdMode = false;
      videoPlayer.resume();
    }

    /**
     * The AdsManager raises this event when the ad has started.
     */
    private function startedHandler(event:AdEvent):void {
	  trace("started1");
      if (!event.ad) {
        return;
      }
      // If the ad exists and is a non-linear, start the content with the ad.
      if (!event.ad.linear) {
        videoPlayer.play();
      } else {
        videoPlayer.linearAdMode = true;
        videoPlayer.changePlayerState(VideoPlayerFlex3.PLAYING);
      }
    }

    /**
     * The AdsManager raises this event when all ads for the request have been
     * played.
     */
    private function allAdsCompletedHandler(event:AdEvent):void {
      // Ads manager can be destroyed after all of its ads have played.
      destroyAdsManager();
    }

    /**
     * The video player raises this event when the user clicks the play/pause
     * button.
     */
    private function playPauseButtonHandler(event:Event):void {
      if (videoPlayer.playing) {
        adsManager.pause();
        videoPlayer.changePlayerState(VideoPlayerFlex3.PAUSED);
      } else {
        adsManager.resume();
        videoPlayer.changePlayerState(VideoPlayerFlex3.PLAYING);
      }
    }

    private function enableLinearAdControls():void {
      videoPlayer.addEventListener(VideoPlayerFlex3.PLAY_PAUSE_EVENT,
                                   playPauseButtonHandler);
    }

    private function enableContentControls():void {
      videoPlayer.removeEventListener(VideoPlayerFlex3.PLAY_PAUSE_EVENT,
                                      playPauseButtonHandler);
    }

    /**
     * Update the playhead time for the AdsManager.
     */
    private function contentPlayheadTimeChangeHandler(event:Event):void {
      contentPlayheadTime = videoPlayer.contentPlayhead;
    }

    private function contentCompleteHandler(event:Event):void {
      videoPlayer.removeEventListener(VideoPlayerFlex3.CONTENT_COMPLETED_EVENT,
                                      contentCompleteHandler);
      // Tell the SDK when any content completes, even content without ads. The
      // SDK uses this method for better ad selection (especially VMAP).
      adsLoader.contentComplete();
    }
  }
}
