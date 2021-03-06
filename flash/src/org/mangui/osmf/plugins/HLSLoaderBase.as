//-------------------------------------------------------------------------------
// Copyright (c) 2014-2013 NoZAP B.V.
// Copyright (c) 2013 Guillaume du Pontavice (https://github.com/mangui/HLSprovider)
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// 
// Authors:
//     Jeroen Arnoldus
//     Guillaume du Pontavice
//-------------------------------------------------------------------------------

package org.mangui.osmf.plugins
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
  import flash.net.*;
	
	
	import org.osmf.elements.VideoElement;
	import org.osmf.elements.proxyClasses.LoadFromDocumentLoadTrait;
	import org.osmf.events.MediaError;
	import org.osmf.events.MediaErrorEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.LoaderBase;
			
	import org.mangui.HLS.HLS;
	import org.mangui.HLS.HLSEvent;
	
	/**
	 * Loader for .m3u8 playlist file.
	 * Works like a F4MLoader
	 */
	public class HLSLoaderBase extends LoaderBase
	{
		
		private var _loadTrait:LoadTrait;
    /** Reference to the framework. **/
    private static var _hls:HLS = null;
		
		public function HLSLoaderBase(){
			super();
		}

        public static function canHandle(resource:MediaResourceBase):Boolean
        {
            if (resource !== null && resource is URLResource) {
                var urlResource:URLResource = URLResource(resource);
                if (urlResource.url.search(/(https?|file)\:\/\/.*?\.m3u8(\?.*)?/i) !== -1) {
                    return true;
                }

                var contentType:Object = urlResource.getMetadataValue("content-type");
                if (contentType && contentType is String) {
                    // If the filename doesn't include a .m3u8 extension, but
                    // explicit content-type metadata is found on the
                    // URLResource, we can handle it.  Must be either of:
                    // - "application/x-mpegURL"
                    // - "vnd.apple.mpegURL"
                    if ((contentType as String).search(/(application\/x-mpegURL|vnd.apple.mpegURL)/i) !== -1) {
                        return true;
                    }
                }
            }
            return false;
        }
        
        public static function get hls():HLS {
          return _hls;
        }
        
		
		override public function canHandleResource(resource:MediaResourceBase):Boolean{
            return canHandle(resource);
		}
		
		private function onError(e:ErrorEvent):void
		{		
			updateLoadTrait(_loadTrait, LoadState.LOAD_ERROR);
			_loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(0, 'This video is not available.')));
		}
	
		override protected function executeLoad(loadTrait:LoadTrait):void
		{
			_loadTrait = loadTrait;
			updateLoadTrait(loadTrait, LoadState.LOADING);
      if (_hls == null) {
        _hls = new HLS();
        _hls.addEventListener(HLSEvent.MANIFEST_LOADED,_manifestHandler);        
      }
      /* load playlist */
      _hls.play(URLResource(loadTrait.resource).url,0);
		}
		
		override protected function executeUnload(loadTrait:LoadTrait):void
		{
			updateLoadTrait(loadTrait, LoadState.UNINITIALIZED);
		}
	
		
  /** Update video A/R on manifest load. **/
  private function _manifestHandler(event:HLSEvent):void {
      var resource:MediaResourceBase = URLResource(_loadTrait.resource);
      
			try{
				var loadedElem:MediaElement = new VideoElement(null, new HLSNetLoader(_hls,event.levels[0].duration));
				loadedElem.resource = resource;
				
				LoadFromDocumentLoadTrait(_loadTrait).mediaElement = loadedElem;
				
				updateLoadTrait(_loadTrait, LoadState.READY);
			}catch(e:Error){
				updateLoadTrait(_loadTrait, LoadState.LOAD_ERROR);
				_loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(e.errorID, e.message)));
			}
  };
	}
}