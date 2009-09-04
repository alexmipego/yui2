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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	/**
     * The weight, in pixels, of the line drawn between points in this series.
     *
     * @default 3
     */
    [Style(name="lineWeight", type="Number")]
	
	/**
     * If true, lines are drawn between the markers. If false, only the markers are drawn.
     *
     * @default true
     */
    [Style(name="connectPoints", type="Boolean")]
	
	/**
     * If true, draws a dashed line between discontinuous points.
     *
     * @default false
     */
    [Style(name="connectDiscontinuousPoints", type="Boolean")]
	
	/**
     * The length of dashes in a discontinuous line. 
     *
     * @default 10
     */
    [Style(name="discontinuousDashLength", type="Number")]
	
	/**
     * If true, the series will include a fill under the line, extending to the axis.
     *
     * @default false
     */
    [Style(name="showAreaFill", type="Boolean")]
	
	/**
     * The alpha value of the area fill.
     *
     * @default 0.6
     */
    [Style(name="areaFillAlpha", type="Number")]
    
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
			lineWeight: 3,
			connectPoints: true,
			connectDiscontinuousPoints: false,
			discontinuousDashLength: 10,
			showAreaFill: false,
			areaFillAlpha: 0.6,
			markerSize: 10,
			markerAlpha: 1.0
		};
		
		private static const RENDERER_STYLES:Object = 
		{
			fillColor: "lineColor"
		};
		
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
					var skin:FlagSkin = new FlagSkin();
					skin.height = 10;
					skin.width = 20;

					skin.x = xPosition - skin.width/2;
					skin.y = this.getHighestYForIndex(i) - skin.height - 10;
//					this.copyStylesToChild(skin, RENDERER_STYLES);  // Not working?
					this.addChild(skin);
				}
			}
		}
		
		/** 
		  *@Private
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
