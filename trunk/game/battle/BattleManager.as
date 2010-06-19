﻿package game.battle
{
	public class BattleManager
	{
		public static var INSTANCE:BattleManager = new BattleManager();	
		
		public var battles/*Battle*/:Array = new Array();
		
		public function BattleManager()
		{
		}
		
		public function addBattle(battle:Battle) : void
		{
			battles.push(battle);
		}
		
		public function getBattle(battleId:int) : Battle
		{
			for (var i:int = 0; i < battles.length; i++)
			{
				if (battles[i].id == battleId)
					return battles[i];
			}
			
			return null;
		}
		
		public function removeBattle(battle:Battle) : void
		{
		}
	}
}