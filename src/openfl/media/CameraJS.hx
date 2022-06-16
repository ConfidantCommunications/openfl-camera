package openfl.media;

import haxe.ds.Either;
import haxe.extern.EitherType;
import haxe.Timer;
import js.Promise;
import js.Browser;
import js.html.*;
import openfl.events.StatusEvent;
import openfl.events.EventDispatcher;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.net.NetStream;
import openfl.net.NetConnection;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;

@:access(openfl.display.BitmapData)
@:access(openfl.net.NetStream)
class CameraJS extends EventDispatcher {
	public var activityLevel(default, never):Float;
	public var bandwidth(default, never):Int;
	public var currentFPS(default, never):Float;
	public var fps(default, never):Float;
	public var height(default, null):Int = 320;
	public var index(default, never):Int;
	public var isSupported(default, never):Bool;
	public var keyFrameInterval(default, never):Int;
	public var loopback(default, never):Bool;
	public var motionLevel(default, never):Int;
	public var motionTimeout(default, never):Int;
	public var muted(default, never):Bool;
	public var name(default, null):String;

	public var names(default, null):Array<String> = [];
	public var permissionStatus(default, never):String;

	public var position(default, never):String;
	public var quality(default, never):Int;
	public var width(default, null):Int = 240;

	public var mediaDevices:MediaDevices;
	public var devices = new Map<String, MediaDeviceInfo>();

	var stream:MediaStream;
	@:noCompletion var __video(default, null):VideoElement;

	var netStream:NetStream;
	var video(get, null):VideoElement;

	var idealWidth:Null<Int>;
	var idealHeight:Null<Int>;
	var idealFps:Null<Float>;
	var idealFavorArea:Bool = true;

	/* static function __init__() {
		mediaDevices = Reflect.getProperty(Browser.navigator, 'mediaDevices');
		findAvailableDevices(true);
	} */
	
	public function new(name:String = null) {
		super();
		this.name = name;
		mediaDevices = Reflect.getProperty(Browser.navigator, 'mediaDevices');

		// mediaDevices.ondevicechange = ondevicechange;

		netStream = new NetStream(new NetConnection(), null);
		netStream.__video.onloadedmetadata = function(e:Dynamic) {
			netStream.__video.play();
		};

		findAvailableDevices(findDevice);
	}
	

	public function findAvailableDevices(callback:Void->Void = null, updateNames:Bool = false) {
		var names:Array<String> = [];
		if (devices == null) {
			devices = new Map<String, MediaDeviceInfo>();
		}

		mediaDevices.enumerateDevices().then(function(_devices:Array<MediaDeviceInfo>) {
			for (device in _devices) {
				if (device.kind == MediaDeviceKind.VIDEOINPUT) {
					names.push(device.label);
					devices.set(device.label, device);
					// trace([device.label, device]);
				}
			}
			if (updateNames)
				this.names = names;
			if (callback != null)
				callback();
		});
	}

	function ondevicechange(e:Dynamic) {
		clearActive();
		Timer.delay(() -> {
			findAvailableDevices(findDevice);
		}, 100);
	}

	public function clearActive() {
		if (this.stream != null) {
			var tracks:Array<MediaStreamTrack> = this.stream.getTracks();
			for (track in tracks) {
				track.stop();
				this.stream.removeTrack(track);
			}
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, StatusEventCode.INACTIVE));
		}
		this.stream = null;
		netStream.__video.srcObject = null;
	}

	function findDevice() {
		trace("findDevice");
		var deviceInfo:MediaDeviceInfo = null;
		if (name != null) {
			deviceInfo = devices.get(name);
		} else {
			for (item in devices.iterator()) {
				deviceInfo = item;
				break;
			}
		}

		var constraints:MediaStreamConstraints = {audio: false, video: true};
		if (deviceInfo != null) {
			var trackConstraints:MediaTrackConstraints = {
				deviceId: {exact: deviceInfo.deviceId},
			};
			if (idealWidth != null)
				trackConstraints.width = {ideal: idealWidth};
			if (idealHeight != null)
				trackConstraints.height = {ideal: idealHeight};
			if (idealFps != null)
				trackConstraints.frameRate = {ideal: idealFps};
			constraints.video = trackConstraints;
		} else if (name != null) {
			trace("not device with name " + name + " found");
			return;
		}
		js.Browser.console.log("idealWidth = " + idealWidth);
		js.Browser.console.log("idealHeight = " + idealHeight);
		js.Browser.console.log("idealFps = " + idealFps);

		js.Browser.console.log(deviceInfo);
		js.Browser.console.log(constraints);
		mediaDevices.getUserMedia(constraints).then(function(stream:MediaStream) {
			trace("stream");

			this.stream = stream;
			netStream.__video.srcObject = stream;
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, StatusEventCode.ACTIVE));
		}).catchError(function(error:Dynamic) {
			trace(error);
		});
	}

	public function copyToByteArray(rect:Rectangle, destination:ByteArray):Void {
		var canvas = toCanvas(0, 0, Math.floor(rect.width), Math.floor(rect.height));
		var bmd:BitmapData = BitmapData.fromCanvas(canvas, true);
		var b = bmd.getPixels(rect);
		destination.readBytes(b, 0, b.length);
	}

	public function copyToVector(rect:Rectangle, destination:Vector<UInt>):Void {
		var canvas = toCanvas(0, 0, Math.floor(rect.width), Math.floor(rect.height));
		var bmd:BitmapData = BitmapData.fromCanvas(canvas, true);
		var v = bmd.getVector(rect);
		for (i in 0...v.length) {
			destination.push(v[i]);
		}
	}

	public function drawToBitmapData(destination:BitmapData):Void {
		var canvas = toCanvas(0, 0, destination.width, destination.height);
		var bmd:BitmapData = BitmapData.fromCanvas(canvas, destination.transparent);
		destination.draw(bmd);
	}

	function toCanvas(x:Int, y:Int, width:Int, height:Int) {
		var canvas:CanvasElement = Browser.document.createCanvasElement();
		var ctx:CanvasRenderingContext2D = canvas.getContext('2d');
		canvas.width = width;
		canvas.height = height;
		ctx.drawImage(netStream.__video, 0, 0);
		return canvas;
	}

	public function getCamera(name:String = null):CameraJS {
		var cam = new CameraJS(name);
		return cam;
	}

	public function requestPermission():Void {
		throw "neess to be implemented";
	}

	public function setKeyFrameInterval(keyFrameInterval:Int):Void {
		throw "neess to be implemented";
	}

	public function setLoopback(compress:Bool = false):Void {
		throw "neess to be implemented";
	}

	public function setMode(width:Int, height:Int, fps:Float, favorArea:Bool = true):Void {
		trace("setMode");
		this.width = idealWidth = width;
		this.height = idealHeight = height;
		idealFps = fps;
		idealFavorArea = favorArea;
	}

	public function setMotionLevel(motionLevel:Int, timeout:Int = 2000):Void {
		throw "neess to be implemented";
	}

	public function setQuality(bandwidth:Int, quality:Int):Void {
		throw "neess to be implemented";
	}

	function get_video():VideoElement {
		return netStream.__video;
	}
}