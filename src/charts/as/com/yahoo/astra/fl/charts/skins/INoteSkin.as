package com.yahoo.astra.fl.charts.skins
{
	/**
	 * A type of skin that supports text and interaction customization.
	 * 
	 * @author Josh Tynjala
	 */
	public interface INoteSkin
	{
	//--------------------------------------
	//  Properties
	//--------------------------------------
	
		/**
		 * The text.
		 */
		function get text():String;
		
		/**
		 * Sets the text.
		 */
		function set text(value:String):void;
		
	}
}