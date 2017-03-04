local players_info = {} 

--Shortlist:
	

function players_info:GetTeamList(team_id) 
	return Spring.GetTeamList(team_id)
end

function players_info:GetPlayerList() 
	return Spring.GetPlayerList()
end

function players_info:GetAllyTeamList() 
	return GetAllyTeamList()
end

function players_info:GetPlayerInfo(player_id) 
	return Spring.GetPlayerInfo(player_id)
end

function players_info:GetPlayerControlledUnit(player_id) 
	return Spring.GetPlayerControlledUnit(player_id)
end

function players_info:GetAIInfo(team_id)
	Spring.GetAIInfo(team_id)
end

function players_info:GetAllyTeamInfo(team_id) 
	return Spring.GetAllyTeamInfo(team_id)
	
end

function players_info:GetTeamInfo(team_id) 
	return Spring.GetTeamInfo(team_id)
end

function players_info:GetTeamResources(team_id) 
	return Spring.GetTeamResources(team_id)
end

function players_info:GetTeamUnitStats(team_id)
	return Spring.GetTeamUnitStats(team_id)
end

function players_info:GetTeamResourceStats(team_id) 
	return Spring.GetTeamResourceStats(team_id)	
end

function players_info:GetTeamStatsHistory(team_id) 
	return Spring.GetTeamStatsHistory(team_id)
end

function players_info:GetTeamLuaAI(team_id) 
	return Spring.GetTeamLuaAI(team_id)
	
end

function players_info:AreTeamsAllied(team_id1, team_id2) 
	return Spring.AreTeamsAllied(team_id1, team_id2)
end

function players_info:ArePlayersAllied(player_id1, player_id2) 
	return Spring.ArePlayersAllied(player_id1, player_id2)
end

function players_info:GetAllyTeamStartBox(ally_id) 
	return Spring.GetAllyTeamStartBox(ally_id)
end

function players_info:GetTeamStartPosition(team_id)
	return GetTeamStartPosition(team_id)
end




