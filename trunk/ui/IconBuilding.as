﻿package ui
{
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;		
	import flash.events.MouseEvent;
	
	import game.Building;
	
	public class IconBuilding extends MovieClip 
	{
		private static var REST:int = 0;
		private static var ACTIVATE:int = 1;		
				
		public var building:Building;
		public var anchorX:int;
		public var anchorY:int;		
		
		protected var image:Bitmap = null;
		
		private var iconState:int = REST;		
		
		public function IconBuilding()
		{
			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			addEventListener(MouseEvent.CLICK, mouseClick);		
		}
		
		public function showActivate() : void
		{
			iconState = ACTIVATE;
			this.gotoAndStop("Activate");
		}
		
		public function hideActivate() : void
		{
			iconState = REST;
			this.gotoAndStop("Rest");
		}
		
		private function mouseOut(e:MouseEvent) : void
		{
			if(iconState == REST)
				this.gotoAndStop("Rest");
			else
				this.gotoAndStop("Activate");
		}
		
		private function mouseOver(e:MouseEvent) : void
		{
			this.gotoAndStop("MouseOver");
		}
		
		private function mouseClick(e:MouseEvent): void
		{
			this.gotoAndStop("MouseClick");
		}		
		
		public function setBuilding(_building:Building) : void
		{
			this.building = _building;			
			
			var iconBitmapData:BitmapData = building.getImage();
			
			image = new Bitmap(iconBitmapData);
			image.width = 44;
			image.height = 44;
			image.smoothing = true;
			image.x = 1;
			image.y = 1;
			
			addChild(image);				
		}
	}
	
}