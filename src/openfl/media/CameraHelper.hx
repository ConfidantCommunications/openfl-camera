package openfl.media;

import js.lib.Promise;
import js.Browser;
import js.html.*;

// using Camera.MediaDeviceInfo;
// using Camera.MediaDevices;
// using Camera.MediaDeviceKind;

/**
 * This class makes it easier to work with multiple cameras. Maybe. 
 */

class CameraHelper {
	public static var instance(default, null):CameraHelper = new CameraHelper();
    var mediaDevices:MediaDevices;

	private function new(){
        mediaDevices = Reflect.getProperty(Browser.navigator, 'mediaDevices');
    }
	/**
	 * Returns the name of the next camera. 
	 * @param currentCamera 
	 * @param callback 
     * 
     * 
        var jsCam:Camera;
        var jsCamName:String = ""; //retain the name of the currently used camera
        CameraHelper.instance.nextCamera(jsCamName,function(s:String){
            trace("nextCamera name:"+s); //returns something like "Back Camera"
            jsCam = Camera.getCamera(s);
            jsCamName = s;
        });
	 */
    /* public function stopStream(stream:MediaStream):Void {
        for (t in stream.getTracks()){
            t.stop();
        }
    } */
	public function nextCamera(currentCamera:String = "",callback:String->Void):Void {
        mediaDevices.enumerateDevices().then(function(_devices:Array<MediaDeviceInfo>) {
            var names:Array<String> = [];
			for (device in _devices) {
				if (device.kind == MediaDeviceKind.VIDEOINPUT) {
                    trace("device:"+device.label);
					names.push(device.label);
				}
			}
            var nextCameraIndex:Int = 0;
            trace("test:"+names.indexOf(currentCamera)+":"+names.length);
            if(currentCamera != "" && names.indexOf(currentCamera) < names.length-1){
                nextCameraIndex = names.indexOf(currentCamera) + 1;
            } 
            callback(names[nextCameraIndex]);
            
		});

    }

}