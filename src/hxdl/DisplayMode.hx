package hxdl;

// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


class DisplayMode {
    public var height:Int;
    public var width:Int;
    public var pixelFormat:PixelFormat;

    public var refreshRate:Int;


    public function new(_width:Int = 0, _height:Int = 0, _pixelFormat:PixelFormat = RGBA32, _refreshRate:Int = 0){
        width = _width;
		height = _height;
		pixelFormat = _pixelFormat;
		refreshRate = _refreshRate;
    }
}