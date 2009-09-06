package com.yahoo.astra.fl.charts.series
{
	import com.yahoo.astra.animation.Animation;
	import com.yahoo.astra.animation.AnimationEvent;
	import com.yahoo.astra.fl.charts.*;
	import com.yahoo.astra.fl.charts.axes.NumericAxis;
	import com.yahoo.astra.fl.charts.skins.FlagSkin;
	import com.yahoo.astra.utils.GraphicsUtil;
	
	import fl.core.UIComponent;
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
     * The color for the note.
     */
    [Style(name="fillColor", type="uint")]

	/**
     * The alpha for the note.
     */
    [Style(name="fillAlpha", type="Number")]

    /**
     * The color of the border.
     */
    [Style(name="borderColor", type="uint")]

	/**
     * Alpha for the border.
     */
    [Style(name="borderAlpha", type="Number")]
	
	/**
     * Alpha for the border.
     */
    [Style(name="textColor", type="uint")]

	/**
	 * Renders data points as a series of connected line segments.
	 * 
	 * @author Josh Tynjala
	 */
	public class NotesSeries extends CartesianSeries
	{
		
	//--------------------------------------
	//  Class Variables
	//--------------------------------------
		
		/**
		 * @private
		 */
		private static var defaultStyles:Object =
		{
			markerSkin: null,
			fillColor: 0x000000,
			borderColor: 0xFF0000,
			fillAlpha: 1,
			borderAlpha: 1,
			textColor: 0xFF0000
		};
		
		/**
		 * @private
		 */
		private var skinjobs:Array = [];
		
	//--------------------------------------
	//  Class Methods
	//--------------------------------------
	
		/**
		 * @copy fl.core.UIComponent#getStyleDefinition()
		 */
		public static function getStyleDefinition():Object
		{
			return mergeStyles(defaultStyles, Series.getStyleDefinition());
		}
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
	
		/**
		 *  Constructor.
		 */
		public function NotesSeries(data:Object = null)
		{
			super(data);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
	
		/**
		 * @private
		 * The Animation instance that controls animation in this series.
		 */
		private var _animation:Animation;
		
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * @inheritDoc
		 */
		override public function clone():ISeries
		{
			var series:LineSeries = new LineSeries();
			if(this.dataProvider is Array)
			{
				//copy the array rather than pass it by reference
				series.dataProvider = (this.dataProvider as Array).concat();
			}
			else if(this.dataProvider is XMLList)
			{
				series.dataProvider = (this.dataProvider as XMLList).copy();
			}
			series.displayName = this.displayName;
			series.horizontalField = this.horizontalField;
			series.verticalField = this.verticalField;
			
			return series;
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
			
			this.graphics.clear();
			
			if(!this.dataProvider)
			{
				return;
			}
			
			var markerSize:Number = this.getStyleValue("markerSize") as Number;
			
			var startValues:Array = [];
			var endValues:Array = [];
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var position:Point = CartesianChart(this.chart).itemToPosition(this, i);
				
				var marker:DisplayObject = this.markers[i] as DisplayObject;
				var ratio:Number = marker.width / marker.height;
				if(isNaN(ratio)) ratio = 1;
				marker.height = markerSize;
				marker.width = marker.height * ratio;
				
				if(marker is UIComponent) 
				{
					(marker as UIComponent).drawNow();
				}
				
				//if we have a bad position, don't display the marker
				if(isNaN(position.x) || isNaN(position.y))
				{
					this.invalidateMarker(ISeriesItemRenderer(marker));
				}
				else if(this.isMarkerInvalid(ISeriesItemRenderer(marker)))
				{
					marker.x = position.x - marker.width / 2;
					marker.y = position.y - marker.height / 2;
					this.validateMarker(ISeriesItemRenderer(marker));
				}
				
				//correct start value for marker size
				startValues.push(marker.x + marker.width / 2);
				startValues.push(marker.y + marker.height / 2);
				
				endValues.push(position.x);
				endValues.push(position.y);
			}
			
			//handle animating all the markers in one fell swoop.
			if(this._animation)
			{
				this._animation.removeEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.removeEventListener(AnimationEvent.COMPLETE, tweenUpdateHandler);
				this._animation = null;
			}
			
			//don't animate on livepreview!
			if(this.isLivePreview || !this.getStyleValue("animationEnabled"))
			{
				this.drawMarkers(endValues);
			}
			else
			{
				var animationDuration:int = this.getStyleValue("animationDuration") as int;
				var animationEasingFunction:Function = this.getStyleValue("animationEasingFunction") as Function;
				
				this._animation = new Animation(animationDuration, startValues, endValues);
				this._animation.addEventListener(AnimationEvent.UPDATE, tweenUpdateHandler);
				this._animation.addEventListener(AnimationEvent.COMPLETE, tweenUpdateHandler);
				this._animation.easingFunction = animationEasingFunction;
				this.drawMarkers(startValues);
			}
		}
		
		/**
		 * @private
		 */
		private function tweenUpdateHandler(event:AnimationEvent):void
		{
			this.drawMarkers(event.parameters as Array);
		}
		
		/**
		 * @private
		 */
		private function drawMarkers(data:Array):void
		{
			var primaryIsVertical:Boolean = true;
			var primaryAxis:NumericAxis = CartesianChart(this.chart).verticalAxis as NumericAxis;
			if(!primaryAxis)
			{
				primaryIsVertical = false;
				primaryAxis = CartesianChart(this.chart).horizontalAxis as NumericAxis;
			}
			
			var originPosition:Number = primaryAxis.valueToLocal(primaryAxis.origin);

			this.graphics.clear();

			this.prepareSkinjobs();
			
			//used to determine if the data must be drawn
			var seriesBounds:Rectangle = new Rectangle(0, 0, this.width, this.height);
			var itemCount:int = this.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var marker:DisplayObject = DisplayObject(this.markers[i]);
				var xPosition:Number = data[i * 2] as Number;
				var yPosition:Number = data[i * 2 + 1] as Number;
				var markerValid:Boolean = !this.isMarkerInvalid(ISeriesItemRenderer(marker));
				
				//if the position is valid, move or draw as needed
				if(markerValid)
				{
					marker.x = xPosition - marker.width / 2;
					marker.y = yPosition - marker.height / 2;
					
					// TODO: intercept with seriesBounds to know if it needs to be displayed.					
					var skin:FlagSkin = this.skinjobs[i] as FlagSkin;
					skin.height = 20;
					skin.width = 30;

					skin.x = xPosition - skin.width/2;
					skin.y = this.getHighestYForIndex(i) - skin.height - 10;
					skin.fillColor = this.getStyleValue("fillColor") as uint;
					skin.fillAlpha = this.getStyleValue("fillAlpha") as Number;
					skin.borderColor = this.getStyleValue("borderColor") as uint;
					skin.borderAlpha = this.getStyleValue("borderAlpha") as Number;
					skin.text = "a:" + yPosition;
				}
			}
		}
		
		public override function itemRendererToIndex(renderer:ISeriesItemRenderer):int
		{
			return this.skinjobs.indexOf(renderer);
		}
		/**
		  *@private
		  */
		 private function prepareSkinjobs() : void {
			 var itemsNeeded:int = this.length;
			 var skinJobCount = this.skinjobs.length;
			 
			 if(itemsNeeded > skinJobCount) {
				for(var i:int = 0; i<(itemsNeeded - skinJobCount); i++) {
					var skinjob:FlagSkin = new FlagSkin();
					
					InteractiveObject(skinjob).doubleClickEnabled = true;
					skinjob.addEventListener(MouseEvent.ROLL_OVER, markerRollOverHandler, false, 0, true);
					skinjob.addEventListener(MouseEvent.ROLL_OUT, markerRollOutHandler, false, 0, true);
					skinjob.addEventListener(MouseEvent.CLICK, markerClickHandler, false, 0, true);
					skinjob.addEventListener(MouseEvent.DOUBLE_CLICK, markerDoubleClickHandler, false, 0, true);
					
					skinjob.series = this;
					skinjob.data = 1;
					
					this.skinjobs.push(skinjob);
					this.addChild(DisplayObject(skinjob));
				}
			 } else if(skinJobCount > itemsNeeded) {
				for(var i:int = 0; i<(skinJobCount - itemsNeeded); i++) {
					var skinjob:FlagSkin = this.skinjobs.pop() as FlagSkin;
					
					// and remove event handlers
					
					this.removeChild(DisplayObject(skinjob));
				}
			 }
		 }
		
		/** 
		  *@private
		  */
		private function getHighestYForIndex(index:int) : int {
			var cchart:CartesianChart = CartesianChart(this.chart);
			
			var max = this.height;
			var seriesCount:int = cchart.dataProvider.length;
			for(var i:int = 0; i < seriesCount; i++)
				max = Math.min(max, cchart.itemToPosition(cchart.dataProvider[i], index).y);

			return max;
		}
	}
}
