﻿package game
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;	
	import flash.events.KeyboardEvent;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.events.EventPhase;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import net.packet.BattleTarget;
	import net.packet.Perception;
	
	import Main;
	
	import game.battle.Battle;
	import game.battle.BattleManager;
	import game.entity.City;
	import game.entity.Army;
	import game.entity.Entity;
	import game.perception.PerceptionManager
	import game.map.Map;
	import game.map.MapObjectType;
	import game.map.MapBattle;
	import game.map.Tile;
	
	import net.Connection;
	import net.packet.BattleInfo;
	import net.packet.BattleAddArmy;
	import net.packet.BattleDamage;	
	
	import ui.panel.controller.ArmyPanelController;
	import ui.panel.controller.BottomPanelController;
	import ui.panel.controller.CityPanelController;
	import ui.panel.controller.CommandPanelController;
	import ui.panel.controller.CreateUnitPanelController;
	import ui.panel.controller.QueueBuildingPanelController;
	import ui.panel.controller.BattlePanelController;
	
	public class Game extends Sprite
	{				
		public static var INSTANCE:Game = new Game();	
		public static var SCROLL_SPEED:int = 8;
		public static var GAME_LOOP_TIME:int = 50;	
				
		public var main:Main;
		public var player:Player;
		
		public var selectedEntity:Entity;
		public var targetedEntity:Entity;
		public var action:int = 0;
		
		private var lastLoopTime:Number;
		private var perceptionManager:PerceptionManager;
		private var map:Map;
		
		public function Game() : void
		{
			selectedEntity = null;							
			targetedEntity = null;
			player = new Player();
			
			map = Map.INSTANCE;
			perceptionManager = PerceptionManager.INSTANCE;
						
			addChild(map);	
						
			Connection.INSTANCE.addEventListener(Connection.onMapEvent, connectionMap);
			Connection.INSTANCE.addEventListener(Connection.onPerceptionEvent, connectionPerception);		
			Connection.INSTANCE.addEventListener(Connection.onInfoArmyEvent, connectionInfoArmy);
			Connection.INSTANCE.addEventListener(Connection.onInfoCityEvent, connectionInfoCity);
			Connection.INSTANCE.addEventListener(Connection.onBattleInfoEvent, connectionBattleInfo);
			Connection.INSTANCE.addEventListener(Connection.onBattleDamageEvent, connectionBattleDamage);
			
			addEventListener(Tile.onClick, tileClicked);
			addEventListener(Army.onClick, armyClicked);
			addEventListener(Army.onDoubleClick, armyDoubleClicked);
			addEventListener(City.onClick, cityClicked);
			addEventListener(City.onDoubleClick, cityDoubleClicked);
			addEventListener(MapBattle.onDoubleClick, battleDoubleClicked);
		}
				
		public function addPerceptionData(perception:Perception) : void
		{	
			//Clear player's entities
			player.clearEntities();
			
			//Set entities from perception
			perceptionManager.setMapObjects(perception.mapObjects);
			
			//Set map tiles from perception
			map.setTiles(perception.mapTiles);
		}
		
		public function setLastLoopTime(time:Number) : void
		{
			lastLoopTime = time;
		}		
		
		public function startLoop() : void
		{
			addEventListener(Event.ENTER_FRAME, this.gameLoop);
		}
		
		public function gameLoop(e:Event) : void
		{
			var time:Number = getTimer();
						
			if((time - lastLoopTime) >= Game.GAME_LOOP_TIME)
			{
				
			}
		}
		
		public function keyDownEvent(e:KeyboardEvent) : void
		{
			var rect:Rectangle = Game.INSTANCE.scrollRect;
		
			if (e.keyCode == 87) //w
			{
				rect.y -= Game.SCROLL_SPEED;	
			}
			else if (e.keyCode == 68) //d
			{
				rect.x += Game.SCROLL_SPEED;
			}
			else if (e.keyCode == 83) //s
			{ 
				rect.y += Game.SCROLL_SPEED;						 
			}
			else if (e.keyCode == 65) //a
			{
				rect.x -= Game.SCROLL_SPEED;					 
			}			
			
			Game.INSTANCE.scrollRect = rect;
		}	
		
		public function stageClick(e:MouseEvent) : void
		{			
			if (e.eventPhase == EventPhase.AT_TARGET)
			{
				var mapX:int = e.stageX - 100;
				var mapY:int = e.stageY;
				
				var rect:Rectangle = Game.INSTANCE.scrollRect;
				var offsetX:int = rect.x;
				var offsetY:int = rect.y;
				
				var gameX:int = (mapX + offsetX) / Tile.WIDTH;
				var gameY:int = (mapY + offsetY) / Tile.HEIGHT
				
				trace("Stage Click - mapX: " + mapX + " mapY: " + mapY);
				trace("Stage Click - gameX: " + gameX + " gameY: " + gameY + " action: " + action);
				
				sendMove(gameX, gameY);
			}
		}
		
		public function sendAttack(targetId:int)
		{
			if (selectedEntity != null)
			{
				trace("Game - sendAttack");
				var parameters:Object = {id: selectedEntity.id, targetId: targetId};
				var attackEvent:ParamEvent = new ParamEvent(Connection.onSendAttackTarget);
				attackEvent.params = parameters;				
				Connection.INSTANCE.dispatchEvent(attackEvent);		
			}
		}
		
		public function sendTarget(battleId:int, sourceArmyId:int, sourceUnitId:int, targetArmyId:int, targetUnitId:int) : void
		{
			var battleTarget:BattleTarget = new BattleTarget();
			
			battleTarget.battleId = battleId;
			battleTarget.sourceArmyId = sourceArmyId;
			battleTarget.sourceUnitId = sourceUnitId;
			battleTarget.targetArmyId = targetArmyId;
			battleTarget.targetUnitId = targetUnitId;
			
			var battleTargetEvent:ParamEvent = new ParamEvent(Connection.onSendBattleTarget);
			battleTargetEvent.params = battleTarget;
			
			Connection.INSTANCE.dispatchEvent(battleTargetEvent);
		}		
				
		private function tileClicked(e:ParamEvent) : void
		{
			trace("Game - tileClicked");
			
			var tile:Tile = e.params;
			
			if (tile != null)
			{
				BottomPanelController.INSTANCE.tile = tile;
				BottomPanelController.INSTANCE.setIcons();
				CommandPanelController.INSTANCE.hidePanel();
				
				sendMove(tile.gameX, tile.gameY);
			}
		}
		
		private function sendMove(gameX:int, gameY:int) : void
		{
			if(selectedEntity != null)
			{
				if (CommandPanelController.INSTANCE.isMoveCommand())
				{					
					CommandPanelController.INSTANCE.resetCommand();
					
					var parameters:Object = {id: selectedEntity.id, x: gameX, y: gameY};
					var pEvent = new ParamEvent(Connection.onSendMoveArmy);
					pEvent.params = parameters;
					Connection.INSTANCE.dispatchEvent(pEvent);	
				}
			}
		}
		
		private function armyClicked(e:ParamEvent) : void
		{
		}
		
		private function armyDoubleClicked(e:ParamEvent) : void
		{
			var parameters:Object = { type: MapObjectType.ARMY, targetId: e.params.id };
			var requestInfoEvent:ParamEvent = new ParamEvent(Connection.onSendRequestInfo);
			requestInfoEvent.params = parameters;
			Connection.INSTANCE.dispatchEvent(requestInfoEvent);
		}
		
		private function cityDoubleClicked(e:ParamEvent) : void
		{
			var parameters:Object = { type: MapObjectType.CITY, targetId: e.params.id };
			var requestInfoEvent:ParamEvent = new ParamEvent(Connection.onSendRequestInfo);
			requestInfoEvent.params = parameters;
			Connection.INSTANCE.dispatchEvent(requestInfoEvent);
		}
		
		private function battleDoubleClicked(e:ParamEvent) : void
		{
			var parameters:Object = { type: MapObjectType.BATTLE, targetId: e.params.battleId };
			var requestInfoEvent:ParamEvent = new ParamEvent(Connection.onSendRequestInfo);
			requestInfoEvent.params = parameters;
			
			Connection.INSTANCE.dispatchEvent(requestInfoEvent);
		}
						
		private function cityClicked(e:ParamEvent) : void
		{
			trace("Game - cityClicked");
		}	
		
		private function connectionMap(e:ParamEvent) : void
		{
			trace("Game - connectionMap");
			map.setTiles(e.params);
		}
		
		private function connectionPerception(e:ParamEvent) : void
		{
			trace("Game - perception");
			addPerceptionData(e.params);
		}
		
		private function connectionInfoArmy(e:ParamEvent) : void
		{
			trace("Game - infoArmy");
			var army:Army = Army(perceptionManager.getEntity(e.params.id));
			army.setArmyInfo(e.params);
			
			ArmyPanelController.INSTANCE.army = army;
			ArmyPanelController.INSTANCE.setUnits();
			ArmyPanelController.INSTANCE.showPanel();
		}
		
		private function connectionInfoCity(e:ParamEvent) : void
		{
			trace("Game - infoCity");	
			var city:City = City(perceptionManager.getEntity(e.params.id));
			city.setCityInfo(e.params);
			
			CityPanelController.INSTANCE.city = city;
			CityPanelController.INSTANCE.setBuildings();
			CityPanelController.INSTANCE.setUnits();
			CityPanelController.INSTANCE.showPanel();
		}		
		
		private function connectionBattleInfo(e:ParamEvent) : void
		{
			trace("Game - battleInfo");
			var battleInfo:BattleInfo = BattleInfo(e.params);			
			var battle:Battle = new Battle();		
			
			battle.id = battleInfo.battleId;
			battle.createArmies(battleInfo.armies);
			
			BattleManager.INSTANCE.addBattle(battle);
			
			BattlePanelController.INSTANCE.battle = battle;
			BattlePanelController.INSTANCE.setArmies();
			BattlePanelController.INSTANCE.showPanel();
		}
		
		private function connnectionBattleAddArmy(e:ParamEvent) : void
		{
			trace("Game - battleAddArmy");
			var battleAddArmy:BattleAddArmy = BattleAddArmy(e.params);
			var battle:Battle = BattleManager.INSTANCE.getBattle(battleAddArmy.battleId);
			
		}
		
		private function connectionBattleDamage(e:ParamEvent) : void
		{
			trace("Game - battleDamage");
			var battleDamage:BattleDamage = e.params as BattleDamage;
			var battle:Battle = BattleManager.INSTANCE.getBattle(battleDamage.battleId);
			
			battle.addDamage(battleDamage);			
		}		
	}
}