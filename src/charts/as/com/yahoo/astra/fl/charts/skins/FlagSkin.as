﻿package com.yahoo.astra.fl.charts.skins
{
	import com.yahoo.astra.fl.charts.series.SeriesItemRenderer;
	import fl.core.UIComponent;
	import flash.text.TextField;

	public class FlagSkin extends SeriesItemRenderer implements IProgrammaticSkin, INoteSkin
	{
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 * Constructor.
		 */
		public function FlagSkin()
		{
			super();
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		private var _text:String = "";
		
		public function get text():String {
			return this._text;
		}
		
		public function set text(value:String):void {
			this._text = value;
		}
		
		/**
		 * @private
		 * Storage for the fillColor property.
		 */
		private var _fillColor:uint = 0x000000;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.skins.IProgrammaticSkin#fillColor
		 */
		public function get fillColor():uint
		{
			return this._fillColor;
		}
		
		/**
		 * @private
		 */
		public function set fillColor(value:uint):void
		{
			if(this._fillColor != value)
			{
				this._fillColor = value;
				this.invalidate();
			}
		}
		
		/**
		 * @private 
		 * Storage for outline color
		 */
		private var _borderColor:uint = 0x000000;
		
		/**
		 * @copy com.yahoo.astra.fl.charts.skins.IProgrammaticSkin#borderColor
		 */
		public function get borderColor():uint
		{
			return _borderColor;
		}
		
		/**
		 * @private (setter)
		 */
		public function set borderColor(value:uint):void
		{
			if(this._borderColor != value)
			{
				this._borderColor = value;
				this.invalidate();
			}
		}
		
		/**
		 * @private
		 * Storage for the fill alpha.
		 */
		private var _fillAlpha:Number = 1;
		
		/**
		 * The alpha value of the fill.
		 */
		public function get fillAlpha():Number
		{
			return _fillAlpha;
		}

		/**
		 * @private (setter)
		 */
		public function set fillAlpha(value:Number):void
		{
			if(this._fillAlpha != value)
			{
				this._fillAlpha = value;
				this.invalidate();
			}
		}
		
		/**
		 * @private
		 * Storage for the border alpha.
		 */
		private var _borderAlpha:Number = 1;
		
		/**
		 * The alpha value of the border.
		 */
		public function get borderAlpha():Number
		{
			return _borderAlpha;
		}
		
		/**
		 * @private (setter)
		 */
		public function set borderAlpha(value:Number):void
		{
			if(this._borderAlpha != value)
			{
				this._borderAlpha = value;
				this.invalidate();
			}
		}		

	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
	
		/**
		 * @private
		 */
		override protected function draw():void
		{
			super.draw();
			
			//since the Blaze component architecture rounds the position,
			//we need to account for that to make sure the mark displays correctly.
			var xDiff:Number = this._x - Math.round(this._x);
			var yDiff:Number = this._y - Math.round(this._y);
			
			this.graphics.clear();
			if(this.width == 0 || this.height == 0 || isNaN(this.width) || isNaN(this.height))
			{
				return;
			}
			
			if(this.borderColor == this.fillColor)
			{
				this.graphics.lineStyle(0, 0, 0);
			}
			else
			{
				this.graphics.lineStyle(1, this.borderColor, this.borderAlpha);
			}
			
			this.graphics.beginFill(this.fillColor, this.fillAlpha);
			this.graphics.drawRect(xDiff, yDiff, this.width, this.height);
			this.graphics.moveTo(this.width / 2 - 5, this.height);
			this.graphics.lineTo(this.width / 2, this.height + 5);
			this.graphics.lineTo(this.width / 2 + 5, this.height);
			this.graphics.endFill();
			
			var tv:TextField = new TextField();
			tv.height = this.height;
			tv.width = this.width;
			tv.text = this.text;
			this.addChild(tv);
		}
		
	}
}