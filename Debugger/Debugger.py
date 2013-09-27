#!/usr/bin/python
import sys
import time
sys.path.append("/home/mrhase/xml-message-passing/") #We add the path to the libs here..
import xmplib

import xml.dom.minidom #xml
from struct import * #unpack, pack

import wx
from wx import *
#from wxPython.xrc import * #deprecated
import os



class MyApp(wx.App):
	def OnInit(self):
		self.interpreter_is_listening=False
		print "Init"
		self.res = xrc.XmlResource("dbg.xrc")
		self.frame = self.res.LoadFrame(None, "main_frame")
		self.console=xrc.XRCCTRL(self.frame,"Console")
		self.console.AppendText("Init\n")
		
		self.varlist=xrc.XRCCTRL(self.frame,"list_ctrl_1")
		self.varlist.InsertColumn(0,"Name")
		self.varlist.InsertColumn(1,"Value")
		self.varlist.InsertColumn(2,"Info")
		#EVT_LISTBOX_DCLICK(self,xrc.XRCID("list_ctrl_1"),self.VariableDClick)
		#EVT_LIST_COL_CLICK
		EVT_LIST_ITEM_ACTIVATED(self,xrc.XRCID("list_ctrl_1"),self.VariableDClick)
		#self.raw_textarea=xrc.XRCCTRL(self.frame,"rawdata_textarea")
		#self.chat_text=xrc.XRCCTRL(self.frame,"chat_text")
		#self.chat_playerlist=xrc.XRCCTRL(self.frame,"chat_playerlist")
		#self.playerlist=PlayerList(self.chat_playerlist)
		#self.chat_playerlist_search=xrc.XRCCTRL(self.frame,"chat_playerlist_search")
		
		#self.playerlist.Add("Test1")
		#self.playerlist.Add("Test2")
		#self.playerlist.Add("Test3")
		#self.playerlist.Add("Test4")
		
		
		
		EVT_BUTTON(self, xrc.XRCID("button_run"), self.button_run)
		EVT_BUTTON(self, xrc.XRCID("button_step_over"), self.button_step_over)
		EVT_BUTTON(self, xrc.XRCID("button_step_into"), self.button_step_into)
		#EVT_BUTTON(self, XRCID("chat_close_tab_button"), self.ChatCloseTab)
		#EVT_LISTBOX_DCLICK(self,XRCID("chat_playerlist"),self.ChatPlayerlist)
		#EVT_TEXT(self,XRCID("chat_playerlist_search"),self.ChatPlayerlistSearch)
	
		#self.chat_panel_dic={}
		#self.chat_notebook=xrc.XRCCTRL(self.frame,"chat_notebook")
		#self.chat_notebook.DeleteAllPages()
		#self.AddChatPanel("Lobby")
		#</tabs>
		
		print "Show frame"
		self.frame.Show()
		
		#return True
		#<connect to xmp>
		
		self.console.AppendText("Connecting to xmpd...\n")
		try:
			print "Try to connect to xmp..."
			self.xmp=xmplib.XmpConnector('localhost',30000)
		except (Exception):
			wx.MessageBox('Could not connect to the xmp server', 'Error')
			sys.exit(1)
		print "connected..."
		self.xmp.Register('XO++','Debugger')		
		#</connect ot xmp>
		print "OnInit fertig"
		#timer
		TIMER_ID = wx.NewId()#100  # pick a number
		self.timer = wx.Timer(self.frame, TIMER_ID)  # message will be sent to the panel
		wx.EVT_TIMER(self.frame, TIMER_ID, self.on_timer)  # call the on_timer function
		self.timer.Start(200)  # x1000 milliseconds=0.2sec
		###
		return True
	def get_interpreter_attention(self):
		ret=self.interpreter_is_listening
		self.interpreter_is_listening=False
		return ret
	
	def SendSimpleCommand(self,cmd):
		import xml.dom
		implement = xml.dom.getDOMImplementation()
		doc = implement.createDocument(None, "debugging", None)
		dbg=doc.createElement("debugging")
		msg=doc.createElement("response")
		text = doc.createTextNode(cmd)
		msg.appendChild(text)
		dbg.appendChild(msg)
		print dbg.toxml("utf-8")
		self.xmp.SendXML("Interpreter",dbg)	
	def button_run(self,event):
		if self.get_interpreter_attention()==True:
			self.SendSimpleCommand("run")
		
	def button_step_over(self,event):
		if self.get_interpreter_attention()==True:
			self.SendSimpleCommand("step")
	def button_step_into(self,event):
		if self.get_interpreter_attention()==True:
			self.SendSimpleCommand("step")
	def VariableDClick(self,event):
		print event.m_itemIndex
		varname=self.varlist.GetItemText(event.m_itemIndex)
		if self.get_interpreter_attention()==True:
			import xml.dom
			implement = xml.dom.getDOMImplementation()
			doc = implement.createDocument(None, "debugging", None)
			dbg=doc.createElement("debugging")
			msg=doc.createElement("response")
			text = doc.createTextNode("info")
			about=doc.createElement("about")
			about_txt=doc.createTextNode(varname)
			about.appendChild(about_txt)
			msg.appendChild(about)
			msg.appendChild(text)
			dbg.appendChild(msg)
			print dbg.toxml("utf-8")
			self.xmp.SendXML("Interpreter",dbg)	
		
	def handle_input(self,data):
		print "handle data:"
		print data.toxml("utf-8")
		print "tagname: "+ data.tagName
		
		if data.getAttribute("attention")=="true":
			self.interpreter_is_listening=True
				
		for info in data.getElementsByTagName("info"):
			self.console.AppendText(data.getElementsByTagName("info")[0].firstChild.data)
			self.console.AppendText("\n")
			
		for raw_string in data.getElementsByTagName("raw_string"):
				self.console.AppendText(raw_string.firstChild.data)
				self.console.AppendText("\n")
				self.SendSimpleCommand("variables")
				self.interpreter_is_listening=True
	
		if data.getElementsByTagName("var").length>0:
			self.varlist.DeleteAllItems()
		for var in data.getElementsByTagName("var"):
			name=var.getAttribute("name")
			self.varlist.InsertStringItem(0, name)
			value=var.firstChild.data
			self.varlist.SetStringItem(0, 1, value)
			info=var.getAttribute("info")
			self.varlist.SetStringItem(0, 2, info)
		
	def on_timer(self,event): #hier fehlt noch das try, except
		#print "timer"
		try:
			while self.xmp.Count()!='0':
				self.xmp.Receive()
				recv_xml=self.xmp.GetXML()
				if recv_xml!=None:
					self.handle_input(recv_xml)
		except (Exception):
			print Exception
def main():
	app = MyApp(0)
	app.MainLoop()
if __name__ == '__main__':
	main()
