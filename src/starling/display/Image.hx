// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import openfl.display.Bitmap;
import openfl.errors.ArgumentError;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import starling.core.RenderSupport;
import starling.textures.Texture;
import starling.textures.TextureSmoothing;
import starling.utils.VertexData;

/** An Image is a quad with a texture mapped onto it.
 *  
 *  <p>The Image class is the Starling equivalent of Flash's Bitmap class. Instead of 
 *  BitmapData, Starling uses textures to represent the pixels of an image. To display a 
 *  texture, you have to map it onto a quad - and that's what the Image class is for.</p>
 *  
 *  <p>As "Image" inherits from "Quad", you can give it a color. For each pixel, the resulting  
 *  color will be the result of the multiplication of the color of the texture with the color of 
 *  the quad. That way, you can easily tint textures with a certain color. Furthermore, images 
 *  allow the manipulation of texture coordinates. That way, you can move a texture inside an 
 *  image without changing any vertex coordinates of the quad. You can also use this feature
 *  as a very efficient way to create a rectangular mask.</p> 
 *  
 *  @see starling.textures.Texture
 *  @see Quad
 */ 
class Image extends Quad
{
	private var mTexture:Texture;
	private var mSmoothing:String;
	
	private var mVertexDataCache:VertexData;
	private var mVertexDataCacheInvalid:Bool;
	
	
	public var texture(get, set):Texture;
	public var smoothing(get, set):String;
	
	private var random:Int = 0;
	
	/** Creates a quad with a texture mapped onto it. */
	public function new(texture:Texture)
	{
		if (texture != null)
		{
			random = cast Math.random() * 200000;
			
			var frame:Rectangle = texture.frame;
			var width:Float  = (frame != null) ? frame.width  : texture.width;
			var height:Float = (frame != null) ? frame.height : texture.height;
			var pma:Bool = texture.premultipliedAlpha;
			
			super(width, height, 0xffffff, pma);
			
			mVertexData.setTexCoords(0, 0.0, 0.0);
			mVertexData.setTexCoords(1, 1.0, 0.0);
			mVertexData.setTexCoords(2, 0.0, 1.0);
			mVertexData.setTexCoords(3, 1.0, 1.0);
			
			mTexture = texture;
			mSmoothing = TextureSmoothing.BILINEAR;
			mVertexDataCache = new VertexData(4, pma);
			mVertexDataCacheInvalid = true;
		}
		else
		{
			throw new ArgumentError("Texture cannot be null");
		}
	}
	
	/** Creates an Image with a texture that is created from a bitmap object. */
	public static function fromBitmap(bitmap:Bitmap, generateMipMaps:Bool=true, 
									  scale:Float=1):Image
	{
		return new Image(Texture.fromBitmap(bitmap, generateMipMaps, false, scale));
	}
	
	/** @inheritDoc */
	private override function onVertexDataChanged():Void
	{
		mVertexDataCacheInvalid = true;
	}
	
	/** Readjusts the dimensions of the image according to its current texture. Call this method 
	 *  to synchronize image and texture size after assigning a texture with a different size.*/
	public function readjustSize():Void
	{
		var frame:Rectangle = texture.frame;
		var width:Float  = frame != null ? frame.width  : texture.width;
		var height:Float = frame != null ? frame.height : texture.height;
		
		mVertexData.setPosition(0, 0.0, 0.0);
		mVertexData.setPosition(1, width, 0.0);
		mVertexData.setPosition(2, 0.0, height);
		mVertexData.setPosition(3, width, height); 
		
		onVertexDataChanged();
	}
	
	/** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
	public function setTexCoords(vertexID:Int, coords:Point):Void
	{
		mVertexData.setTexCoords(vertexID, coords.x, coords.y);
		onVertexDataChanged();
	}
	
	/** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
	public function setTexCoordsTo(vertexID:Int, u:Float, v:Float):Void
	{
		mVertexData.setTexCoords(vertexID, u, v);
		onVertexDataChanged();
	}
	
	/** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. 
	 *  If you pass a 'resultPoint', the result will be stored in this point instead of 
	 *  creating a new object.*/
	public function getTexCoords(vertexID:Int, resultPoint:Point=null):Point
	{
		if (resultPoint == null) resultPoint = new Point();
		mVertexData.getTexCoords(vertexID, resultPoint);
		return resultPoint;
	}
	
	/** Copies the raw vertex data to a VertexData instance.
	 *  The texture coordinates are already in the format required for rendering. */ 
	public override function copyVertexDataTo(targetData:VertexData, targetVertexID:Int=0):Void
	{
		copyVertexDataTransformedTo(targetData, targetVertexID, null);
	}
	
	/** Transforms the vertex positions of the raw vertex data by a certain matrix
	 *  and copies the result to another VertexData instance.
	 *  The texture coordinates are already in the format required for rendering. */
	public override function copyVertexDataTransformedTo(targetData:VertexData,
														 targetVertexID:Int=0,
														 matrix:Matrix=null):Void
	{
		if (mVertexDataCacheInvalid)
		{
			mVertexDataCacheInvalid = false;
			mVertexData.copyTo(mVertexDataCache);
			mTexture.adjustVertexData(mVertexDataCache, 0, 4);
		}
		
		mVertexDataCache.copyTransformedTo(targetData, targetVertexID, matrix, 0, 4);
		
	}
	
	/** The texture that is displayed on the quad. */
	public function get_texture():Texture { return mTexture; }
	public function set_texture(value:Texture):Texture 
	{ 
		if (value == null)
		{
			throw new ArgumentError("Texture cannot be null");
		}
		else if (value != mTexture)
		{
			mTexture = value;
			mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
			mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, false);
			onVertexDataChanged();
		}
		
		return value;
	}
	
	/** The smoothing filter that is used for the texture. 
	*   @default bilinear
	*   @see starling.textures.TextureSmoothing */ 
	public function get_smoothing():String { return mSmoothing; }
	public function set_smoothing(value:String):String 
	{
		if (TextureSmoothing.isValid(value))
			mSmoothing = value;
		else
			throw new ArgumentError("Invalid smoothing mode: " + value);
		return value;
	}
	
	/** @inheritDoc */
	public override function render(support:RenderSupport, parentAlpha:Float):Void
	{
		support.batchQuad(this, parentAlpha, mTexture, mSmoothing);
	}
}