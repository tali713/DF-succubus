--create unit at pointer or given location. Usage e.g. "spawnunit DWARF 0 Dwarfy"
 
--Made by warmist, but edited by Putnam for the dragon ball mod to be used in reactions
 
--note that it's extensible to any autosyndrome reaction to spawn anything due to this; to use in autosyndrome, you want \COMMAND spawnunit CREATURE caste_number name \LOCATION
 
args={...}
function getCaste(race_id,caste_id)
    local cr=df.creature_raw.find(race_id)
    return cr.caste[caste_id]
end
function genBodyModifier(body_app_mod)
    local a=math.random(0,#body_app_mod.ranges-2)
    return math.random(body_app_mod.ranges[a],body_app_mod.ranges[a+1])
end
function getBodySize(caste,time)
    --todo real body size...
    return caste.body_size_1[#caste.body_size_1-1] --returns last body size
end
function genAttribute(array)
    local a=math.random(0,#array-2)
    return math.random(array[a],array[a+1])
end
function norm()
    return math.sqrt((-2)*math.log(math.random()))*math.cos(2*math.pi*math.random())
end
function normalDistributed(mean,sigma)
    return mean+sigma*norm()
end
function clampedNormal(min,median,max)
    local val=normalDistributed(median,math.sqrt(max-min))
    if val<min then return min end
    if val>max then return max end
    return val
end
function makeSoul(unit,caste)
    local tmp_soul=df.unit_soul:new()
    tmp_soul.unit_id=unit.id
    tmp_soul.name:assign(unit.name)
    tmp_soul.race=unit.race
    tmp_soul.sex=unit.sex
    tmp_soul.caste=unit.caste
    --todo skills,preferences,traits.
    local attrs=caste.attributes
    for k,v in pairs(attrs.ment_att_range) do
       local max_percent=attrs.ment_att_cap_perc[k]/100
       local cvalue=genAttribute(v)
       tmp_soul.mental_attrs[k]={value=cvalue,max_value=cvalue*max_percent}
    end
    for k,v in pairs(tmp_soul.traits) do
        local min,mean,max
        min=caste.personality.a[k]
        mean=caste.personality.b[k]
        max=caste.personality.c[k]
        tmp_soul.traits[k]=clampedNormal(min,mean,max)
    end
    unit.status.souls:insert("#",tmp_soul)
    unit.status.current_soul=tmp_soul
end
function CreateUnit(race_id,caste_id)
    local race=df.creature_raw.find(race_id)
    if race==nil then error("Invalid race_id") end
    local caste=getCaste(race_id,caste_id)
    local unit=df.unit:new()
    unit.race=race_id
    unit.caste=caste_id
    unit.id=df.global.unit_next_id
    df.global.unit_next_id=df.global.unit_next_id+1
	unit.relations.old_year=df.global.cur_year-5 -- everybody will be 15 years old
    if caste.misc.maxage_max==-1 then
        unit.relations.old_year=-1
    else
        unit.relations.old_year=df.global.cur_year+math.random(caste.misc.maxage_min,caste.misc.maxage_max)
    end
    unit.sex=caste.gender
		local num_inter=#caste.body_info.interactions  -- new for interactions
	unit.curse.anon_4:resize(num_inter) -- new for interactions
	unit.curse.anon_5:resize(num_inter) -- new for interactions
    local body=unit.body
    
    body.body_plan=caste.body_info
    local body_part_count=#body.body_plan.body_parts
    local layer_count=#body.body_plan.layer_part
    --components
    unit.relations.birth_year=df.global.cur_year-15
    --unit.relations.birth_time=??
    
    --unit.relations.old_time=?? --TODO add normal age
    local cp=body.components
    cp.body_part_status:resize(body_part_count)
    cp.numbered_masks:resize(#body.body_plan.numbered_masks)
    for num,v in ipairs(body.body_plan.numbered_masks) do
        cp.numbered_masks[num]=v
    end
    
    cp.layer_status:resize(layer_count)
    cp.layer_wound_area:resize(layer_count)
    cp.layer_cut_fraction:resize(layer_count)
    cp.layer_dent_fraction:resize(layer_count)
    cp.layer_effect_fraction:resize(layer_count)
    local attrs=caste.attributes
    for k,v in pairs(attrs.phys_att_range) do
        local max_percent=attrs.phys_att_cap_perc[k]/100
        local cvalue=genAttribute(v)
        unit.body.physical_attrs[k]={value=cvalue,max_value=cvalue*max_percent}
        --unit.body.physical_attrs:insert(k,{new=true,max_value=genMaxAttribute(v),value=genAttribute(v)})
    end
 
    body.blood_max=getBodySize(caste,0) --TODO normal values
    body.blood_count=body.blood_max
    body.infection_level=0
    unit.status2.body_part_temperature:resize(body_part_count)
    for k,v in pairs(unit.status2.body_part_temperature) do
        unit.status2.body_part_temperature[k]={new=true,whole=10067,fraction=0}
        
    end
    --------------------
    local stuff=unit.enemy
    stuff.body_part_878:resize(body_part_count) -- all = 3
    stuff.body_part_888:resize(body_part_count) -- all = 3
    stuff.body_part_relsize:resize(body_part_count) -- all =0
 
    --TODO add correct sizes. (calculate from age)
    local size=caste.body_size_2[#caste.body_size_2-1]
    body.size_info.size_cur=size
    body.size_info.size_base=size
    body.size_info.area_cur=math.pow(size,0.666)
    body.size_info.area_base=math.pow(size,0.666)
    body.size_info.area_cur=math.pow(size*10000,0.333)
    body.size_info.area_base=math.pow(size*10000,0.333)
    
    stuff.were_race=race_id
    stuff.were_caste=caste_id
    stuff.normal_race=race_id
    stuff.normal_caste=caste_id
    stuff.body_part_8a8:resize(body_part_count) -- all = 1
    stuff.body_part_base_ins:resize(body_part_count) 
    stuff.body_part_clothing_ins:resize(body_part_count) 
    stuff.body_part_8d8:resize(body_part_count) 
    unit.recuperation.healing_rate:resize(layer_count) 
    --appearance
   
    local app=unit.appearance
    app.body_modifiers:resize(#caste.body_appearance_modifiers) --3
    for k,v in pairs(app.body_modifiers) do
        app.body_modifiers[k]=genBodyModifier(caste.body_appearance_modifiers[k])
    end
    app.bp_modifiers:resize(#caste.bp_appearance.modifier_idx) --0
    for k,v in pairs(app.bp_modifiers) do
        app.bp_modifiers[k]=genBodyModifier(caste.bp_appearance.modifiers[caste.bp_appearance.modifier_idx[k]])
    end
    --app.unk_4c8:resize(33)--33
    app.tissue_style:resize(#caste.bp_appearance.style_part_idx)
    app.tissue_style_civ_id:resize(#caste.bp_appearance.style_part_idx)
    app.tissue_style_id:resize(#caste.bp_appearance.style_part_idx)
    app.tissue_style_type:resize(#caste.bp_appearance.style_part_idx)
    app.tissue_length:resize(#caste.bp_appearance.style_part_idx)
    app.genes.appearance:resize(#caste.body_appearance_modifiers+#caste.bp_appearance.modifiers) --3
    app.genes.colors:resize(#caste.color_modifiers*2) --???
    app.colors:resize(#caste.color_modifiers)--3
    
    makeSoul(unit,caste)
    
    df.global.world.units.all:insert("#",unit)
    df.global.world.units.active:insert("#",unit)
    --todo set weapon bodypart
    
    local num_inter=#caste.body_info.interactions
    unit.curse.anon_5:resize(num_inter)
    return unit
end
function findRace(name)
    for k,v in pairs(df.global.world.raws.creatures.all) do
        if v.creature_id==name then
            return k
        end
    end
    qerror("Race:"..name.." not found!")
end

function createFigure(trgunit,he)
    local hf=df.historical_figure:new()
    hf.id=df.global.hist_figure_next_id
    hf.race=trgunit.race
    hf.caste=trgunit.caste
	hf.profession = trgunit.profession
	hf.sex = trgunit.sex
    df.global.hist_figure_next_id=df.global.hist_figure_next_id+1
	hf.appeared_year = df.global.cur_year
	
	hf.born_year = trgunit.relations.birth_year
	hf.born_seconds = trgunit.relations.birth_time
	hf.curse_year = trgunit.relations.curse_year
	hf.curse_seconds = trgunit.relations.curse_time
	hf.birth_year_bias = trgunit.relations.birth_year_bias
	hf.birth_time_bias = trgunit.relations.birth_time_bias
	hf.old_year = trgunit.relations.old_year
	hf.old_seconds = trgunit.relations.old_time
	hf.died_year = -1
	hf.died_seconds = -1
	hf.name:assign(trgunit.name)
	hf.civ_id = trgunit.civ_id
	hf.population_id = trgunit.population_id
	hf.breed_id = -1
	hf.unit_id = trgunit.id
	
    df.global.world.history.figures:insert("#",hf)

	hf.info = df.historical_figure_info:new()
	hf.info.unk_14 = df.historical_figure_info.T_unk_14:new() -- hf state?
	--unk_14.region_id = -1; unk_14.beast_id = -1; unk_14.unk_14 = 0
	hf.info.unk_14.unk_18 = -1; hf.info.unk_14.unk_1c = -1
	-- set values that seem related to state and do event
	--change_state(hf, dfg.ui.site_id, region_pos)


--lets skip skills for now
--local skills = df.historical_figure_info.T_skills:new() -- skills snap shot
-- ...
--info.skills = skills


	he.histfig_ids:insert('#', hf.id)
	he.hist_figures:insert('#', hf)

	trgunit.flags1.important_historical_figure = true
	trgunit.flags2.important_historical_figure = true
	trgunit.hist_figure_id = hf.id
	trgunit.hist_figure_id2 = hf.id
    
    hf.entity_links:insert("#",{new=df.histfig_entity_link_memberst,entity_id=trgunit.civ_id,link_strength=100})
    --add entity event
    local hf_event_id=df.global.hist_event_next_id
    df.global.hist_event_next_id=df.global.hist_event_next_id+1
    df.global.world.history.events:insert("#",{new=df.history_event_add_hf_entity_linkst,year=trgunit.relations.birth_year,
        seconds=trgunit.relations.birth_time,id=hf_event_id,civ=hf.civ_id,histfig=hf.id,link_type=0})
    return hf
end
function createNemesis(trgunit,civ_id)
    local id=df.global.nemesis_next_id
    local nem=df.nemesis_record:new()
	local he=df.historical_entity.find(civ_id)
    nem.id=id
    nem.unit_id=trgunit.id
    nem.unit=trgunit
    nem.flags:resize(1)
    --not sure about these flags...
    nem.flags[4]=true
    nem.flags[5]=true
    nem.flags[6]=true
    nem.flags[7]=true
    nem.flags[8]=true
    nem.flags[9]=true
    --[[for k=4,8 do
        nem.flags[k]=true
    end]]
    df.global.world.nemesis.all:insert("#",nem)
    df.global.nemesis_next_id=id+1
    trgunit.general_refs:insert("#",{new=df.general_ref_is_nemesisst,nemesis_id=id})
    trgunit.flags1.important_historical_figure=true
    
    nem.save_file_id=he.save_file_id
	
    he.nemesis_ids:insert("#",id)
	he.nemesis:insert("#",nem)
    nem.member_idx=he.next_member_idx
    he.next_member_idx=he.next_member_idx+1
    --[[ local gen=df.global.world.worldgen
    gen.next_unit_chunk_id
    gen.next_unit_chunk_offset
    ]]
    nem.figure=createFigure(trgunit,he)
end

function PlaceUnit(race,caste,name,position,civ_id)


	
    local pos=position or copyall(df.global.cursor)
    if pos.x==-30000 then
        qerror("Point your pointy thing somewhere")
    end
    race=findRace(race)

	
    local u=CreateUnit(race,tonumber(caste) or 0)
    u.pos:assign(pos)
		
    if name then
        u.name.first_name=name
        u.name.has_name=true
    end
    u.civ_id=civ_id or df.global.ui.civ_id

    
    local desig,ocupan=dfhack.maps.getTileFlags(pos)
    if ocupan.unit then
        ocupan.unit_grounded=true
        u.flags1.on_ground=true
    else
        ocupan.unit=true
    end
    
    if df.historical_entity.find(u.civ_id) ~= nil  then
        createNemesis(u,u.civ_id)
    end
end

local argPos
 
if #args>3 then
    argPos={}
    argPos.x=args[4]
    argPos.y=args[5]
    argPos.z=args[6]
end
 
PlaceUnit(args[1],args[2],args[3],argPos) --Creature (ID), caste (number), name, x,y,z , civ_id(-1 for enemy, optional) for spawn.
