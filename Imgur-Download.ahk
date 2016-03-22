#SingleInstance,Force
global settings,txml,img,count,wb,cxml:=new CurrentXML(),v:=[]
v.count:=9
settings:=new XML("settings")
img:=new Imgur()
if(img.registered)
	return
Gui()
if(settings.ssn("//xbox").text)
	SetTimer,XBox,-500
if(!FileExist("settings.xml"))
	GuiControl,1:Choose,SysTabControl321,2
return
XBox:
new XBox()
return
class Imgur{
	__New(){
		this.startup()
		return this
	}
	StartUp(){
		for a,b in StrSplit("client_secret,client_id,refresh_token,access_token,expires_in,account_username",",")
			this[b]:=settings.ssn("//account/" b).text
		if(!(this.client_secret&&this.client_id))
			return this.register()
		if(!this.refresh_token)
			return this.authorize()
		if(this.expires_in<A_NowUTC)
			this.refresh()
		return
		update:
		for a,b in StrSplit("client_secret,client_id",","){
			ControlGetText,info,Edit%A_Index%,A
			settings.Add("account/" b,,info)
		}
		Imgur.Startup()
		return
	}
	Refresh(){
		refreshtoken:
		body:=imgur.info("refresh_token","client_id","client_secret") "&grant_type=refresh_token",this.store(iq:=imgur.http({verb:"POST",url:"https://api.imgur.com/oauth2/token",body:body}))
		return
	}http(info){
		static http
		Default("SysListView321"),LV_GetText(sub,LV_GetNext())
		if(!IsObject(http))
			http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
		http.Open(info.verb,info.url,1),http.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		if(info.oauth)
			http.SetRequestHeader("Authorization",": Bearer " this.access_token)
		http.Send(info.body),http.WaitForResponse
		ComObjError(0)
		if(http.status=500){
			m("Imgur is over Capacity"),v.overcap:=1,Show_Sub.SetTitle("Over-Capacity")
			Exit
		}if(http.status!=200){
			m("Something went wrong:",http.ResponseText),v.overcap:=1
			Exit
		}
		SB_SetText("Remaining API Calls: " http.getResponseHeader("X-RateLimit-ClientRemaining"),1)
		ComObjError(1)
		return http.ResponseText
	}UpdateAlbums(){
		updatealbums:
		url:="https://api.imgur.com/3/account/" imgur.account_username "/albums.xml",temp:=new xml("temp"),temp.xml.loadxml(imgur.http({verb:"get",url:url,oauth:1})),albums:=temp.sn("//item")
		while,album:=ssn(albums.item[A_Index-1],"id").text{
			info:=imgur.http({url:"https://api.imgur.com/3/album/" album ".xml",oauth:1,verb:"GET"}),temp:=new xml("temp"),temp.xml.loadxml(info)
			if(top:=settings.ssn("//album[@id='" album "']"))
				rem:=ssn(top,"images"),rem.ParentNode.RemoveChild(rem),top.appendchild(temp.ssn("//images"))
			Else{
				top:=settings.Add("album",{id:album},,1),all:=temp.sn("//data/*")
				while,a:=all.item[A_Index-1]
					top.appendchild(a)
		}}
		temp:=new xml("temp"),img:=new xml("img"),info:=imgur.http({url:"https://api.imgur.com/3/account/" imgur.account_username "/images/ids.xml",oauth:1,verb:"GET"}),temp.xml.loadxml(info),list:=temp.sn("//item")
		while,item:=list.item[A_Index-1].text{
			if(!settings.ssn("//*[id='" item "']")){
				img.xml.loadxml(imgur.http({url:"https://api.imgur.com/3/image/" item ".xml",oauth:1,verb:"GET"})),top:=settings.Add("image/image",{id:item},,1),info:=img.sn("//*/*")
				while,ii:=info.item[A_Index-1]
					top.appendchild(ii)
		}}imgur.albumlv()
		return
	}AlbumLV(){
		albums:=settings.sn("//album/title")
		TV_Delete()
		top:=TV_Add("Albums")
		TV_Add("Un-Sorted")
		while,aa:=albums.item[A_Index-1]
			TV_Add(aa.text,top)
		TV_Modify(TV_GetChild(TV_GetNext()),"Vis Select Focus")
	}Register(){
		static web
		Gui,2:Default
		Gui,Add,Text,,Client Information
		for a,b in StrSplit("client_secret,client_id",","){
			Gui,Add,Text,xm,%b%:
			Gui,Add,Edit,x+5 w200
		}
		Gui,Add,Button,xm gregnew,Register Your Client
		Gui,Add,Text,x+M,Choose OAuth 2 authorization without callback URL
		Gui,Add,Button,xm gupdate,Click Here once you have both ID and Secret
		Gui,Add,ActiveX,xm w1000 h600 vweb,InternetExplorer.Application:
		web.navigate("About:Blank")
		;web.navigate("http://www.google.com")
		Gui,Show
		this.registered:=1
		return
		regnew:
		web.navigate("https://api.imgur.com/oauth2/addclient")
		While(web.readyState!=4||web.document.readyState!= "complete"||web.busy){
			sleep 100
		}
		web.document.body.style.overflow:="auto"
		return
	}Store(Info){
		values:=[],info:=RegExReplace(info,"[\{\}" Chr(34) "]")
		for a,b in StrSplit(info,",")
			value:=StrSplit(b,":"),values[value.1]:=value.2
		for a,b in ["access_token","expires_in","refresh_token","account_username"]{
			if(b="expires_in"){
				add:=values[b],time:=A_NowUTC,time+=3600,ss,settings.Add("account/" b,,time),this[b]:=time
			}Else{
				if(values[b])
					this[b]:=values[b],settings.Add("account/" b,,values[b])
	}}}Authorize(){
		static
		Gui,Destroy
		web:=ComObjCreate("InternetExplorer.Application"),web.Visible:=1,web.navigate("https://api.imgur.com/oauth2/authorize?response_type=pin&client_id=" this.client_id),ComObjConnect(web,"Web_")
		While(web.readyState!=4||web.document.readyState!= "complete"||web.busy)
			sleep 100
		web.document.body.style.overflow:="auto"
		return
	}Info(X*){
		for a,b in x
			info.=b "=" settings.ssn("//account/" b).text "&"
		return Trim(info,"&")
}}
Web_DocumentComplete(a*){
	if(RegExMatch(a.2,"pin=(.*)",found)){
		body:=img.info("client_id","client_secret") "&grant_type=pin&pin=" found1,info:=img.http({verb:"POST",body:body,url:"https://api.imgur.com/oauth2/token"}),img.store(info),a.1.quit(),Gui()
		if(settings.ssn("//xbox").text)
			SetTimer,XBox,-500
		if(!FileExist("settings.xml"))
			GuiControl,1:Choose,SysTabControl321,2
}}
Class XML{
	keep:=[]
	__New(param*){
		if(!FileExist(A_ScriptDir "\lib"))
			FileCreateDir,%A_ScriptDir%\lib
		root:=param.1,file:=param.2,file:=file?file:root ".xml",temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath"),this.xml:=temp
		if(FileExist(file)){
			FileRead,info,%file%
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else
				temp.loadxml(info),this.xml:=temp
		}else
			this.xml:=this.CreateElement(temp,root)
		this.file:=file,xml.keep[root]:=this
	}CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}add(path,att:="",text:="",dup:=0,list:=""){
		p:="/",dup1:=this.ssn("//" path)?1:0,next:=this.ssn("//" path),last:=SubStr(path,InStr(path,"/",0,0)+1)
		if(!next.xml){
			next:=this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		}if(dup&&dup1)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in att
			next.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			next.SetAttribute(b,att[b])
		if(text!="")
			next.text:=text
		return next
	}find(info*){
		doc:=info.1.NodeName?info.1:this.xml
		if(info.1.NodeName)
			node:=info.2,find:=info.3
		else
			node:=info.1,find:=info.2
		if(InStr(find,"'"))
			node:=doc.SelectSingleNode(node "[.=concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "')]/..")
		else
			node:=doc.SelectSingleNode(node "[.='" find "']/..")
		return info.3.sn?sn(node,info.3.sn):node
	}under(under,node:="",att:="",text:="",list:=""){
		if(node="")
			node:=under.node,att:=under.att,list:=under.list,under:=under.under
		new:=under.appendchild(this.xml.createelement(node))
		for a,b in att
			new.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			new.SetAttribute(b,att[b])
		if(text)
			new.text:=text
		return new
	}ssn(path){
		return this.xml.SelectSingleNode(path)
	}sn(path){
		return this.xml.SelectNodes(path)
	}__Get(x=""){
		return this.xml.xml
	}transform(){
		static
		if(!IsObject(xsl)){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">`n<xsl:output method="xml" indent="yes" encoding="UTF-8"/>`n<xsl:template match="@*|node()">`n<xsl:copy>`n<xsl:apply-templates select="@*|node()"/>`n<xsl:for-each select="@*">`n<xsl:text></xsl:text>`n</xsl:for-each>`n</xsl:copy>`n</xsl:template>`n</xsl:stylesheet>
			xsl.loadXML(style),style:=null
		}this.xml.transformNodeToObject(xsl,this.xml)
	}save(x*){
		if(x.1=1)
			this.Transform()
		filename:=this.file?this.file:x.1.1
		if(this.xml.SelectSingleNode("*").xml="")
			return m("Errors happened. Reverting to old version of the XML")
		ff:=FileOpen(filename,0),text:=ff.Read(ff.length),ff.Close()
		if(!this[])
			return m("Error saving the " this.file " xml.  Please get in touch with maestrith if this happens often")
		if(text!=this[])
			file:=FileOpen(filename,"rw"),file.seek(0),file.write(this[]),file.length(file.position)
	}ea(path){
		list:=[]
		if(nodes:=path.nodename)
			nodes:=path.SelectNodes("@*")
		else if(!IsObject(path))
			nodes:=this.sn(path "/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.nodename]:=n.text
		return list
}}ssn(node,path){
	return node.SelectSingleNode(path)
}sn(node,path){
	return node.SelectNodes(path)
}
m(x*){
	static list:={btn:{oc:1,ari:2,ync:3,yn:4,rc:5,ctc:6},ico:{"x":16,"?":32,"!":48,"i":64}},msg:=[]
	list.title:="Image Sort",list.def:=0,list.time:=0,value:=0,v.msgbox:=1,txt:=""
	for a,b in x
		obj:=StrSplit(b,":"),(vv:=List[obj.1,obj.2])?(value+=vv):(list[obj.1]!="")?(List[obj.1]:=obj.2):txt.=b "`n"
	msg:={option:value+262144+(list.def?(list.def-1)*256:0),title:list.title,time:list.time,txt:txt}
	Sleep,120
	MsgBox,% msg.option,% msg.title,% msg.txt,% msg.time
	v.msgbox:=0
	for a,b in {OK:value?"OK":"",Yes:"YES",No:"NO",Cancel:"CANCEL",Retry:"RETRY"}
		IfMsgBox,%a%
			return b
}
t(x*){
	for a,b in x{
		if((obj:=StrSplit(b,":")).1="time"){
			SetTimer,killtip,% "-" obj.2*1000
			Continue
		}
		list.=b "`n"
	}
	Tooltip,% list
	return
	killtip:
	ToolTip
	return
}
Default(Control:="SysTreeView321",win:=1){
	type:=InStr(Control,"treeview")?"TreeView":InStr(Control,"ListView")?"ListView":""
	if(!type)
		return
	Gui,%win%:Default
	Gui,%win%:%type%,%Control%
}
Epoch(current="",convert:=0){
	current:=current?current:A_NowUTC,seventy:=19700101000000
	if(convert){
		seventy+=current,ss
		current:=seventy
	}else
		current-=seventy,ss
	FormatTime,date,%current%,MM-dd-yyyy HH:mm:ss
	return {date:date,datetime:current}
}
Gui(x:=0){
	static
	if(x){
		obj:=[],list:=v.xml.sn("//controls/*")
		Gui,1:Submit,Nohide
		while,ll:=list.item[A_Index-1]
			name:=ll.nodename,obj[ll.nodename]:=%name%
		return obj
	}
	Controller()
	Gui,+hwndmain +Resize
	v.MainID:="ahk_id" main,v.main:=main,v.controls:=[],v.xml:=new xml("general")
	tabs:="Main|Subs"
	v.maxtabs:=StrSplit(tabs,"|").MaxIndex()
	Gui,Margin,0,0
	Gui,Font,,Consolas
	Gui,Add,Tab,x0 y0 w0 h0,%tabs%
	Gui,Add,ActiveX,xm ym w900 h700 vwb,mshtml:
	Gui,Tab,2
	Gui,Add,ListView,xm ym w480 h500 AltSubmit Checked hwndSysListView321 vSysListView321,Auto Select/Name|Most Recent Image|Custom Image Count
	Gui,Add,MonthCal,x+M gSetDate hwndSysDateTimePick321 vSysDateTimePick321
	Gui,Add,Button,xm y500 gSetLast hwndButton2 vButton2,&Set Selected As Current Sub-Reddit
	Gui,Add,Button,x+M gAddSubReddit,&Add Sub Reddit
	Gui,Add,Checkbox,xm y523 gBrowse vbrowse,&Browse Mode
	Gui,Add,Checkbox,x+M gUseXBox vUseXBox,Use &XBox Controller
	Gui,Add,Text,xm y540,Browse mode will allow you to browse images beyond the Most Recent Image date
	Gui,Add,Button,xm y560 gCheck_For_Update,Check For &Update
	GuiControl,1:,browse,% Round(v.browse:=settings.ssn("//browse").text)
	GuiControl,1:,UseXBox,% Round(settings.ssn("//xbox").text)
	con:=v.xml.add("controls")
	for a,b in ["SysListView321","SysDateTimePick321","Button1","Button2"]
		v.xml.under(con,b,,%b%)
	PopulateSubReddits(),ea:=settings.ea("//gui"),pos:=ea.pos?ea.pos:"AutoSize"
	Gui,+MinSize800X600
	Gui,Add,text,x485 y170,Instructions:`n`n1. Add A Sub Reddit (Or Multiple Sub Reddits)`n2. Press Enter to start going through them`n3. Use your arrow keys to change the selection`n4. Press Space to select an image`n5. Press Enter again to Download the selected images`n   and go to the next X images`n`nHotkeys:`n`n        F1: Will jump to this screen`n        F2: Jumps to the next page (100 images)`nArrow Keys: Change Selection`n     Space: Toggles Selected state`n Ctrl+Left: Jumps Back a X images`n            (Can not jump from page to page)`n     Enter: Downloads Selected images and jumps `n            to the next X images`n    Delete: Removes a Sub Reddit`n  Alt+Left: Previous Screen`n Alt+Right: Next Screen`n    Ctrl+A: Toggle Selected state of all X images`n`nXBox 360 Controller:`n`n     D-Pad: Changes Selection`n         X: Toggles Selected State`n         A: Same as Enter above`n         Y: Same as Ctrl+A`n     Start: Next Screen`n      Back: Previous Screen
	Gui,Show,%pos%,Imgur Downloader 2.x
	if(ea.max)
		WinMaximize,% v.MainID
	Hotkey,IfWinActive,ahk_id%main%
	for a,b in ["Left","Right","Up","Down"]
		Hotkey,%b%,Move,On
	for a,b in {Next:"Enter",Select:"Space",Select_All:"^a",Previous_Screen:"!Left",Next_Screen:"!Right",Tab:"Tab",Delete:"Delete",Back:"^Left",Help:"F1",Next_Page:"F2"}
		Hotkey,%b%,%a%,On
	wb.write("<!DOCTYPE html><html><body leftmargin=0 topmargin=0 rightmargin=0 bottommargin=0></body><div></div></html>"),wb.body.style.backgroundcolor:=0
	return
	GuiSize:
	images:=wb.images,calc:=Calc(images,10)
	GuiControl,-Redraw,AtlAxWin1
	while(im:=images.item[A_Index-1])
		aw:=!Mod(A_Index,v.x)?calc.ww+calc.ax:calc.ww,ah:=A_Index>calc.yadd?calc.hh+calc.ay:calc.hh,im.ParentNode.style.width:=aw,im.ParentNode.style.height:=ah,im.style.maxwidth:=aw,im.style.maxheight:=ah,im.ParentNode.GetElementsByTagName("p").item[0].style.width:=aw-calc.sub
	GuiControl,move,AtlAxWin1,% "w" A_GuiWidth " h" A_GuiHeight
	if(GetTab()=1)
		GuiControl,+Redraw,AtlAxWin1
	SubReddit(1)
	return
	GuiEscape:
	cxml.SetTitle("Stopping, Please Wait..."),v.stop:=1
	return
	GuiClose:
	pos:=WinPos().text
	WinGet,minmax,MinMax,% v.MainID
	if(!gui:=settings.ssn("//gui"))
		gui:=settings.add("gui")
	if(minmax=0)
		gui.SetAttribute("pos",pos),gui.RemoveAttribute("max")
	else
		gui.SetAttribute("max",1)
	settings.save(1)
	ExitApp
	return
}
+Escape::
SetTimer,GuiClose,-1
return
Move(dir:=""){
	currenttab:=GetTab(),dir:=dir?dir:A_ThisHotkey
	if(currenttab=1){
		xx:=cxml.xml,first:=xx.sn("//item/link[text()='" wb.images.item[0].id "']/../preceding-sibling::*").length,current:=xx.sn("//*[@current]/../preceding-sibling::*").length,last:=xx.sn("//item/link[text()='" wb.images.item[wb.images.length-1].id "']/../preceding-sibling::*").length,count:=wb.images.length
		if(first=last)
			return t("hehe can't move when there is only 1 image","time:1")
		if(!v.showimage){
			if(dir="left")
				cxml.SetCurrent(current=first?last+1:current)
			else if(dir="right")
				cxml.SetCurrent(current=last?first+1:current+2)
			else if(dir="up"){
				if(current-v.x>=first)
					cxml.SetCurrent(current-v.x+1)
				else{
					sub:=v.x-Mod(current,count)-1
					if((flan:=v.x*v.y-sub)>count)
						cxml.SetCurrent(v.x*(v.y-1)+first-sub)
					else
						cxml.SetCurrent(flan+first)
				}
			}else if(dir="down")
				cxml.SetCurrent(current+v.x>last?first+Mod(current,v.x)+1:current+v.x+1)
		}else{
			/*
				nd:=dir~="i)Up|Left"?[current.PreviousSibling,current.ParentNode.LastChild]:[current.NextSibling,current.ParentNode.FirstChild],next:=nd.1?nd.1:nd.2,cxml.SetCurrent(next),cxml.Display(),cxml.Highlight(),ea:=xml.ea(cxml.current())
			*/
		}
	}if(currenttab>1){
		Send,{%dir%}
}}
Select(){
	tab:=GetTab()
	if(tab=1){
		node:=cxml.SSN("//*[@current]")
		if(!ssn(node.ParentNode,"width").text)
			return
		if(!ssn(node,"@selected"))
			node.SetAttribute("selected",1)
		else
			node.RemoveAttribute("selected")
		cxml.Highlight()
	}else
		Send,{Space}
}
Select_All(){
	all:=wb.images
	while(aa:=all.item[A_Index-1]){
		node:=cxml.SSN("//item/link[text()='" aa.id "']")
		if(!ssn(node.ParentNode,"width").text)
			Continue
		if(ssn(node,"@selected"))
			node.RemoveAttribute("selected")
		else
			node.SetAttribute("selected",1)
	}cxml.Highlight()
}
class XBox{
	static keystroke:={22528:"A",22529:"B",22549:"Back",22545:"Down",22546:"Left",22547:"Right",22544:"Up",22533:"LeftShoulder",22561:"LThumbY_Down",22563:"LThumbX_Left",22550:"LeftThumb",22562:"LThumbX_Right",22560:"LThumbY_Up",22534:"LTrigger",22532:"RightShoulder",22577:"RThumbY_Down",22579:"RThumbX_Left",22551:"RightThumb",22578:"RThumbX_Right",22576:"RThumbY_Up",22535:"RTrigger",22548:"Start",22530:"X",22531:"Y"}
	__New(count:=0){
		static
		this.library:=DllCall("LoadLibrary","str",(A_OSVersion~="8\.|10\.")?"Xinput1_4":"Xinput1_3"),this.ctrl:=[],main:=this,VarSetCapacity(State,16),main.ctrl:=[]
		if(!this.library){
			m("Error loading the DLL")
			return
		}
		for a,b in {xGetState:"XInputGetState",xBattery:"XInputGetBatteryInformation",xSetState:"XInputSetState",xkeystroke:"XInputGetKeystroke"}
			this[a]:=DllCall("GetProcAddress","ptr",this.library,"astr",b)
		xbox.main:=this,v.startxbox:=0,v.states:=[]
		goto,listen
		return
		GetState:
		ret:=DllCall(main.xkeystroke,UInt,0,UInt,0,UPtr,&State)
		if(ret=1167){
			goto,nocontroller
		}button:=NumGet(state,0),st:=NumGet(state,4),key:=xbox.keystroke[button]
		if(v.currenttab>1)
			if(v.states[key]=5&&key~="\b(Up|Down|Left|Right)\b")
				Send,{%key%}
		if(st=1&&button)
			Press(key)
		if(v.states[key]!=st)
			v.states[key]:=st
		return
		watch:
		ret:=DllCall(main.xGetState,int,0,"uint*",test)
		if(ret=1167)
			goto,nocontroller
		return
		nocontroller:
		v.nocontroller:=1
		Hotkey,IfWinActive,% mainwin.id
		Hotkey,^!p,Listen,On
		SetTimer,GetState,Off
		xbox.stopped:=1
		return
		Listen:
		v.nocontroller:=0
		SetTimer,GetState,100
		SetTimer,watch,1000
		return
	}
	Battery(Controller){
		VarSetCapacity(batt,8),info:=DllCall(xbox.main.xBattery,"uint",Controller,"uint",0,"uptr",&batt)
		Return NumGet(batt,1)
	}
}
Press(key){
	if(key~="\b(Up|Down|Left|Right)\b")
		return Move(key)
	info:=settings.ssn("//controller/@*[.='" key "']").nodename
	if(IsFunc(info)||IsLabel(info))
		SetTimer,%info%,-1
}
Controller(){
	static controller:={Next:"A",Download_Selected:"B",Shift_Tab:"LeftShoulder",Previous_Screen:"Back",Tab:"RightShoulder",Select_All:"Y",Next_Screen:"Start",Update_Search_Date:"Start",Select:"X",Stop:"Y",Page_Down:"RThumbY_Down",Page_Up:"RThumbY_Up"}
	if(!settings.ssn("//controller")){
		new:=settings.add("controller")
		for a,b in controller
			new.SetAttribute(a,b)
}}
Tab(x:=0){
	ControlGetFocus,Focus,% v.MainID
	if(InStr(Focus," "))
		return
	if(node:=v.xml.ssn("//" focus))
		next:=x=0?(node.NextSibling?node.NextSibling:node.ParentNode.FirstChild):(node.PreviousSibling?node.PreviousSibling:node.ParentNode.LastChild)
	next:=next?next:v.xml.ssn("//controls").FirstChild()
	ControlFocus,,% "ahk_id" next.text
}
Shift_Tab(){
	Tab(1)
}
Previous_Screen(){
	tab:=GetTab()
	GuiControl,1:Choose,SysTabControl321,% tab:=tab-1>0?tab-1:v.maxtabs
	if(tab=2)
		PopulateSubReddits()
	v.currenttab:=tab
}
Next_Screen(){
	tab:=GetTab()
	GuiControl,1:Choose,SysTabControl321,% tab:=tab+1<=v.maxtabs?tab+1:1
	if(tab=2)
		PopulateSubReddits()
	v.currenttab:=tab
}
GetTab(){
	ControlGet,tab,tab,,SysTabControl321,% v.MainID
	return Tab
}
WinPos(){
	VarSetCapacity(rect,16),DllCall("GetClientRect",ptr,v.main,ptr,&rect)
	WinGetPos,x,y,,,% v.MainID
	w:=NumGet(rect,8),h:=NumGet(rect,12),text:=(x!=""&&y!=""&&w!=""&&h!="")?"x" x " y" y " w" w " h" h:""
	return {x:x,y:y,w:w,h:h,text:text}
}
SubReddit(SetCal:=0){
	if(!LV_GetNext())
		return
	Default("SysListView321"),LV_GetText(sub,LV_GetNext()),node:=settings.ssn("//" sub),ea:=settings.ea(node)
	err:=ErrorLevel
	if(err~="C"&&A_GuiEvent="i"&&!ea.autoselect)
		node.SetAttribute("autoselect",1),cxml.autoselect:=1
	if(err~="c"&&A_GuiEvent="i"&&ea.autoselect)
		node.RemoveAttribute("autoselect"),cxml.autoselect:=0
	if(err~="S"||SetCal=1){
		GuiControl,1:,SysMonthCal321,% Epoch(ea.time,1).datetime
	}
}
PopulateSubReddits(){
	GuiControl,1:+g,SysListView321
	GuiControl,1:-Redraw,SysListView321
	all:=settings.sn("//date/*"),Default("SysListView321"),LV_Delete()
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa){
		LV_Add("",aa.NodeName,Epoch(ea.time,1).date,ea.customcount,ea.page)
	}
	all:=settings.sn("//date/*[@autoselect]")
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
		LV_Modify(sn(aa,"preceding-sibling::*").length+1,"Check")
	Loop,3
		LV_ModifyCol(A_Index,"AutoHDR")
	if(node:=settings.ssn("//date/*[@last='1']"))
		LV_Modify(sn(node,"preceding-sibling::*").length+1,"Select Vis Focus")
	GuiControl,1:+Redraw,SysListView321
	GuiControl,1:+gSubReddit,SysListView321
}
SetLast(alert:=1){
	info:=Gui(1),Default("SysListView321"),LV_GetText(sub,LV_GetNext()),node:=settings.ssn("//" sub),cxml.Reset()
	if(node){
		last:=settings.sn("//date/*[@last]")
		while,ll:=last.item[A_Index-1]
			ll.RemoveAttribute("last")
		node.SetAttribute("last",1)
		if(alert)
			m(node.nodename " Is now the current Sub-Reddit","time:1")
	}
}
Page_Up(){
	Send,{PgUp}
}
Page_Down(){
	Send,{PgDn}
}
SetDate(){
	cxml.GetSub()
	ControlGetText,time,SysMonthCal321,% v.MainID
	if(A_GuiEvent="Normal"){
		cxml.SetLast(cxml.node),cxml.node.SetAttribute("time",Epoch(Gui(1).SysDateTimePick321).datetime),cxml.Reset(),PopulateSubReddits()
	}
}
AddSubReddit(){
	InputBox,new,New Sub-Reddit,Enter ONLY the name, no /r
	if(ErrorLevel||new="")
		return
	if(RegExMatch(new,"\/|\\"))
		return m("Please read the instructions and try again")
	if(!settings.ssn("//" new))
		settings.under(settings.add("date"),new,{time:0,autoselect:0}),PopulateSubReddits()
}
Browse(){
	browse:=settings.ssn("//browse").text?0:1
	v.Browse:=browse,settings.add("browse",,browse)
}
Delete(){
	ControlGetFocus,Focus,% v.MainID
	if(Focus="SysListView321"){
		LV_GetText(sub,LV_GetNext())
		node:=settings.ssn("//date/" sub)
		if(m("Are you sure? Can not be undone","btn:ync")="Yes")
			node.ParentNode.RemoveChild(node),PopulateSubReddits()
}}
Class CurrentXML{
	__New(){
		this.xml:=new XML("cxml"),this.page:=0,this.count:=0,this.LatestDate:=0
	}
	Top(){
		rem:=cxml.ssn("//list"),rem.ParentNode.RemoveChild(rem),top:=cxml.add("list")
	}SetLast(Index:=1){
		list:=settings.sn("//date/*[@last]")
		while(ll:=list.item[A_Index-1])
			ll.RemoveAttribute("last")
		if(index.NodeName)
			index.SetAttribute("last",1)
		else
			this.GetSub(),this.node.SetAttribute("last",1)
	}
	NextSub(){
		next:=LV_GetNext()
		if(next+1<=LV_GetCount()){
			LV_Modify(0,"-Select"),LV_Modify(next+1,"Select Vis Focus"),SetLast(0),this.page:=0,this.count:=0,this.LatestDate:=0,this.xml.xml.LoadXML(""),this.GetSub(),this.SetTitle("Moving to the next sub " this.Sub " Slight Delay so you don't get banned")
			if((sleep:=A_Now-this.now)<2)
				Sleep,2000
			this.Reset(),this.Next()
		}else{
			m("All Done"),LV_Modify(1,"Select Vis Focus"),cxml.SetLast()
			Exit
		}
	}Reset(){
		this.xml.xml.LoadXML(""),this.count:=0,this.page:=0,this.GetNextSub:=0,this.LatestDate:=0,this.LastImage:=0,this.WrappedAround:=0
	}
	Next(){
		if(Tab()!=1)
			GuiControl,1:Choose,SysTabControl321,1
		if(v.stop)
			return this.Reset(),v.stop:=0,this.SetTitle(" ")
		if(this.GetNextSub)
			return this.NextSub()
		if(this.LastImage)
			this.LastImage:=0,this.page++,this.xml.xml.LoadXML(""),this.count:=0
		this.GetSub()
		if(!this.xml.ssn("//item")){
			this.now:=A_Now,this.SetTitle("Downloading File List For " this.sub "...Please Wait...Page" this.page+1),this.xml.xml.LoadXML(flan:=img.http({verb:"get",url:"https://api.imgur.com/3/gallery/r/" this.sub "/new/time/" this.page ".xml",oauth:1}))
			if(!this.xml.ssn("//item"))
				this.NextSub()
		}if(this.WrappedAround){
			return this.NextSub()
		}
		if(this.page=0&&this.LatestDate=0)
			this.LatestDate:=this.xml.ssn("//item/datetime").text,this.FirstItemID:=this.xml.ssn("//item/id").text,this.FirstTime:=1
		this.Display()
		if(v.LastNewImage)
			this.GetNextSub:=1,v.LastNewImage:=0,this.node.SetAttribute("time",this.LatestDate),this.LatestDate:=0,PopulateSubReddits(),SubReddit(1)
	}GetSub(){
		if(LV_GetNext())
			LV_GetText(sub,LV_GetNext()),this.sub:=sub,this.node:=settings.ssn("//date/" sub),this.LastTime:=settings.ssn("//date/" sub "/@time").text
		else
			return m("Select A Sub-Reddit First")
	}SetTitle(txt:=""){
		text:="Imgur Downloader: " this.sub " : Page " this.page+1,text.=(txt?": " txt:""),text.=this.size?" : " this.size:"",text.=" : Displaying " (count:=this.xml.sn("//item[" this.count+1 "]/preceding-sibling::*").length)+1 " Through " count+wb.images.length,text.=v.nocontroller?" : Press Ctrl+Alt+P to Enable Your XBox Controller":""
		WinSetTitle,% v.MainID,,%text%
	}Display(){
		GuiControl,1:-Redraw,AtlAxWin1
		all:=wb.images,dir:=A_ScriptDir "\images\" this.sub
		if(!FileExist(dir))
			FileCreateDir,% dir
		while(aa:=all.item[A_Index-1]),node:=this.xml.ssn("//item/link[text()='" aa.id "']"){
			if(ssn(node,"@selected")){
				url:=aa.id,this.SetTitle("Downloading " url)
				SplitPath,url,filename
				UrlDownloadToFile,%url%,% dir "\" filename
		}}
		this.count+=wb.images.length,list:=this.xml.sn("//item"),rem:=wb.GetElementsByTagName("div").item[0],rem.ParentNode.RemoveChild(rem),top:=wb.CreateElement("div")
		if(this.count=this.xml.sn("//item").length)
			return this.LastImage:=1,this.Next()
		calc:=Calc(list,10)
		while,ll:=list.item[(A_Index-1)+this.count]{
			if(this.FirstItemID=ssn(ll,"id").text&&this.FirstTime!=1){
				this.WrappedAround:=1
				if(!wb.images.length){
					if(v.Browse)
						return m("You have reached the end of this Sub Reddit")
					return this.NextSub()
				}
				Break
			}if(!v.Browse)
				if(ssn(ll,"datetime").text<=this.LastTime){
					if(!wb.images.length){
						GuiControl,1:+Redraw,AtlAxWin1
						return this.NextSub()
					}
					v.LastNewImage:=1,this.SetTitle("Now Showing The Last Image In This Set.")
					Break
				}
			div:=wb.CreateElement("div"),style:=div.style,span:=wb.CreateElement("span"),sp:=span.style,img1:=wb.CreateElement("img"),im:=img1.style,link:=ssn(ll,"link").text,img1.id:=link,img1.src:=link
			aw:=!Mod(A_Index,v.x)?calc.ww+calc.ax:calc.ww,ah:=A_Index>calc.yadd?calc.hh+calc.ay:calc.hh
			for a,b in {width:aw,height:ah,display:"table-cell",textalign:"center",verticalalign:"middle",display:"block",position:"Relative",float:"Left",border:Floor(calc.sub/2)"px solid black"}
				if(b)
					Style[a]:=b
			for a,b in {display:"inline-block",height:"100%",verticalalign:"middle"}
				sp[a]:=b
			for a,b in {maxwidth:aw,maxheight:ah,verticalalign:"middle"}
				im[a]:=b
			for a,b in {border:"3px solid black",position:"absolute",textposition:"center",width:aw-calc.sub "px",bottom:"0px",left:"0px",textalign:"center",backgroundcolor:"black",color:"Grey"}
				Text[a]:=b
			for a,b in [[div,span],[div,img1],[top,wb.body.AppendChild(div)],[wb.body,top]]
				(b.1).AppendChild(b.2)
			if(A_Index=v.count)
				break
		}wb.GetElementsByTagName("div").item[0].style.overflow:="auto",this.SetCurrent(),this.FirstTime:=0,this.SetTitle()
		if(LV_GetNext(LV_GetNext()-1,"C")=LV_GetNext())
			Select_All()
		GuiControl,1:+Redraw,AtlAxWin1
	}Highlight(){
		all:=wb.images
		while,aa:=all.item[A_Index-1]
			ea:=this.xml.ea("//item/link[text()='" aa.id "']"),aa.ParentNode.style.bordercolor:=(ea.current&&ea.selected?"#00ff00":ea.current&&!ea.selected?"#ffff00":!ea.current&&!ea.selected?"#aaaaaa":"#ff00ff")
	}SSN(path){
		return this.xml.ssn(path)
	}SetCurrent(x:=""){
		list:=this.xml.sn("//item/link[@current]")
		while(rem:=list.item[A_Index-1])
			rem.RemoveAttribute("current")
		if(x)
			node:=this.xml.ssn("//item[" x "]/link"),node.SetAttribute("current",1)
		else
			node:=this.xml.ssn("//item/link[text()='" wb.images.item[0].id "']"),node.SetAttribute("current",1)
		this.size:="Width=" ssn(node.ParentNode,"width").text " Height=" ssn(node.ParentNode,"height").text,this.SetTitle()
		this.Highlight()
	}
}
Calc(list,sub){
	pos:=WinPos()
	if(list.item[0].nodename){
		length:=((count:=((cxml.count+v.count)-list.length))>0)?Abs(count-v.count):v.count
		if(!v.Browse){
			current:=cxml.xml.ssn("//item[" cxml.count+1 "]"),last:=cxml.xml.ssn("//item/datetime[text()<='" cxml.Lasttime "']/ancestor-or-self::item"),length:=Round(sn(last,"preceding-sibling::*").length-sn(current,"preceding-sibling::*").length),length:=length<v.count?length:v.count
		}
	}else
		length:=list.length
	length:=length=0?v.count:length,status=0,v.x:=Ceil(Sqrt(length)),v.y:=Round(Sqrt(length)),mww:=pos.w,mwh:=pos.h,ww:=Floor((mww/v.x)-sub),hh:=Floor(((mwh-status)/v.y)-sub)
	return info:={ww:ww,hh:hh,sub:sub,ax:(mww-(ww*v.x+(sub*v.x))),ay:(mwh-(hh*v.y+(sub*v.y)+Status)),yadd:(v.x*(v.y-1))}
}
Back(){
	cxml.count:=cxml.count-v.count>=0?(cxml.count-v.count):0,cxml.LastImage:=0,rem:=wb.GetElementsByTagName("div").item[0],rem.ParentNode.RemoveChild(rem),top:=wb.CreateElement("div")
	if(cxml.count=0)
		cxml.FirstTime:=1
	cxml.LastNewImage:=0,cxml.Display()
}
Help(){
	GuiControl,1:Choose,SysTabControl321,2
}
UseXbox(){
	node:=settings.add("xbox")
	if(node.text)
		node.text:=0,m("This will take effect on the next run","time:2")
	else{
		node.text:=1
		SetTimer,XBox,-1
	}
}
Next_Page(){
	cxml.page++,cxml.xml.xml.LoadXML(""),cxml.count:=0,cxml.GetNextSub:=0,rem:=wb.GetElementsByTagName("div").item[0],rem.ParentNode.RemoveChild(rem),top:=wb.CreateElement("div"),cxml.Next()
}
Next(){
	cxml.Next()
}

URLDownloadToVar(url){
	http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	if(proxy:=settings.ssn("//proxy").text)
		http.setProxy(2,proxy)
	http.Open("GET",url,1),http.Send(),http.WaitForResponse ;the 1 is async
	return http.ResponseText
}
Check_For_Update(startup:=""){
	static newwin,version,DownloadURL:="https://raw.githubusercontent.com/maestrith/Imgur-Download/master/Imgur-Download.ahk",VersionTextURL:="https://raw.githubusercontent.com/maestrith/Imgur-Download/master/Imgur-Download.text"
	Run,RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
	auto:=settings.ea("//autoupdate"),sub:=A_NowUTC
	if(startup=1){
		if(v.options.Check_For_Update_On_Startup!=1)
			return
		if(auto.reset>A_Now)
			return
	}
	sub-=A_Now,hh
	FileGetTime,time,%A_ScriptFullPath%
	time+=sub,hh
	;ea:=settings.ea("//github")
	;token:=ea.token?"?access_token=" ea.token:""
	url:="https://api.github.com/repos/maestrith/Imgur-Download/commits/master" token
	http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.Open("GET",url)
	if(proxy:=settings.ssn("//proxy").text)
		http.setProxy(2,proxy)
	http.send(),RegExMatch(flan:=http.ResponseText,"iUO)\x22date\x22:\x22(.*)\x22",found),date:=RegExReplace(found.1,"\D")
	if(startup="1"){
		if(reset:=http.getresponseheader("X-RateLimit-Reset")){
			seventy:=19700101000000
			for a,b in {s:reset,h:-sub}
				EnvAdd,seventy,%b%,%a%
			settings.add("autoupdate",{reset:seventy})
			if(time>date)
				return
		}else
			return
	}
	Version:="0.000.2"
	;newwin:=new GUIKeep("CFU"),newwin.add("Edit,w400 h400 ReadOnly,No New Updates,wh","Button,gautoupdate,Update,y","Button,x+5 gcurrentinfo,Current Changelog,y","Button,x+5 gextrainfo,Changelog History,y"),newwin.show("AHK Studio Version: " version)
	Gui,2:Destroy
	Gui,2:+hwndhwnd
	Gui,2:Add,Edit,w500 h400,This may be blank...if so just try the update.
	Gui,2:Add,Button,gUpdateProgram,Update
	Gui,2:Show,,Imgur Download
	if(time<date){
		file:=FileOpen("changelog.txt","rw"),file.seek(0),file.write(update:=RegExReplace(UrlDownloadToVar(VersionTextURL),"\R","`r`n")),file.length(file.position),file.Close()
		ControlSetText,Edit1,%update%,ahk_id%hwnd%
	}if(!found.1)
		ControlSetText,Edit1,% http.ResponseText,ahk_id%hwnd%
	else
		ControlSetText,Edit1,% found.1 "`r`n`r`n" http.ResponseText,ahk_id%hwnd%
	return
	UpdateProgram:
	SplitPath,A_ScriptFullPath,,dir,,nne
	if(dir="D:\AHK\Duplicate Programs\Imgur Download")
		return m("just....no.....")
	FileMove,%A_ScriptFullPath%,%dir%\%nne%%A_Now%.ahk
	UrlDownloadToFile,%DownloadURL%,%A_ScriptFullPath%
	Run,%A_ScriptFullPath%
	ExitApp
	return
}